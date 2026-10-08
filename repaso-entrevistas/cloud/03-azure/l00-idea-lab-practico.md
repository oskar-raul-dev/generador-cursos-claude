# L00 — Introducción a la serie práctica: qué se hace en la nube y qué no

> **Objetivo:** entender qué vas a construir en los labs [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md)–[`L09`](l09-costos-y-destruccion-verificada.md), por qué el laboratorio
> incluye exactamente esos servicios y no otros, por qué son nueve sesiones, cuánto va a costar y
> cómo se garantiza que no quede nada encendido.
> **Se asume leído:** nada. Este es el primer documento de la serie práctica.
> **Precios de referencia:** `eastus2`, consultados el 27 de septiembre de 2026 en la
> [Azure Retail Prices API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices),
> en dólares y precio de lista. Verifica siempre en la
> [calculadora oficial](https://azure.microsoft.com/en-us/pricing/calculator/) antes de encender algo.
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [Las dos restricciones](#1--las-dos-restricciones-de-partida) ·
[Doctrina de reparto](#2--la-doctrina-de-reparto-qué-se-paga-y-qué-se-practica-en-local) ·
[Por qué no un microservicio en AKS](#3--el-caso-testigo-por-qué-no-montamos-un-microservicio-en-aks) ·
[Qué entra y qué no](#4--el-catálogo-completo-de-exclusiones) ·
[El sistema del lab](#5--el-sistema-que-vas-a-construir) ·
[Presupuesto](#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas) ·
[Cómo recorrer la serie](#7--cómo-recorrer-la-serie) ·
[Emuladores](#8--emuladores-locales-qué-sirve-y-qué-miente) ·
[Ampliaciones](#9--ampliaciones-opcionales) ·
[Decisiones](#11--decisiones-las-cerradas-y-las-que-siguen-abiertas) ·
[Preguntas](#-preguntas-rápidas)

Este documento no es material de estudio para la entrevista: es el contrato de la serie
práctica. Define qué entra en el laboratorio de pago, **qué queda fuera y por qué**, el
presupuesto y cómo se conecta con el resto del repositorio. Si solo vas a leer un documento
antes de abrir una suscripción de Azure, que sea este.

---

## 1. 🧭 Las dos restricciones de partida

Todo el diseño de la serie sale de dos hechos. El primero es una buena noticia con letra
pequeña; el segundo no es negociable.

**Hay tres cosas gratis, y no son la misma.** La cuenta gratuita de Azure trae, según la
[página oficial de la oferta](https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account):

| Mecanismo | Qué da | Cuándo se acaba |
|---|---|---|
| Crédito de bienvenida | $200 para casi cualquier servicio | A los 30 días o al gastarlo, lo que ocurra primero |
| Servicios gratis por 12 meses | Cuotas mensuales de más de 20 servicios, solo para clientes nuevos | A los 12 meses |
| Servicios siempre gratis | Cuotas mensuales de más de 65 servicios, para cualquier cliente | Mientras Microsoft no las cambie |

A esas tres se suman **ofertas gratuitas propias de cada servicio**, que no dependen del tipo
de cuenta y son las que de verdad sostienen el laboratorio: el
[free grant de Container Apps](https://azure.microsoft.com/en-us/pricing/details/container-apps/)
—180.000 vCPU-segundos, 360.000 GiB-segundos y 2 millones de requests por suscripción y mes—, el
[free tier de Cosmos DB](https://learn.microsoft.com/en-us/azure/cosmos-db/free-tier) —1000 RU/s y
25 GB para toda la vida de la cuenta, una cuenta por suscripción, y solo si lo pides al crearla— y
los primeros 5 GB mensuales de ingesta de Log Analytics.

> 📝 **Contexto.** Mucho material de estudio te dice "Azure es gratis el primer mes". Lo cierto es
> más útil: **casi toda esta serie cabe dentro de las ofertas propias de cada servicio**, que no
> caducan. El crédito de $200 es la red de seguridad, no el presupuesto. Diseñar el lab pensando en
> el crédito es diseñarlo para que muera a los 30 días.

**La cuenta gratuita trae un spending limit, y es de verdad.** A diferencia de un budget, el
[spending limit](https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/spending-limit)
sí detiene el gasto: cuando el crédito se agota, los servicios se deshabilitan hasta el final del
período, las VMs se detienen y desasignan, y las storage accounts quedan en solo lectura. Es igual
al crédito, no se puede cambiar de monto y **desaparece cuando pasas la suscripción a
pay-as-you-go**, que es lo que tendrás que hacer a los 30 días si quieres seguir usando las ofertas
gratuitas. A partir de ahí, lo único que te protege es tu disciplina de teardown y las alertas de
[`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md).

**El lab acompaña una búsqueda de empleo.** No hay presupuesto de empresa ni tiempo ilimitado. El
laboratorio tiene que poder encenderse en minutos, practicarse en una sesión y destruirse con
certeza. Un lab que tarda tres horas en levantarse se hace una vez y nunca más, y un lab que no
sabes destruir del todo es una suscripción mensual que no pediste.

De ahí sale la tesis de la serie:

```text
El laboratorio no se mide por lo que despliegas.
Se mide por lo que destruyes y vuelves a levantar sin intervención manual.
```

---

## 2. ⚖ La doctrina de reparto: qué se paga y qué se practica en local

> 🧠 **Modelo mental.** En la nube se practica lo que **solo** existe en la nube. Todo lo demás se
> practica en local con contenedores: gratis, con un ciclo de iteración de segundos en vez de
> minutos, y sin miedo a olvidarse algo encendido.

Un tema entra en el laboratorio de pago solo si cumple **al menos una** de estas cuatro
condiciones:

| Criterio | Ejemplos en Azure |
|---|---|
| Lo hace cumplir Azure y nadie más | Entra ID y Azure RBAC, jerarquía de scopes, registro de resource providers, Azure Policy, cuotas |
| El fallo real difiere del emulado | Soft-delete y purge protection, resource locks, propagación de role assignments, DLQ y `MaxDeliveryCount` de Service Bus, throttling por Request Units |
| Solo se conoce pagando | Cost Management, budgets, spending limit, qué consume de verdad cada oferta gratuita |
| Es la costura entre tu código y Azure | Managed identities, `DefaultAzureCredential`, tokens y audiencias, app roles, workload identity federation |

La contrapartida de esa regla es lo que hace útil al laboratorio:

> Regla de arquitectura: los emuladores son andamio de desarrollo, no instrumento de enseñanza. Lo
> que un emulador te quita —un RBAC que sí deniega, un provider que hay que registrar, un token que
> sí se valida, una factura— es exactamente lo que Azure enseña.

Y al revés: lo que Azure **no** te enseña mejor que un contenedor local no merece que le pagues.
Correr PostgreSQL en Flexible Server no te enseña PostgreSQL. Correr un contenedor en Container
Apps no te enseña qué es un contenedor. Desplegar un microservicio en AKS no te enseña
Kubernetes. En los tres casos pagas por hora para practicar algo que ya podías practicar gratis, y
con un ciclo de iteración diez veces más lento.

---

## 3. ⚖ El caso testigo: por qué no montamos un microservicio en AKS

Es la pregunta que más aparece al ver el índice: *"¿un lab de Azure sin Kubernetes?"*. Sí, y vale
la pena desarmarla entera, porque el razonamiento sirve para cualquier otro servicio dudoso.

### 3.1 Primero, hay que ser honestos con el precio

El argumento fácil —"el control plane de Kubernetes es caro"— no sirve en Azure. AKS tiene un tier
Free sin cargo por el control plane; el tier Standard, el que trae SLA financiado, cuesta
**$0.10/h** por cluster. Lo que sí factura desde el primer minuto es todo lo demás:

- **los nodos son VMs**, y facturan por hora aunque no corra ni un Pod tuyo;
- un `Service` de tipo `LoadBalancer` crea un Azure Load Balancer Standard y una **IP pública
  Standard a $0.005/h**;
- los discos de los nodos y los volúmenes persistentes son managed disks que facturan por mes,
  prorrateado.

No es ruinoso: una tarde de AKS con un nodo pequeño cuesta centavos. El problema no es el precio.

### 3.2 Qué esperas aprender y qué aprendes de verdad

Haz la lista de lo que esperas aprender montando un microservicio en AKS y marca qué es de Azure:

| Aprendizaje esperado | ¿Específico de Azure? |
|---|---|
| Deployments, Services, ConfigMaps, probes | ❌ Kubernetes puro, igual en `kind` |
| Escalado horizontal de Pods | ❌ Kubernetes puro |
| Rolling updates y rollback | ❌ Kubernetes puro |
| Helm, manifiestos, GitOps | ❌ Ecosistema de Kubernetes |
| Observabilidad de Pods | ❌ Prometheus y Grafana corren en local |
| Workload identity: un Pod con identidad de Entra ID | ✅ Solo existe en Azure |
| Un `Service` que crea un Load Balancer y una IP pública | ✅ La integración con la red de Azure |
| Azure CNI y el agotamiento de IPs de la subnet | ✅ Solo existe en Azure |

Cinco de ocho aprendizajes son Kubernetes, y los practicas gratis en local. Los tres que quedan
son la costura con Azure, y caben en una sesión de dos horas que se enciende y se destruye: es el
drill de §9, no un lab del tronco.

### 3.3 La pregunta que decide

```text
¿Qué parte de este servicio solo la enseña Azure?
  ├── casi nada          → contenedor local
  ├── una costura        → drill opcional de §9, encender y destruir en una sesión
  └── el servicio entero → lab del tronco
```

Container Apps pasa la prueba como lab del tronco por la razón inversa a AKS: **no tiene nada que
aprender en local**. Revisiones, reparto de tráfico, escala a cero con KEDA, identidad, secretos
referenciados desde Key Vault y el contrato de ingress son todos de Azure, y su free grant hace que
practicarlos no cueste nada.

---

## 4. 📋 El catálogo completo de exclusiones

Lo que sí entra al laboratorio de pago, con lo que enseña cada cosa:

| Servicio | Qué enseña que no se aprende en local |
|---|---|
| `az`, suscripción y resource groups | Providers, perfil aislado, tags, budgets, Cost Management |
| Entra ID y Azure RBAC | Role assignments por scope, plano de datos, propagación, `AuthorizationFailed` real |
| Bicep sobre ARM | `what-if`, modo complete, locks, Deployment Stacks con deny settings |
| VNet, NSG y private endpoint | Resolución DNS privada, effective routes y security rules, Network Watcher |
| Container Apps y Container Registry | Contrato de la plataforma, revisiones, escala a cero, `AcrPull` con managed identity |
| App registrations | Scopes frente a app roles, tokens v2, una managed identity como cliente de tu API |
| Cosmos DB (free tier) | Partition key real, RU consumidas, `429`, escritura idempotente |
| Service Bus Standard | Topics, subscriptions, peek-lock, DLQ incluida, duplicate detection |
| Log Analytics y Application Insights | KQL, diagnostic settings, Activity Log, alertas |

Y lo que queda fuera, cada uno con su razón y su destino.

**AKS.** Desarrollado en §3. → `kind` en local, más el drill de §9.

**Virtual Machines y VM Scale Sets como carga de trabajo.** Una B1ls cuesta $0.0052/h y entra en los
12 meses gratis de la cuenta nueva, así que el problema no es el precio: el ciclo de vida de una VM
no enseña nube. La excepción es [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md), que enciende una VM durante una hora **como
instrumento de diagnóstico** —Network Watcher necesita una NIC para IP flow verify y next hop—, no
como carga. → VM o contenedor local.

**App Service.** Comparte con Container Apps casi todo lo que enseña (planes, slots frente a
revisiones, identidad), y su tier gratuito no admite deployment slots, que es lo que importa
practicar. El vocabulario se
cubre en [`04`](04-computo-y-contenedores.md). → Fuera del tronco.

**Azure SQL Database y PostgreSQL Flexible Server.** El motor se aprende mejor en un contenedor. El
sobre administrado —failover groups, PITR, autenticación con Entra ID— es de Azure, y aquí hay una
buena noticia: la
[oferta gratuita de Azure SQL](https://learn.microsoft.com/en-us/azure/azure-sql/database/free-offer)
da hasta 10 bases General Purpose serverless por suscripción, con 100.000 vCore-segundos y 32 GB al
mes cada una, de por vida. Por eso Azure SQL es un drill gratuito de §9 y no una exclusión. Flexible
Server no tiene equivalente: el tier Burstable más pequeño (B1ms) cuesta **$0.017/h** más el
almacenamiento, que sigue cobrando con el servidor detenido. → PostgreSQL en contenedor.

**Application Gateway y Front Door.** Application Gateway Standard v2 tiene un costo fijo de
**$0.20/h** antes de procesar un solo request; Front Door Standard, un cargo base de **$35 al mes**.
Container Apps ya publica un FQDN HTTPS con certificado administrado sin cobrar por él. Es la trampa
de costo número uno de los proyectos de práctica. → Conceptos en [`05`](05-balanceo-entrega-global-y-api-management.md); drill de §9 para quien
quiera verlo.

**Azure Firewall, NAT Gateway y Bastion.** Azure Firewall Basic cuesta **$0.395/h**; NAT Gateway,
**$0.045/h** más el tráfico procesado; Bastion Basic, **$0.19/h**. El lab no los necesita: la VM de
diagnóstico de [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) no tiene IP pública y se opera con `az vm run-command`, que
le entrega el script al agente de la VM a través de la plataforma de Azure, sin SSH, sin puerto de
entrada y sin Bastion. Eso sí, Run Command necesita **salida por el puerto 443 hacia IPs públicas de
Azure** para devolver el resultado, y la subnet del lab es privada: [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) enciende un NAT Gateway
durante una hora para resolverlo, y lo destruye en la misma sesión. → Conceptos en
[`02`](02-redes-vnet-nsg-y-enrutamiento.md).

**API Management.** El tier Consumption da 1 millón de llamadas al mes sin cargo, pero el aprendizaje
—políticas, `validate-jwt`, productos— no es parte del flujo del sistema del lab y alargaría
[`L06`](l06-identidad-de-aplicaciones-api-protegida.md) sin añadir un diagnóstico nuevo. → Conceptos en [`05`](05-balanceo-entrega-global-y-api-management.md) y [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md); drill de §9.

**Event Grid y Event Hubs.** Event Grid da 100.000 operaciones al mes sin cargo y cabe en un drill
de §9; Event Hubs Standard cuesta **$0.03/h** por throughput unit y enseña streaming, que corre igual
con Kafka en local. → Conceptos en [`13`](13-mensajeria-y-eventos.md); Event Grid en §9, Kafka en contenedor.

**Azure Managed Redis.** El tier más pequeño (Balanced B0) cuesta **$0.016/h** para enseñarte un
Redis que ya sabes usar. → Redis en contenedor.

**Analítica (Fabric, Synapse, Databricks).** Fuera del alcance del curso entero, no solo del lab.

**Jenkins, SonarQube, Prometheus, Grafana.** No son productos de Azure. → Contenedores en local.

---

## 5. 🧱 El sistema que vas a construir

Inventario de una cadena de tiendas. Solo backend, sin frontend y sin una sola credencial guardada
en la aplicación.

```text
  curl  (access token de Entra ID con el app role Inventory.Write)
    │
    ▼
  inv-api (Container Apps, ingress externo, valida el JWT)      identidad: inv-api-id
    │
    ├──►  Cosmos DB  contenedor events   (escritura idempotente)
    │
    └──►  Service Bus topic  inv-events
                 │   subscription inv-projector (peek-lock, MaxDeliveryCount)
                 ▼
           inv-projector (Container Apps, escala 0 → N por mensajes)   identidad: inv-projector-id
                 │
                 ├──►  Cosmos DB  contenedor stock
                 │
                 └──►  tras N entregas fallidas: DLQ de la subscription
                                  │
                                  ▼
                        alerta de métrica  ──►  correo
```

Cada pieza está ahí por un motivo concreto:

- **Dos user-assigned managed identities, una por servicio**, son la costura entre tu código y
  Azure. Cada una recibe solo los roles de datos que necesita —`inv-api-id` escribe en `events` y
  envía al topic; `inv-projector-id` recibe de la subscription y escribe en `stock`— y ninguna tiene
  un rol de control plane. Es la diferencia entre un lab que enseña privilegio mínimo y uno que
  corre entero como Contributor.
- **La validación del JWT en `inv-api`** es donde se practica [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md): un cliente humano con un scope
  delegado y un cliente máquina con un app role, y el `401` y el `403` que distinguen "no sé quién
  eres" de "sé quién eres y no puedes".
- **La escritura en Cosmos DB** es donde practicas partition key, consumo de RU e idempotencia, la
  respuesta a la pregunta de entrevista más frecuente sobre procesamiento asíncrono.
- **La DLQ de Service Bus** viene incluida en cada subscription; no hay que crear otro topic. Lo que
  hay que hacer es provocar un mensaje envenenado a propósito, verlo agotar `MaxDeliveryCount` y
  encontrarlo en `$deadletterqueue` con su motivo.
- **La vigilancia de la DLQ no es un tercer servicio.** Una alerta sobre la métrica de mensajes en
  dead-letter hace lo mismo sin desplegar nada, y las primeras diez reglas de alerta de métrica no
  cobran. Si el servicio administrado ya lo hace, no escribas un servicio.

El sistema no se levanta de una sentada: [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) despliega `inv-api` sin
autenticación ni datos, [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) le pone la validación de tokens, y
[`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) añade Cosmos DB, el topic, `inv-projector` y la DLQ. Esa frontera es
deliberada y está explicada en §7.1.

---

## 6. 💰 Presupuesto, y de dónde sale el gasto que no esperabas

| Bloque | Costo |
|---|---|
| [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md)–[`L03`](l03-bicep-desde-la-cli.md) — suscripción, RBAC, Bicep | $0.00; storage account y Key Vault cuestan fracciones de centavo por operación |
| [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) — red | ~$0.07 por sesión de una hora: private endpoint a $0.01/h, VM B1ls a $0.0052/h y su disco, NAT Gateway a $0.045/h con su IP pública a $0.005/h, y una Private DNS zone a $0.50/mes como máximo |
| [`L05`](l05-container-apps-revisiones-trafico-y-escala.md)–[`L06`](l06-identidad-de-aplicaciones-api-protegida.md) — Container Apps e identidad de aplicaciones | ~$0.17 por día que exista el registry (Container Registry Basic a $0.1666/día); Container Apps dentro del free grant |
| [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) — datos y eventos | ~$0.05 por sesión: Service Bus Standard a $0.0134/h; Cosmos DB dentro del free tier |
| [`L08`](l08-observabilidad-kql-y-auditoria.md)–[`L09`](l09-costos-y-destruccion-verificada.md) — observabilidad, costos y teardown | ~$0.00; por debajo de 5 GB de ingesta y de diez alertas de métrica |
| **Serie completa** | **menos de $1**, o $0.00 de bolsillo mientras dure el crédito de bienvenida |

El único cargo que aparece de verdad en el tronco es **Container Registry**, porque su unidad de
facturación es el día y no la hora: no esperes pagar solo los minutos que existió. Por eso
[`L05`](l05-container-apps-revisiones-trafico-y-escala.md) lo crea una vez y [`L09`](l09-costos-y-destruccion-verificada.md) lo destruye; entre medias no se
recrea.

Ahora la parte importante, porque el gasto real de un proyecto de práctica **casi nunca viene del
lab en sí**. Viene de cuatro sitios:

1. **Cargos base que corren sin tráfico.** Front Door, Application Gateway, Azure Firewall, NAT
   Gateway y Bastion cobran por existir. Uno olvidado después de un drill es un mes de factura.
2. **IPs públicas y discos huérfanos.** Borrar una VM no borra necesariamente su disco ni su IP
   pública Standard, y un snapshot no lo borra nadie nunca. El catálogo completo va en [`A02`](a02-costos-trampas-y-recursos-huerfanos.md).
3. **Lo que Azure crea por ti sin decírtelo.** `az containerapp env create` sin
   `--logs-workspace-id` **crea un Log Analytics workspace nuevo** con nombre aleatorio; crear una
   VNet habilita Network Watcher en un resource group aparte, `NetworkWatcherRG`.
4. **Drills opcionales que se quedan encendidos.** Los de §9.

El blindaje preventivo —perfil aislado, providers, tags obligatorios y un budget con alertas— se
monta en [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) antes de crear el primer recurso; el barrido verificado vive en
[`L09`](l09-costos-y-destruccion-verificada.md).

> ⚠️ **Un budget de Cost Management no es un tope de gasto.** La
> [documentación](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets)
> es explícita: los recursos no se ven afectados y el consumo no se detiene. Además, los datos de
> costo tardan de 8 a 24 horas en aparecer, el budget se evalúa cada 24 horas, y en una suscripción
> nueva Cost Management puede tardar hasta 48 horas en estar disponible. Un budget te avisa de lo
> que olvidaste ayer, no de lo que estás encendiendo ahora. Para que algo ocurra automáticamente
> hay que conectarlo a un action group. El único mecanismo que sí detiene el gasto es el spending
> limit de §1, y solo existe mientras la suscripción sea de crédito.

El budget del lab se fija en **$5 al mes** sobre la suscripción, con alertas al 20 %, 50 % y 100 %
del costo real y al 100 % del pronosticado. Cinco veces el costo de la serie completa: si salta la
primera alerta, algo se quedó encendido.

---

## 7. 🧭 Cómo recorrer la serie

### 7.1 Por qué nueve labs

El número de labs no se hereda de ningún otro curso: **lo decide la nube que se está
practicando**, y hay tres hechos de Azure que empujan la serie hacia arriba.

**La red se practica porque el diagnóstico es de Azure, y casi no cuesta.** La VNet, sus subnets y
sus NSG no cobran. Lo que cobra —un private endpoint y una VM de diagnóstico durante una hora— son
centavos, y a cambio se practica el diagnóstico más frecuente de Azure: un FQDN que resuelve a la IP
pública cuando debería resolver a la privada. Un tema que aparece en toda entrevista de arquitectura
en Azure, y en banca en particular, no se queda en el capítulo teórico por cinco centavos.

**Azure tiene dos planos de identidad y dos sesiones no sobran.** Una cosa es que tu código
obtenga un token para llamar a Azure —managed identities, role assignments, plano de datos, eso es
[`L02`](l02-entra-id-rbac-y-managed-identities.md)—, y otra que tu API valide los tokens que le llegan —app registrations,
scopes, app roles, eso es [`L06`](l06-identidad-de-aplicaciones-api-protegida.md)—. Las dos son gratis, las dos se preguntan en toda
entrevista de backend en Azure y las dos producen errores distintos que conviene no mezclar en la
misma tarde.

**Container Apps y el flujo de eventos son dos aprendizajes distintos.** El contrato de la
plataforma —puerto, revisiones, reparto de tráfico, escala a cero, identidad— se entiende con un
solo servicio y ningún mensaje de por medio. Encadenarlo con Service Bus, Cosmos DB y una DLQ en la
misma sesión mezcla dos diagnósticos: cuando algo falle, tienes que poder decir si el problema es
del contenedor o de la entrega.

La contrapartida es que **las sesiones son cortas y fáciles de retomar**. Nueve labs de dos o tres
horas se hacen en nueve tardes, y cada uno cierra con su propio teardown.

### 7.2 El índice

Los labs son **acumulativos y en orden**. Cada uno asume el estado que dejó el anterior, y cada
nombre de este índice enlaza con su documento.

```text
L01  suscripción, CLI aislada y blindaje de costos        $0.00      60–90 min
  │  deja: inv-lab-rg con el action group, providers registrados, budget con alertas
  ▼
L02  Entra ID, Azure RBAC y managed identities             $0.00      2–3 h
  │  deja: identidades, storage account y Key Vault con RBAC
  ▼
L03  Bicep desde la CLI                                    $0.00      2–3 h
  │  deja: lo mismo, ahora administrado por un Deployment Stack
  ▼
L04  red: VNet, NSG, private endpoint y DNS                ~$0.07     2–3 h
  │  deja: la VNet, sin VM ni private endpoint
  ▼
L05  Container Apps: revisiones, tráfico y escala          ~$0.17     3 h
  │  deja: inv-api corriendo, registry y environment vivos
  ▼
L06  identidad de aplicaciones: una API protegida          $0.00      2–3 h
  │  deja: inv-api exigiendo tokens; app registrations creadas
  ▼
L07  datos y eventos: Cosmos DB y Service Bus              ~$0.05     3–4 h
  │  deja: el sistema de §5 completo
  ▼
L08  observabilidad: KQL, auditoría y alertas              $0.00      2–3 h
  │  deja: lo mismo, ahora observable
  ▼
L09  costos y destrucción verificada                       $0.00      2 h
     deja: la suscripción vacía, verificada, sin nada soft-deleted
```

Lo que cada uno practica, en una línea:

- **[`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md)** — `AZURE_CONFIG_DIR` para una CLI aislada de tu sesión de trabajo, `az login` y la
  suscripción activa, registro explícito de providers (y el `MissingSubscriptionRegistration` que
  sale cuando te olvidas), el resource group con tags obligatorios y el budget con action group.
- **[`L02`](l02-entra-id-rbac-y-managed-identities.md)** — una storage account sin access keys, el Owner de la suscripción que no puede leer un
  blob, role assignments en el scope correcto y en el equivocado, la propagación, un token decodificado
  con `az account get-access-token`, dos user-assigned identities y un Key Vault con RBAC.
- **[`L03`](l03-bicep-desde-la-cli.md)** — lo de [`L02`](l02-entra-id-rbac-y-managed-identities.md) reescrito en Bicep con versiones de API fijas, `what-if` antes de cada
  despliegue, drift provocado desde `az`, un modo complete que borra lo que no esperabas, un lock
  `CanNotDelete` que bloquea `az group delete`, una Azure Policy asignada al resource group que
  rechaza los recursos sin tags, y un Deployment Stack cuyos deny settings crean el deny assignment
  que tú no puedes crear.
- **[`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md)** — VNet y subnets propias, NSG con prioridades y service tags, un private endpoint a la
  storage account con su Private DNS zone, la resolución que falla sin el VNet link, y el
  diagnóstico con effective routes, effective security rules e IP flow verify desde una VM sin IP
  pública operada con `az vm run-command`.
- **[`L05`](l05-container-apps-revisiones-trafico-y-escala.md)** — imagen de `inv-api` construida en local para `linux/amd64` y subida a Container
  Registry, `AcrPull` con managed identity en vez de admin user, el environment con su workspace
  declarado, revisiones, reparto de tráfico para un canary, escala a cero y el cold start de la JVM.
- **[`L06`](l06-identidad-de-aplicaciones-api-protegida.md)** — la app registration de la API con su Application ID URI, un scope delegado y un app
  role, un cliente humano y un cliente máquina (la managed identity de otra app), la validación del
  JWT en Spring Boot y los errores de audiencia, de issuer y de versión de token.
- **[`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md)** — cuenta de Cosmos DB con free tier y partition key declarada, escritura idempotente,
  un `429` provocado, namespace de Service Bus Standard con topic y subscription, `inv-projector`
  escalando por mensajes pendientes, un mensaje envenenado en la DLQ y roles de datos por identidad.
- **[`L08`](l08-observabilidad-kql-y-auditoria.md)** — un Log Analytics workspace, diagnostic settings de Service Bus y Key Vault,
  Application Insights con el agente Java, consultas KQL, el Activity Log que dice quién borró qué y
  la alerta de métrica sobre la DLQ.
- **[`L09`](l09-costos-y-destruccion-verificada.md)** — atribuir el gasto por tag en Cost Management, y el teardown en capas: el stack, el
  resource group, lo soft-deleted, lo que vive fuera del resource group y lo que vive en el tenant.

Los cinco apéndices se consultan en cualquier momento: [`A01`](a01-az-de-supervivencia.md) para la mecánica de `az`, [`A02`](a02-costos-trampas-y-recursos-huerfanos.md) para el
catálogo de qué cobra y qué sobrevive a un borrado, [`A03`](a03-catalogo-de-errores-y-diagnostico.md) para el catálogo de errores con el comando
que confirma cada causa, [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) para la rutina de §7.4 y [`A05`](a05-kql-de-supervivencia.md) para las consultas KQL de diagnóstico.

> 💡 **Truco.** Si vienes con poco tiempo, el recorrido mínimo que sigue enseñando algo es [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) →
> [`L02`](l02-entra-id-rbac-y-managed-identities.md) → [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) → [`L09`](l09-costos-y-destruccion-verificada.md): blindas la suscripción, entiendes RBAC, despliegas algo con identidad propia
> y lo destruyes verificando.

### 7.3 El resource group es la unidad de destrucción, con letra pequeña

`az group delete --name inv-lab-rg` borra en cascada todo lo que contiene el resource group. Es la
base de todos los teardowns de la serie, y la
[documentación](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/delete-resource-group)
describe el orden en que ARM borra las dependencias. Pero hay cinco cosas que sobreviven, y cada lab
que las provoca lo dice en el punto en que las crea:

1. **Lo que queda soft-deleted.** Un Key Vault borrado queda recuperable entre 7 y 90 días —90 por
   defecto, fijado al crearlo y sin posibilidad de cambiarlo después—, y durante ese período **su
   nombre no se puede reutilizar**; si además tiene purge protection, no hay forma de acortarlo
   ([soft-delete de Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview)).
   Un Log Analytics workspace queda 14 días en soft-delete con el nombre reservado, salvo que lo
   borres con `--force`
   ([borrado de workspaces](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/delete-workspace)).
2. **Lo que Azure crea fuera de tu resource group.** Crear una VNet habilita
   [Network Watcher](https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-create)
   en esa región, en un resource group llamado `NetworkWatcherRG`. No cobra por existir, pero
   aparece en tu inventario y nadie te avisó.
3. **Lo que vive en el tenant, no en la suscripción.** Las app registrations de [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) no están en
   ningún resource group. Borradas, quedan
   [30 días en estado suspendido](https://learn.microsoft.com/en-us/entra/identity-platform/howto-restore-app)
   antes del borrado permanente.
4. **Los role assignments en scopes superiores.** Uno hecho sobre la suscripción no muere con el
   resource group, y uno cuyo principal se borró queda como "Identity not found".
5. **Lo que bloquea el borrado.** Un
   [resource lock](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources)
   `CanNotDelete` hace fallar `az group delete` entero, y un Deployment Stack con deny settings
   impide borrar sus recursos por fuera del stack; [`L03`](l03-bicep-desde-la-cli.md) reproduce los dos casos.

### 7.4 La rutina de recurso: CLI, API y destrucción

Los labs recorren un sistema completo, pero hay un aprendizaje que no se consigue recorriendo nada:
**saber crear, inspeccionar, modificar y destruir un recurso cualquiera desde cero**. Es lo que se
pregunta en una entrevista con la forma *"¿cómo harías X en Azure?"*.

Para eso el curso define **una rutina fija, la misma para todos los servicios**, desarrollada en
[`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md):

```text
1. Crear        az ... create
2. Inspeccionar az ... show --output json      ¿qué propiedades tiene de verdad?
3. Modificar    az ... update                  ¿qué es mutable y qué obliga a recrear?
4. Destruir     az ... delete
5. Verificar    az ... list / list-deleted     ¿qué quedó vivo o soft-deleted?
6. Repetir todo lo anterior desde el Azure SDK for Java
```

El puente entre el paso 5 y el 6 es este:

```bash
az group show --name inv-lab-rg --debug
```

- `--debug` es un argumento global de `az` que imprime en `stderr` todo lo que la CLI hace por
  dentro, incluidas **la petición HTTP a Azure Resource Manager y su respuesta**: el método, la URL
  completa sobre `management.azure.com` con el resource ID y su `api-version`, y el cuerpo JSON. Es
  la prueba de que `az` no es "otra cosa" distinta de la API: es un cliente de la API.
- La salida es larga y mezcla la carga de la configuración con la petición; en [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) se aprende a
  filtrarla. Trae los IDs de tu suscripción y tu tenant y las cabeceras de cada petición, así que
  **nunca se pega una salida de `--debug` sin revisarla y anonimizarla**.

La misma petición se repite a mano con `az rest --method get --url` seguido del resource ID, que
agrega el token por ti. A partir de ahí, escribir esa llamada con el SDK deja de ser un ejercicio de
documentación y pasa a ser una traducción.

Tres cosas que la rutina enseña y que ningún capítulo teórico transmite igual:

- **Las operaciones de larga duración.** Muchos `create` y `delete` de ARM devuelven `201` o `202`
  con una URL para consultar el estado, no el recurso terminado. `az` espera por ti —salvo que le
  pases `--no-wait`— y por eso parece síncrono; desde el SDK usas un poller explícito.
- **De dónde saca credenciales tu código.** El fragmento en Java falla hasta que
  `DefaultAzureCredential` encuentra una credencial en su cadena, y ahí se entiende por qué en local
  usa tu sesión de `az` y en Container Apps usa la managed identity sin cambiar una línea.
- **Control plane frente a data plane.** Crear el contenedor de un blob por ARM y escribir el blob
  por el endpoint de la storage account son dos llamadas a dos hosts distintos, con dos permisos
  distintos. Verlo en `--debug` fija el concepto de [`01`](01-infraestructura-global-y-resource-manager.md#10--control-plane-y-data-plane) y [`10`](10-autorizacion-rbac-policy-y-gobierno.md#3--role-definitions-actions-y-dataactions).

El costo de la rutina es deliberadamente ridículo —un resource group, una identidad, una storage
account o un NSG no cobran por existir— y lo que queda después no es el recurso: es **el script y
el fragmento de código anotados**.

---

## 8. 🧪 Emuladores locales: qué sirve y qué miente

Azure tiene más emuladores oficiales que otras nubes, y eso obliga a ser preciso con lo que cada uno
no hace. La columna que importa es la de fidelidad.

| Servicio | Sustituto local | Fidelidad |
|---|---|---|
| Blob, Queue y Table Storage | [Azurite](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite) (oficial, open source) | Media. Blob y Queue sí; Table en preview; no Azure Files ni Data Lake. Autentica con claves y SAS: no hay RBAC que deniegue, ni tiers, ni firewall |
| Cosmos DB | [Emulador de Cosmos DB](https://learn.microsoft.com/en-us/azure/cosmos-db/emulator) (oficial) | Media. Solo throughput provisionado, sin serverless; una clave conocida en vez de Entra ID; una sola instancia, sin multi-región; la versión de Windows solo marca el nivel de consistencia, no lo implementa. La imagen clásica de Linux no corre en Apple silicon; el [emulador Linux nuevo](https://learn.microsoft.com/en-us/azure/cosmos-db/emulator-linux) es la alternativa |
| Service Bus | [Emulador de Service Bus](https://learn.microsoft.com/en-us/azure/service-bus-messaging/overview-emulator) (oficial, Docker) | Media. AMQP sobre TCP sí; sin integración con Entra ID ni VNet, sin Activity Log, sin entidades particionadas, sin JMS, TTL máximo de una hora y nada persiste al reiniciar el contenedor |
| Container Apps | `docker run` de la misma imagen | Media. La imagen es idéntica; revisiones, escala a cero, KEDA e identidad no se emulan |
| PostgreSQL, SQL Server, Redis | El motor en contenedor | No aplica: el motor es el mismo; lo administrado no se emula |
| Entra ID | Keycloak (terceros) | Sirve para OIDC y JWT como concepto, no como producto: ni app roles de Entra, ni tokens v2, ni managed identities |
| RBAC, VNet, Policy, facturación, Bicep contra ARM | Ninguno | No se emulan de forma útil |

Lo común a todos: **ninguno evalúa RBAC, ninguno cobra y ninguno reproduce la propagación de un role
assignment ni el throttling real.** Son andamio de desarrollo.

> 💡 **Truco.** Corre la misma prueba contra el emulador y contra Azure, y anota cada diferencia. Esa
> lista —"qué me mintió el emulador"— es material de entrevista de primera, porque demuestra que
> entiendes el servicio y no solo su API.

---

## 9. 🧪 Ampliaciones opcionales

Drills sueltos, **no acumulativos**, que se encienden y se destruyen en la misma sesión, en un
resource group propio (`inv-drill-rg`) para que su teardown no toque el del tronco. Cada uno cubre
exactamente los conceptos que §3 y §4 identificaron como "de Azure" en un producto excluido.

| Drill | Qué añade que no aprendes en local | Costo aproximado por sesión de 3 h |
|---|---|---|
| AKS, solo la costura | Workload identity, `Service` → Load Balancer + IP pública, Azure CNI | Nodos por hora más $0.015 de IP pública; control plane sin cargo en tier Free |
| Azure SQL Database, oferta gratuita | Serverless con auto-pause, autenticación con Entra ID, PITR | $0.00 con "auto-pause hasta el mes siguiente" |
| Application Gateway + WAF | Listeners, reglas por path, health probes, WAF | $0.60 en costo fijo más capacity units |
| Event Grid | System topics, handshake de validación del webhook, dead-letter a blob | $0.00 dentro de 100.000 operaciones al mes |
| API Management Consumption | Políticas, `validate-jwt` en el borde, productos | $0.00 dentro de 1 millón de llamadas al mes |
| GitHub Actions con OIDC | Federated credential, despliegue sin secretos | $0.00 |

Cada drill se recorre con la rutina de §7.4.

> ⚠️ En el drill de AKS el orden del teardown importa: primero `kubectl delete` de los `Service` de
> tipo `LoadBalancer` y de los `PersistentVolumeClaim`, se espera a que Azure libere la IP pública y
> los discos, y solo entonces se borra el cluster. AKS guarda sus nodos y su red en un segundo
> resource group administrado (`MC_…`), que se va con el cluster; lo que creaste tú fuera de él, no.
> El barrido de [`L09`](l09-costos-y-destruccion-verificada.md) se corre antes de cerrar la sesión.

---

## 10. 🧭 Relación con el resto del repositorio

Esta serie vive junto a los repasos de AWS (`01-aws/`) y GCP (`02-gcp/`), que tienen sus propias
series prácticas con la misma doctrina de reparto. No se apoya en ellos: el curso es autocontenido
y no traduce conceptos desde otra nube. Lo que comparten es el método —pagar solo por lo que la nube
enseña, destruir con certeza, reproducir antes de reparar— y los nombres del sistema de inventario
(`inv-api`, `inv-projector`, `inv-events`), para que quien haga las tres series compare servicios
con el mismo problema delante.

```text
contenedores en local    → cómo funciona un contenedor y cómo se orquestan muchos
                           Kubernetes, mensajería, observabilidad, pipelines

repaso de Azure          → qué cambia cuando el dueño de la infraestructura es otro:
+ serie práctica L01–L09   identidad, scopes, red privada, IaC, servicios administrados y costo
```

---

## 11. 📝 Decisiones: las cerradas y las que siguen abiertas

Las que bloqueaban la escritura de los labs quedan cerradas el 27 de septiembre de 2026, con su
porqué, porque el criterio vale más que la elección:

| Decisión | Elegida | Por qué |
|---|---|---|
| Región | **`eastus2`** | La API de precios devuelve medidores en `eastus2` para cada servicio del tronco, con los precios de §4 y §6; es una región con Availability Zones |
| Mensajería del tronco | **Service Bus Standard** | $0.0134/h —unos cuatro centavos por sesión— compra topics, subscriptions, sessions, duplicate detection y DLQ, que es lo que se pregunta. Basic no tiene topics; Event Grid + Storage Queue sería gratis y no enseñaría nada de eso |
| Cómputo del tronco | **Container Apps en plan Consumption**, sin VNet propia en [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) | Free grant suficiente, sin cargo de gestión; integrarlo con la VNet de [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) obligaría a un environment con subnet delegada que no añade diagnóstico nuevo |
| Lenguaje de `inv-api`, `inv-projector` y del SDK de [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) | **Java 21 con Spring Boot** | Es el perfil del curso y el stack de la entrevista. La versión exacta de Spring Boot y del Azure SDK for Java se fija y se verifica al escribir [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) |
| Construcción de la imagen | **`docker build --platform linux/amd64` en local → Container Registry** | Primero el mecanismo; `az acr build` se menciona como atajo diciendo qué esconde. El `--platform` explícito existe porque una imagen `arm64` construida en un Mac con Apple silicon no es la que la plataforma espera, y [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) reproduce ese fallo |
| Reparto Bicep / `az` | **Bicep la infraestructura, `az` el despliegue de revisiones** | Bicep administra lo que [`L09`](l09-costos-y-destruccion-verificada.md) tiene que poder destruir y verificar; las revisiones de Container Apps van con `az` para no meter un `what-if` en cada iteración. Matiz de 2026-09-29: el Deployment Stack de [`L03`](l03-bicep-desde-la-cli.md) gestiona el núcleo de identidad y datos de [`L02`](l02-entra-id-rbac-y-managed-identities.md); la red, el cómputo y la mensajería de [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md)–[`L08`](l08-observabilidad-kql-y-auditoria.md) se crean con `az`, por la regla de primero el mecanismo, y se destruyen con el resource group |
| Tope de gasto | **Serie por debajo de $1; budget de alerta a $5 al mes** | §6 |

Y las que siguen abiertas, sin bloquear nada:

1. **Si [`L02`](l02-entra-id-rbac-y-managed-identities.md) merece dividirse.** Entra ID, RBAC, plano de datos y Key Vault caben en una sesión;
   workload identity federation se fue a §9. Es la frontera menos firme de la serie.
2. **La managed identity como cliente en [`L06`](l06-identidad-de-aplicaciones-api-protegida.md).** Asignarle un app role al service principal de una
   managed identity se hace hoy con Microsoft Graph, no con un comando `az` de primera clase; [`L06`](l06-identidad-de-aplicaciones-api-protegida.md)
   decide si lo enseña con `az rest` contra Graph o si usa una segunda app registration. *Resuelta al
   escribir `L06` el 2026-09-29:* `az rest` contra Graph, y la identidad se ejerce desde un Container
   Apps job efímero con la imagen de la CLI, antes de que exista `inv-projector`.
3. **Repositorio de código.** Si el Bicep, los scripts y los fragmentos de SDK van a vivir en un
   repo público como portafolio, conviene decidirlo antes de escribir [`L03`](l03-bicep-desde-la-cli.md). Los labs lo dejan
   en `~/inv-lab/` en la máquina del lector (`infra`, `inv-api`, `inv-projector`, `routine`), sin
   decidir si se publica.

---

## 🧠 Preguntas rápidas

1. ¿Qué condición tiene que cumplir un tema para entrar al laboratorio de pago?
2. ¿Qué tres mecanismos gratuitos trae la cuenta gratuita de Azure y cuál sostiene de verdad el laboratorio?
3. ¿En qué se diferencia el spending limit de un budget, y qué le pasa al spending limit cuando pasas la suscripción a pay-as-you-go?
4. ¿Por qué el argumento "el control plane de Kubernetes es caro" no sirve para descartar AKS, y cuál es el argumento correcto?
5. ¿Qué pregunta decide si un servicio dudoso merece un lab del tronco, un drill o un contenedor local?
6. ¿Por qué el laboratorio no pone Front Door ni Application Gateway delante de Container Apps?
7. ¿Por qué `L04` enciende una VM si las VMs están excluidas, y cómo se opera sin IP pública ni Bastion?
8. ¿Cuál es el único cargo real del tronco y por qué se crea una sola vez en toda la serie?
9. ¿Qué crea `az containerapp env create` si no le pasas un workspace, y por qué importa?
10. ¿Qué cinco cosas sobreviven a `az group delete --name inv-lab-rg`?
11. ¿Por qué no puedes volver a crear un Key Vault con el mismo nombre justo después de borrarlo?
12. ¿Qué le falta al emulador de Service Bus respecto del servicio real que `L07` necesita practicar?
13. ¿Por qué la serie tiene un lab de identidad de aplicaciones separado del de RBAC y managed identities?
14. ¿Qué hace `--debug` y por qué es el puente entre la CLI y el SDK?
15. ¿Por qué se eligió Service Bus Standard y no Basic ni Event Grid con Storage Queue para el tronco?

---

## 📚 Referencias oficiales

- Cuenta gratuita de Azure (crédito, 12 meses, siempre gratis): https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account
- Lista de servicios gratuitos: https://azure.microsoft.com/en-us/pricing/free-services
- Evitar cargos con la cuenta gratuita: https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/avoid-charges-free-account
- Spending limit: https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/spending-limit
- Crear y administrar budgets: https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets
- Azure Retail Prices API: https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices
- Calculadora de precios: https://azure.microsoft.com/en-us/pricing/calculator/
- Precios de Container Apps: https://azure.microsoft.com/en-us/pricing/details/container-apps/
- Facturación de Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/billing
- Precios de Container Registry: https://azure.microsoft.com/en-us/pricing/details/container-registry/
- Free tier de Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/free-tier
- Precios de Cosmos DB (provisionado): https://azure.microsoft.com/en-us/pricing/details/cosmos-db/autoscale-provisioned/
- Precios de Service Bus: https://azure.microsoft.com/en-us/pricing/details/service-bus/
- Precios de Azure Monitor: https://azure.microsoft.com/en-us/pricing/details/monitor/
- Precios de Key Vault: https://azure.microsoft.com/en-us/pricing/details/key-vault/
- Precios de Private Link: https://azure.microsoft.com/en-us/pricing/details/private-link/
- Precios de Virtual Machines Linux: https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/
- Precios de AKS: https://azure.microsoft.com/en-us/pricing/details/kubernetes-service/
- Precios de Application Gateway: https://azure.microsoft.com/en-us/pricing/details/application-gateway/
- Precios de Front Door: https://azure.microsoft.com/en-us/pricing/details/frontdoor/
- Precios de Azure Firewall: https://azure.microsoft.com/en-us/pricing/details/azure-firewall/
- Precios de NAT Gateway: https://azure.microsoft.com/en-us/pricing/details/azure-nat-gateway/
- Precios de Azure Bastion: https://azure.microsoft.com/en-us/pricing/details/azure-bastion/
- Precios de API Management: https://azure.microsoft.com/en-us/pricing/details/api-management/
- Precios de Event Grid: https://azure.microsoft.com/en-us/pricing/details/event-grid/
- Precios de Event Hubs: https://azure.microsoft.com/en-us/pricing/details/event-hubs/
- Precios de PostgreSQL Flexible Server: https://azure.microsoft.com/en-us/pricing/details/postgresql/flexible-server/
- Precios de Azure Managed Redis: https://azure.microsoft.com/en-us/pricing/details/managed-redis/
- Oferta gratuita de Azure SQL Database: https://learn.microsoft.com/en-us/azure/azure-sql/database/free-offer
- Borrar un resource group y sus recursos: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/delete-resource-group
- Resource locks: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources
- Deployment Stacks: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks
- Resource providers y tipos de recurso: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types
- Soft-delete de Key Vault: https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview
- Borrar y recuperar un Log Analytics workspace: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/delete-workspace
- Habilitar o deshabilitar Network Watcher: https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-create
- Restaurar o eliminar una app registration borrada: https://learn.microsoft.com/en-us/entra/identity-platform/howto-restore-app
- Troubleshooting de Azure RBAC: https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting
- Run Command en VMs Linux: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/run-command
- IP flow verify de Network Watcher: https://learn.microsoft.com/en-us/azure/network-watcher/ip-flow-verify-overview
- Configuración de la CLI (`AZURE_CONFIG_DIR`, `az config`): https://learn.microsoft.com/en-us/cli/azure/azure-cli-configuration
- Referencia de `az rest` y comandos globales: https://learn.microsoft.com/en-us/cli/azure/reference-index
- Troubleshooting de la CLI (`--debug`): https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-successfully-troubleshooting
- Azure Identity para Java (`DefaultAzureCredential`): https://learn.microsoft.com/en-us/java/api/overview/azure/identity-readme
- Azurite: https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite
- Emulador de Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/emulator
- Desarrollo con el emulador de Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-develop-emulator
- Emulador de Cosmos DB basado en Linux: https://learn.microsoft.com/en-us/azure/cosmos-db/emulator-linux
- Emulador de Service Bus: https://learn.microsoft.com/en-us/azure/service-bus-messaging/overview-emulator

### Herramientas de terceros (opcional)

No forman parte del material de referencia del curso; se listan solo porque el laboratorio local
las utiliza.

- `kind` (Kubernetes en Docker): https://kind.sigs.k8s.io/
- Keycloak: https://www.keycloak.org/
