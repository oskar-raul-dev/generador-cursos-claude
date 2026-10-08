# A02 — Costos, trampas y recursos huérfanos

> **Objetivo:** tener en una página lo que cobra por existir, lo que cobra por uso y casi nunca te
> alcanza, lo que es gratis de verdad, y el catálogo de lo que sobrevive a cada borrado. Es el apéndice
> que se consulta antes de encender algo y después de destruirlo.
> **Se asume leído:** [`L00` §6](l00-idea-lab-practico.md#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas)
> (presupuesto). Su complemento práctico es [`L09`](l09-costos-y-destruccion-verificada.md).
> **Precios de referencia:** `eastus2`, dólares y precio de lista, verificados contra la Azure Retail
> Prices API en el capítulo que se cita junto a cada cifra, entre el 27 y el 29 de septiembre de 2026.
> Verifica siempre en la [calculadora](https://azure.microsoft.com/en-us/pricing/calculator/) antes de
> encender algo.
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [Tres preguntas](#1--tres-preguntas-antes-de-crear-cualquier-cosa) ·
[Lo gratis de verdad](#2--qué-es-gratis-de-verdad) · [Lo que cobra por existir](#3--el-catálogo-de-lo-que-cobra-por-existir) ·
[Lo que cobra por uso](#4--lo-que-cobra-por-uso-y-casi-nunca-te-alcanza) ·
[Huérfanos](#5--el-catálogo-de-huérfanos-qué-sobrevive-a-qué-borrado) ·
[Por qué el tag no basta](#6--por-qué-un-barrido-por-tag-no-demuestra-nada) ·
[El barrido](#7--el-barrido-de-verificación) · [Budget y spending limit](#8--budgets-y-spending-limit-lo-que-hacen-y-lo-que-no) ·
[Leer la factura](#9--leer-la-factura-y-atribuir-el-gasto) · [Las diez trampas](#10--las-diez-trampas-en-una-tabla) ·
[Preguntas](#-preguntas-rápidas)

Este apéndice no tiene orden ni prerrequisitos: se entra por la sección que necesitas.

---

## 1. 🧭 Tres preguntas antes de crear cualquier cosa

Casi todas las facturas inesperadas de un proyecto de práctica se evitan con tres preguntas hechas
**antes** del `create`:

```text
1. ¿Cobra por existir?             → si sí, su teardown se escribe ahora, junto al create
2. ¿Qué deja al borrarlo?          → soft-delete, discos, IPs, grupos administrados, objetos del tenant
3. ¿Qué crea por mí sin decírmelo? → workspaces, NetworkWatcherRG, grupos de infraestructura, apps
```

La primera separa los recursos con **cargo base** —cobran aunque no reciban ni una petición— de los que
cobran **por uso**. La segunda es la letra pequeña de [`L00` §7.3](l00-idea-lab-practico.md#73-el-resource-group-es-la-unidad-de-destrucción-con-letra-pequeña).
La tercera es la que nadie se hace: un comando que crea dos recursos donde tú pediste uno.

> 🧠 **Modelo mental.** En la nube no pagas por lo que usas: pagas por lo que existe y por lo que usas.
> La primera mitad es la que se olvida.

---

## 2. 🧱 Qué es gratis de verdad

Hay cuatro fuentes de gratuidad, y no son la misma ([`L00` §1](l00-idea-lab-practico.md#1--las-dos-restricciones-de-partida)):

| Fuente | Qué da | Cuándo se acaba |
|---|---|---|
| Crédito de bienvenida | $200 para casi cualquier servicio | A los 30 días o al gastarlo |
| Servicios gratis por 12 meses | Cuotas mensuales de más de 20 servicios, solo cuentas nuevas | A los 12 meses |
| Servicios siempre gratis | Cuotas mensuales de más de 65 servicios | Mientras Microsoft no las cambie |
| **Ofertas propias de cada servicio** | Las de la tabla siguiente | No dependen del tipo de cuenta |

Las que sostuvieron la serie práctica, y dónde se verificaron:

| Servicio | Oferta | Detalle |
|---|---|---|
| Container Apps | 180.000 vCPU-segundos, 360.000 GiB-segundos y 2 millones de requests por suscripción y mes | [`04` §5](04-computo-y-contenedores.md#5--container-apps) |
| Cosmos DB | Free tier: 1.000 RU/s y 25 GB de por vida, **una cuenta por suscripción, solo al crearla** | [`08` §6](08-cosmos-db.md#6--provisionado-autoscale-o-serverless) |
| Log Analytics | 5 GB de ingesta al mes; la tabla `AzureActivity` no cobra ingesta | [`14` §4](14-observabilidad-monitor-log-analytics-app-insights.md#4--el-log-analytics-workspace) |
| Alertas de métrica | Las primeras 10 series vigiladas | [`14` §8](14-observabilidad-monitor-log-analytics-app-insights.md#8--alertas-y-action-groups) |
| Action groups | Los primeros 1.000 correos al mes | [`L01` §6](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md#6--el-action-group-a-quién-avisar) |
| Azure SQL Database | Hasta 10 bases serverless General Purpose con 100.000 vCore-segundos y 32 GB al mes cada una | [`07` §4](07-bases-relacionales-y-cache.md#4--serverless-y-la-oferta-gratuita) |
| Event Grid | 100.000 operaciones al mes | [`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones) |
| API Management Consumption | 1 millón de llamadas al mes | [`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones) |

Y lo que no cobra por existir, aunque parezca que sí: resource groups, VNets, subnets, NSG, user-assigned
managed identities, role assignments, app registrations, las asignaciones de Azure Policy, Network
Watcher, un Container Apps environment en plan Consumption y una app escalada a cero.

---

## 3. 💰 El catálogo de lo que cobra por existir

Todo lo de esta tabla cobra **aunque no reciba ni una petición**. Es la lista que se repasa antes de
cerrar la sesión.

| Recurso | Cargo base | Unidad | Dónde se verificó |
|---|---|---|---|
| Container Registry Basic | $0.1666 | **por día** | [`04` §10](04-computo-y-contenedores.md#10--container-registry) |
| Service Bus Standard | $0.013441 | por hora | [`13` §3](13-mensajeria-y-eventos.md#3--service-bus-el-broker-empresarial) |
| Cosmos DB, 100 RU/s manuales (fuera del free tier) | $0.008 | por hora | [`08` §6](08-cosmos-db.md#6--provisionado-autoscale-o-serverless) |
| Private endpoint | $0.01 | por hora | [`03` §3](03-conectividad-privada-y-dns.md#3--private-endpoints-y-private-link) |
| Private DNS zone | $0.50 | por mes | [`03` §6](03-conectividad-privada-y-dns.md#6--private-dns-zones) |
| IP pública Standard | $0.005 | por hora, asociada o no | [`02` §8](02-redes-vnet-nsg-y-enrutamiento.md#8--ip-públicas) |
| NAT Gateway | $0.045 | por hora | [`02` §7](02-redes-vnet-nsg-y-enrutamiento.md#7--salida-a-internet) |
| VM B1ls | $0.0052 | por hora encendida | [`04` §2](04-computo-y-contenedores.md#2--virtual-machines) |
| Managed disk Standard HDD S4 | $1.536 | por mes, con la VM encendida o no | [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md#4--la-vm-de-diagnóstico-sin-ip-pública) |
| Managed disk Standard SSD E4 | $2.40 | por mes | [`04` §2](04-computo-y-contenedores.md#2--virtual-machines) |
| Azure Firewall Basic / Standard | $0.395 / $1.25 | por hora | [`02` §10](02-redes-vnet-nsg-y-enrutamiento.md#10--hub-and-spoke-y-azure-firewall) |
| Bastion Basic | $0.19 | por hora | [`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones) |
| Application Gateway Standard v2 / WAF v2 | $0.20 / $0.36 fijos | por hora, más capacity units | [`05` §3](05-balanceo-entrega-global-y-api-management.md#3--application-gateway) |
| Front Door Standard | $35 | por mes y perfil | [`05` §4](05-balanceo-entrega-global-y-api-management.md#4--front-door) |
| API Management Developer | $0.0658 | por hora | [`05` §7](05-balanceo-entrega-global-y-api-management.md#7--api-management) |
| AKS tier Standard | $0.10 | por hora y cluster, más los nodos | [`04` §8](04-computo-y-contenedores.md#8--aks-a-nivel-de-decisión) |
| PostgreSQL Flexible Server B1ms | $0.017 | por hora, más el almacenamiento | [`07` §9](07-bases-relacionales-y-cache.md#9--postgresql-flexible-server) |
| Azure Managed Redis B0 | $0.016 | por hora | [`07` §10](07-bases-relacionales-y-cache.md#10--caché-azure-managed-redis) |
| Event Hubs Standard | $0.03 | por hora y throughput unit | [`13` §8](13-mensajeria-y-eventos.md#8--event-hubs) |
| Service Bus Premium | $0.9275 | por hora y messaging unit | [`13` §3](13-mensajeria-y-eventos.md#3--service-bus-el-broker-empresarial) |
| Managed HSM Standard B1 | $3.20 | por hora | [`11` §2](11-secretos-cifrado-y-key-vault.md#2--key-vault-secretos-claves-y-certificados) |
| DNS Private Resolver | $180 | por mes y endpoint (inbound u outbound) | Retail Prices API, verificado en T9 |

Tres observaciones que valen más que la tabla:

- **La unidad importa tanto como el precio.** El registry cobra el día completo aunque exista diez
  minutos; un disco cobra el mes prorrateado aunque la VM esté apagada.
- **"Apagado" no es "borrado".** Una VM desasignada deja de cobrar cómputo, pero su disco y su IP
  pública Standard siguen cobrando ([`04`](04-computo-y-contenedores.md), pregunta 1).
- **Un olvido de una hora es centavos; de un mes, no.** NAT Gateway con su IP son unos $36 al mes;
  Azure Firewall Standard, unos $900. Lo que convierte un lab en factura no es el precio, es el tiempo.

---

## 4. 💰 Lo que cobra por uso, y casi nunca te alcanza

Cobran solo cuando algo pasa, y en un lab se quedan en fracciones de centavo. Merecen una línea porque en
producción son la mitad de la factura:

| Recurso | Precio | Dónde se verificó |
|---|---|---|
| Blob Storage hot LRS | $0.0184 por GB al mes; $0.05 por cada 10.000 escrituras | [`L02`](l02-entra-id-rbac-y-managed-identities.md) |
| Key Vault Standard | $0.03 por cada 10.000 operaciones | [`L02`](l02-entra-id-rbac-y-managed-identities.md) |
| Log Analytics, tablas Analytics | $2.76 por GB ingerido, tras los 5 GB gratis | [`14` §4](14-observabilidad-monitor-log-analytics-app-insights.md#4--el-log-analytics-workspace) |
| Alertas de log | $1.50 al mes cada 5 minutos; $3 cada minuto, por regla | [`14` §8](14-observabilidad-monitor-log-analytics-app-insights.md#8--alertas-y-action-groups) |
| Alertas de métrica | $0.10 por serie y mes, tras las 10 gratis | [`14` §8](14-observabilidad-monitor-log-analytics-app-insights.md#8--alertas-y-action-groups) |
| Container Apps Consumption | $0.000024 por vCPU-segundo; $0.40 por millón de requests, tras el free grant | [`04` §5](04-computo-y-contenedores.md#5--container-apps) |
| VNet peering global | $0.035 por GB, en cada sentido | [`02` §9](02-redes-vnet-nsg-y-enrutamiento.md#9--vnet-peering) |

> ⚠️ **La trampa de la ingesta es la única de esta tabla que crece sola.** Un diagnostic setting con
> `allLogs` en un recurso con mucho tráfico, o un agente sin sampling, puede ingerir gigas al día. El
> precio de ingesta ya incluye 31 días de retención: bajar la retención no ahorra; ingerir menos, sí
> ([`14`](14-observabilidad-monitor-log-analytics-app-insights.md), pregunta 6).

---

## 5. 💰 El catálogo de huérfanos: qué sobrevive a qué borrado

Lo que **no** se va con el borrado que parece que lo borra todo:

| Borras… | Y sobrevive… | Porque… | Se elimina con… |
|---|---|---|---|
| Una VM creada con la CLI | Su disco del sistema, su NIC y su IP pública | La CLI los crea en modo *detach* por defecto | `--*-delete-option Delete` al crearla, o borrarlos después |
| Un disco | Sus snapshots | Son recursos independientes | Borrarlos uno a uno |
| El resource group | Un **Key Vault** soft-deleted (7–90 días) con el nombre retenido | Soft-delete obligatorio | `az keyvault purge` (imposible con purge protection) |
| El resource group | Un **Log Analytics workspace** soft-deleted 14 días | Soft-delete por defecto | Borrarlo antes con `--force` |
| El resource group | `NetworkWatcherRG` | Azure lo creó al crear la primera VNet de la región | Borrarlo aparte si no hay otras VNets |
| El resource group | El grupo `ME_…` o `MC_…` de un Container Apps environment con VNet propia | La plataforma gestiona su infraestructura ahí | Se va con el environment; no se toca a mano |
| El resource group | El grupo `MC_…` de un cluster de AKS, y lo que creaste fuera de él | Nodos y red viven en el grupo administrado | Se va con el cluster; lo externo, a mano |
| El resource group | Budgets y diagnostic settings **de la suscripción** | Viven en otro scope | Borrarlos aparte |
| El resource group | Role assignments en la suscripción o en un management group | Viven en otro scope | `az role assignment delete` |
| El resource group | Las **app registrations** | Viven en el tenant | `az ad app delete` + borrado permanente en Graph |
| Una app registration | La propia app, **suspendida 30 días** | Soft-delete del directorio | `DELETE /directory/deletedItems/{id}` |
| Una managed identity | Sus role assignments en scopes que no se borraron, como *Identity not found* | El scope sigue existiendo | `az role assignment delete --ids` |
| Una storage account | La cuenta, recuperable 14 días | Recuperación de cuentas | Nada: no retiene el nombre ni cobra |
| El resource group con un stack `denyDelete` | Todo lo gestionado por el stack, y el propio borrado falla | Deny assignment | `az stack group delete --action-on-unmanage deleteResources` antes |
| El resource group con un lock `CanNotDelete` | Todo: el borrado falla | El lock protege a todos, incluido el Owner | Quitar el lock antes |

El recorrido completo, en el orden que funciona, está en [`L09`](l09-costos-y-destruccion-verificada.md).

---

## 6. 🧭 Por qué un barrido por tag no demuestra nada

`az resource list --tag project=inv-lab` es el primer comando de cualquier verificación, y **no basta**:
demuestra lo que etiquetaste, no lo que existe. Se le escapan cuatro cosas:

- **Lo que Azure creó por ti**: el workspace aleatorio de un Container Apps environment sin workspace
  declarado, `NetworkWatcherRG`, los grupos `ME_` y `MC_`. Ninguno lleva tu tag.
- **Lo que alguien creó con prisa**, sin el tag. Por eso [`L03`](l03-bicep-desde-la-cli.md) enseña a imponerlo con Azure Policy.
- **Lo soft-deleted**: un Key Vault o un workspace borrados no aparecen en `az resource list`, pero el
  nombre sigue retenido y, en el caso del workspace, los datos también.
- **Lo que no es un recurso de ARM**: app registrations, budgets, diagnostic settings de la suscripción.

> Regla de verificación: el tag te dice qué buscar; el inventario completo, los listados de
> soft-deleted y el tenant te dicen qué quedó.

---

## 7. 🩺 El barrido de verificación

El que usa el curso para cerrar cada tanda de labs, con lo que responde cada línea:

```bash
az resource list --tag project=inv-lab --output table                                   # lo etiquetado
az group list --query "[].name" --output tsv                                           # todos los grupos
az keyvault list-deleted --output table                                                # vaults soft-deleted
az monitor log-analytics workspace list-deleted-workspaces --output table              # workspaces soft-deleted
az monitor diagnostic-settings subscription list --query "value[].name"                # scope de suscripción
az ad app list --filter "startswith(displayName,'inv-')" --query "[].displayName"      # el tenant
az role assignment list --all --query "[?principalType=='Unknown'].id"                 # asignaciones huérfanas
```

- `az group list` sin filtro es el que encuentra `NetworkWatcherRG` y cualquier grupo administrado.
- `list-deleted` y `list-deleted-workspaces` son los únicos que ven lo soft-deleted.
- `diagnostic-settings subscription list` y `az ad app list` miran fuera de ARM.
- La última busca role assignments cuyo principal ya no existe.

Todo tiene que salir vacío salvo lo que la suscripción tuviera antes. Para un inventario de todas tus
suscripciones de una vez, [Resource Graph](https://learn.microsoft.com/en-us/azure/governance/resource-graph/overview)
responde en segundos con KQL ([`A01` §8](a01-az-de-supervivencia.md#8--filtrar-en-el-servidor-tags-tipos-y-resource-graph)).

---

## 8. 🧱 Budgets y spending limit: lo que hacen y lo que no

| | Budget | Spending limit |
|---|---|---|
| Dónde existe | Cualquier suscripción | Solo cuentas con crédito (gratuita y similares) |
| Qué hace | **Avisa** por correo o action group al cruzar un umbral real o pronosticado | **Detiene**: deshabilita los servicios al agotar el crédito |
| Qué no hace | No detiene ni limita nada | No se puede ajustar el monto; desaparece al pasar a pay-as-you-go |
| Latencia | Datos con 8–24 h de retraso; evaluación cada 24 h | Al agotarse el crédito |

> Regla importante: un budget es una alarma de humo, no un disyuntor. Si necesitas que algo se apague
> solo, lo conectas a un action group con una automatización propia, y asumes el riesgo de apagar
> producción.

El budget del lab ([`L01` §7](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md#7--el-budget-y-lo-que-de-verdad-hace))
tiene una alerta **de pronóstico** al 100 %: con un recurso olvidado que cobra por hora, la proyección a
fin de mes cruza el umbral días antes que el gasto real.

---

## 9. 🩺 Leer la factura y atribuir el gasto

Tres herramientas, de más visual a más automatizable:

- **Cost analysis** en el portal: el costo acumulado agrupado por servicio, resource group, recurso o
  tag. Es donde se empieza.
- **La API de consultas de Cost Management**, con `az rest`: la misma agrupación, en un script
  ([`L09` §3](l09-costos-y-destruccion-verificada.md#3--atribuir-el-gasto-por-tag)).
- **Exportaciones** programadas a una storage account, para quien analiza el costo con otras
  herramientas.

Y tres hechos que condicionan cualquier lectura:

- **Los datos llegan con 8 a 24 horas de retraso**, y una suscripción nueva puede tardar 48 horas en
  mostrar nada. Lo de hoy no está.
- **Los tags solo acompañan al costo mientras están puestos**: no se aplican hacia atrás
  ([documentación](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/understand-cost-mgt-data)).
- **La fila sin tag es la que hay que mirar**: lo que no etiquetaste es lo que no sabías que existía.

---

## 10. 📋 Las diez trampas, en una tabla

| # | La trampa | Cómo te muerde | La defensa |
|---|---|---|---|
| 1 | Container Registry cobra por día | Un registry de prueba cobra el día entero, cada día que exista | Crearlo una vez, borrarlo al final |
| 2 | Service Bus Standard cobra por hora | Un namespace "vacío" son $10 al mes | Borrarlo si pausas la serie |
| 3 | La VM borrada deja disco, NIC e IP | Un disco huérfano cobra meses | `--*-delete-option Delete` |
| 4 | La IP pública Standard cobra sin asociar | Una IP olvidada tras borrar el NAT o la VM | Borrarla después de lo que la usaba |
| 5 | `az containerapp env create` sin workspace | Un workspace aleatorio que nadie borra | Declarar el workspace |
| 6 | El Key Vault soft-deleted retiene el nombre | No puedes recrearlo; con purge protection, durante meses | Purge en el teardown; sin purge protection en labs |
| 7 | El workspace soft-deleted retiene nombre y datos | 14 días de datos que creías borrados | Borrarlo con `--force` |
| 8 | Budgets y diagnostic settings de la suscripción | Sobreviven al resource group | Borrarlos aparte |
| 9 | Las app registrations viven en el tenant | Quedan suspendidas 30 días | Borrado permanente en Graph |
| 10 | Un drill olvidado | Firewall, Application Gateway o NAT Gateway un mes: decenas o cientos de dólares | Drills en `inv-drill-rg`, borrado en la misma sesión |

---

## 🧠 Preguntas rápidas

1. ¿Qué tres preguntas haces antes de crear un recurso y qué evita cada una?
2. ¿Qué diferencia hay entre un recurso con cargo base y uno que cobra por uso? Da un ejemplo de cada uno de la serie.
3. ¿Por qué el Container Registry del lab se crea una sola vez y qué tiene de especial su unidad de cobro?
4. Desasignas una VM. ¿Qué deja de cobrar y qué sigue cobrando?
5. ¿Qué sobrevive a `az group delete` de un grupo con un Key Vault, un workspace y una VNet, y cómo eliminas cada cosa?
6. ¿Por qué un barrido con `az resource list --tag` no demuestra que la suscripción está limpia?
7. ¿Qué diferencia hay entre un budget y un spending limit, y cuál existe en pay-as-you-go?
8. ¿Por qué bajar la retención de un workspace no reduce la factura, y qué sí la reduce?
9. ¿Por qué Cost Management no te enseña hoy lo que encendiste esta mañana?
10. Borraste una managed identity y en la suscripción aparece un role assignment sin nombre. ¿Qué es y qué haces con él?

---

## 📚 Referencias oficiales

- Calculadora de precios: https://azure.microsoft.com/en-us/pricing/calculator/
- Azure Retail Prices API: https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices
- Servicios gratuitos de Azure: https://azure.microsoft.com/en-us/pricing/free-services
- Evitar cargos con la cuenta gratuita: https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/avoid-charges-free-account
- Spending limit: https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/spending-limit
- Crear y administrar budgets: https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets
- Cost analysis: https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/quick-acm-cost-analysis
- Datos de Cost Management y tags: https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/understand-cost-mgt-data
- API de consultas de Cost Management: https://learn.microsoft.com/en-us/rest/api/cost-management/query/usage
- Borrar una VM y sus recursos: https://learn.microsoft.com/en-us/azure/virtual-machines/delete
- Borrar un resource group: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/delete-resource-group
- Soft-delete de Key Vault: https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview
- Borrar y recuperar un Log Analytics workspace: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/delete-workspace
- Restaurar o eliminar una app registration: https://learn.microsoft.com/en-us/entra/identity-platform/howto-restore-app
- Resource Graph: https://learn.microsoft.com/en-us/azure/governance/resource-graph/overview
- Precios de Azure DNS (Private Resolver): https://azure.microsoft.com/en-us/pricing/details/dns/
