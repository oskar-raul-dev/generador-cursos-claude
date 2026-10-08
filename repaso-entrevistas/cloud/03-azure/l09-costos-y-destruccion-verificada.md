# L09 — Costos y destrucción verificada

> **Objetivo:** cerrar la serie como se cierra un proyecto de verdad: atribuir el gasto por tag en Cost
> Management y destruir todo **en capas**, verificando cada una —el budget y el diagnostic setting de la
> suscripción, el Deployment Stack, el workspace sin soft-delete, el resource group, lo soft-deleted, lo
> que Azure creó fuera del grupo y lo que vive en el tenant—, hasta una suscripción vacía y una factura
> que deja de crecer.
> **Se asume leído:** [`L00` §6–§7.3](l00-idea-lab-practico.md#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas)
> (presupuesto y letra pequeña del borrado). Es el complemento práctico de
> [`A02`](a02-costos-trampas-y-recursos-huerfanos.md).
> **Costo:** **$0.00**. Solo se borra y se consulta.
> **Duración:** 2 horas, y una comprobación final a las 48 horas.
> **Prerrequisitos:** los labs que hayas hecho de [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md)–[`L08`](l08-observabilidad-kql-y-auditoria.md). Cada capa dice qué comprobar si no
> llegaste al lab que la creó.
> **Qué queda encendido al terminar:** **nada**. Quedan los resource providers registrados, que no
> cobran, y el perfil local de la CLI hasta que lo borres.
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [Por qué en capas](#1--por-qué-en-capas) · [Arranque](#2--arranque) ·
[El gasto por tag](#3--atribuir-el-gasto-por-tag) · [Budget y Activity Log](#4--capa-1-lo-que-vive-en-la-suscripción) ·
[El stack](#5--capa-2-el-deployment-stack) · [Workspace](#6--capa-3-el-workspace-sin-soft-delete) ·
[El resource group](#7--capa-4-el-resource-group) · [Soft-deleted](#8--capa-5-lo-soft-deleted) ·
[Fuera del grupo](#9--capa-6-lo-que-azure-creó-fuera-de-tu-grupo) · [El tenant](#10--capa-7-lo-que-vive-en-el-tenant) ·
[El perfil local](#11--capa-8-el-perfil-local) · [Barrido final](#12--el-barrido-final) ·
[A las 48 horas](#13--la-comprobación-a-las-48-horas) · [Checklist](#-checklist-de-salida) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Por qué en capas

La tesis de la serie práctica está en [`L00` §1](l00-idea-lab-practico.md#1--las-dos-restricciones-de-partida):
el laboratorio no se mide por lo que despliegas, sino por lo que destruyes con certeza. Y `az group
delete` no basta, por las cinco razones de [`L00` §7.3](l00-idea-lab-practico.md#73-el-resource-group-es-la-unidad-de-destrucción-con-letra-pequeña).
Aplicadas a lo que la serie creó:

```text
Capa  Qué                                          Por qué no se va con el resource group
1     budget, diagnostic setting del Activity Log  viven en la SUSCRIPCIÓN
2     Deployment Stack (denyDelete)                BLOQUEA el borrado del grupo
3     Log Analytics workspace                      quedaría SOFT-DELETED 14 días
4     inv-lab-rg y todo lo demás                   —  (esta es la capa que todos conocen)
5     Key Vault                                    queda SOFT-DELETED 7 días, nombre retenido
6     NetworkWatcherRG, role assignments sueltos   Azure los creó FUERA de tu grupo
7     app registrations inv-api, inv-cli           viven en el TENANT, 30 días suspendidas
8     ~/.azure-inv-lab                             vive en TU MÁQUINA y guarda tu sesión
```

El orden importa: cada capa quita un obstáculo o una dependencia de la siguiente. Y cada capa se
**verifica** antes de pasar a la otra, porque un teardown que no se verifica es una esperanza.

---

## 2. 🧱 Arranque

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
SUB=$(az account show --query id --output tsv)
az account show --query "{name:name, id:id}" --output table
az extension add --name resource-graph --version 2.1.1
```

- La segunda línea importa más que nunca: un teardown en la suscripción equivocada es el peor error de
  la serie. Confirma el nombre y el id antes de borrar nada.
- `resource-graph` hace falta para el barrido final de la sección 12 ([`A01` §8](a01-az-de-supervivencia.md#8--filtrar-en-el-servidor-tags-tipos-y-resource-graph)).

```text
[PENDIENTE DE CORRIDA] Una fila con el nombre y el id de la suscripción del lab.
```

---

## 3. 💰 Atribuir el gasto por tag

Antes de borrar, se mide: después no queda a qué preguntar. La consulta va a la API de Cost Management
con `az rest`, agrupando el costo del mes **por el tag `project`** y **por resource group**:

```bash
az rest --method post \
  --url "https://management.azure.com/subscriptions/$SUB/providers/Microsoft.CostManagement/query?api-version=2026-06-01" \
  --body '{
    "type": "ActualCost",
    "timeframe": "MonthToDate",
    "dataset": {
      "granularity": "None",
      "aggregation": { "totalCost": { "name": "Cost", "function": "Sum" } },
      "grouping": [
        { "type": "TagKey", "name": "project" },
        { "type": "Dimension", "name": "ResourceGroupName" }
      ]
    }
  }' --query "properties.rows" --output table
```

- La URL pone el **scope** en la suscripción; la misma consulta vale para un resource group o un
  management group cambiando el prefijo.
- `"type": "ActualCost"` es el costo facturado tal cual; `AmortizedCost` repartiría compras por
  adelantado, como reservas, que el lab no tiene.
- `"timeframe": "MonthToDate"` es el mes en curso hasta hoy.
- `"grouping"` agrupa por el valor del **tag** `project` (`"type": "TagKey"`) y por la dimensión
  `ResourceGroupName`. Lo que no lleva tag sale con el valor de tag vacío: esa fila es exactamente lo
  que se escapó del etiquetado.
- `--query "properties.rows"` se queda con las filas: costo, valor del tag, resource group y moneda.

```text
[PENDIENTE DE CORRIDA] Filas con el costo del mes: la mayor parte en project=inv-lab / inv-lab-rg
(registry y Service Bus), y posiblemente filas sin tag (el resource group de Network Watcher, que no
cobra). Los importes dependen de los días que hayan existido registry y namespace.
```

Tres lecturas que se preguntan en una entrevista:

- **Los datos de costo llegan con retraso**: de 8 a 24 horas. Lo de hoy todavía no está, y por eso la
  comprobación final es a las 48 horas (sección 13).
- **El tag solo cuenta desde que existe**: el costo de un recurso etiquetado tarde no se reasigna hacia
  atrás ([`L01` §8](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md#8--cost-management-dónde-se-mira-el-gasto)).
- **La fila sin tag es la importante**: lo que no etiquetaste es lo que no sabías que existía.

Compara el total con el presupuesto de [`L00` §6](l00-idea-lab-practico.md#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas):
menos de un dólar si hiciste la serie seguida; más, si el registry y Service Bus vivieron días entre
labs. Esa diferencia es la lección de costo más cara, y la más barata de aprender en un lab.

---

## 4. 🧱 Capa 1: lo que vive en la suscripción

El **budget** de [`L01` §7](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md#7--el-budget-y-lo-que-de-verdad-hace)
referencia el action group de `inv-lab-rg`: se borra antes que el grupo. Y el **diagnostic setting del
Activity Log** de [`L08` §3](l08-observabilidad-kql-y-auditoria.md#3--el-activity-log-al-workspace) apunta
al workspace que se borra en la capa 3.

```bash
az rest --method delete \
  --url "https://management.azure.com/subscriptions/$SUB/providers/Microsoft.Consumption/budgets/inv-lab-budget?api-version=2024-08-01"
az monitor diagnostic-settings subscription delete --name inv-lab-activity --yes
```

- El budget se borra con la misma API con la que se creó, con `--method delete`.
- `subscription delete --yes` borra el diagnostic setting del scope de la suscripción sin confirmación.

Verificación:

```bash
az rest --method get \
  --url "https://management.azure.com/subscriptions/$SUB/providers/Microsoft.Consumption/budgets?api-version=2024-08-01" \
  --query "value[].name"
az monitor diagnostic-settings subscription list --query "value[].name"
```

```text
[PENDIENTE DE CORRIDA] [] y [].
```

---

## 5. 🧱 Capa 2: el Deployment Stack

Primero, el fallo que el stack de [`L03` §9](l03-bicep-desde-la-cli.md#9--el-deployment-stack-y-su-deny-assignment)
promete. Intenta borrar el grupo con el stack vivo:

```bash
az group delete --name inv-lab-rg --yes
```

```text
[PENDIENTE DE CORRIDA] El borrado falla: el deny assignment del stack impide borrar sus recursos, y
el mensaje nombra el deny assignment. Parte de los recursos no gestionados por el stack pueden haberse
borrado antes del fallo; el grupo sigue existiendo.
```

> ⚠️ **Un `az group delete` que falla no es inocuo.** ARM borra en paralelo lo que puede y se detiene en
> lo que no: puedes acabar con medio grupo borrado. Por eso, en la vida real, el stack se borra **antes**,
> y este paso solo se provoca en un lab que de todos modos vas a destruir.

La corrección es borrar a través del stack, que es el único que puede:

```bash
az stack group delete --name inv-lab-stack --resource-group inv-lab-rg \
  --action-on-unmanage deleteResources --yes
```

- `--action-on-unmanage deleteResources` borra los recursos que gestiona el stack —las identidades, la
  storage account y su contenedor, el vault, los role assignments y el action group— y con ellos el deny
  assignment. `detachAll` los dejaría vivos y sin protección.

Verificación: el stack ya no existe, y el vault que gestionaba **no desapareció**, quedó soft-deleted:

```bash
az stack group list --resource-group inv-lab-rg --output table
az keyvault list-deleted --query "[].{name:name, scheduledPurge:properties.scheduledPurgeDate}" --output table
```

```text
[PENDIENTE DE CORRIDA] Ningún stack; inv-lab-kv-472913 en la lista de soft-deleted, con su fecha de
purga automática a 7 días.
```

Si no hiciste [`L03`](l03-bicep-desde-la-cli.md), no hay stack: salta a la capa 3.

---

## 6. 🧱 Capa 3: el workspace, sin soft-delete

Un Log Analytics workspace borrado queda **14 días en soft-delete**, con su nombre reservado, salvo que se
borre con `--force` ([`L00` §7.3](l00-idea-lab-practico.md#73-el-resource-group-es-la-unidad-de-destrucción-con-letra-pequeña)).
Borrarlo con el grupo lo dejaría soft-deleted; por eso se borra antes, a propósito:

```bash
az monitor log-analytics workspace delete --workspace-name inv-lab-law --resource-group inv-lab-rg \
  --force true --yes
az monitor log-analytics workspace list-deleted-workspaces --query "[].name" --output tsv
```

- `--force true` borra de forma **permanente**, sin pasar por soft-delete: el nombre queda libre y los
  datos no se pueden recuperar.
- `list-deleted-workspaces` lista los workspaces soft-deleted de la suscripción.

```text
[PENDIENTE DE CORRIDA] La lista de soft-deleted, vacía.
```

> 🩺 **Si se te coló al soft-delete**, la [documentación](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/delete-workspace)
> pide recuperarlo primero (`az monitor log-analytics workspace recover`) y borrarlo después con
> `--force`: un workspace soft-deleted no se purga directamente.

---

## 7. 🧱 Capa 4: el resource group

Ahora sí, el borrado que todos conocen. Sin stack y sin workspace, no queda nada que lo bloquee:

```bash
az group delete --name inv-lab-rg --yes --no-wait
az group wait --name inv-lab-rg --deleted --timeout 3600
az group exists --name inv-lab-rg
```

- `--no-wait` devuelve el control al aceptar la petición; `az group wait --deleted` espera a que termine
  ([`A01` §9](a01-az-de-supervivencia.md#9--operaciones-de-larga-duración---no-wait-y-wait)). El
  borrado de un environment de Container Apps y de una cuenta de Cosmos DB tarda varios minutos.
- `az group exists` confirma el resultado sin error si el grupo ya no está.

```text
[PENDIENTE DE CORRIDA] false
```

Lo que se fue con el grupo, por si alguna vez tienes que explicarlo: la VNet y el NSG, el registry y sus
imágenes, el environment con `inv-api` e `inv-projector` y sus revisiones, la cuenta de Cosmos DB, el
namespace de Service Bus, Application Insights, la alerta de la DLQ, y cada diagnostic setting y role
assignment cuyo scope estaba dentro del grupo.

Comprueba también el grupo de los drills:

```bash
az group exists --name inv-drill-rg
```

```text
[PENDIENTE DE CORRIDA] false. Si es true, un drill se quedó encendido: bórralo igual.
```

---

## 8. 🧱 Capa 5: lo soft-deleted

El vault quedó soft-deleted en la capa 2. Antes de purgarlo, el fallo que provoca: intenta crear otro con
el mismo nombre, en un grupo de drill temporal (no cobra):

```bash
az group create --name inv-drill-rg --location eastus2 --tags project=inv-lab env=lab --output none
az keyvault create --name inv-lab-kv-472913 --resource-group inv-drill-rg --location eastus2
```

```text
[PENDIENTE DE CORRIDA] Un error de conflicto: existe un vault soft-deleted con ese nombre y hay que
recuperarlo o purgarlo antes de reutilizarlo.
```

El nombre está **retenido** mientras dure la retención. La corrección es purgarlo:

```bash
az keyvault purge --name inv-lab-kv-472913 --location eastus2
az keyvault list-deleted --output table
```

- `az keyvault purge` borra el vault de forma permanente y libera el nombre. Necesita la región, porque
  un vault soft-deleted ya no está en ningún resource group.
- Si el vault tuviera **purge protection**, este comando fallaría y no habría salida: esperar la
  retención entera. Por eso el lab nunca la activó.

```text
[PENDIENTE DE CORRIDA] La lista de vaults soft-deleted, vacía.
```

Borra el grupo de drill (`az group delete --name inv-drill-rg --yes`). La storage account también se
puede recuperar durante 14 días, pero **no retiene el nombre** y no cobra: no hay nada que purgar.

---

## 9. 🧱 Capa 6: lo que Azure creó fuera de tu grupo

**`NetworkWatcherRG`.** Azure lo creó en [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md#2--la-vnet-y-una-subnet-privada)
al crear la primera VNet de la región. No cobra, pero no es tuyo y sigue ahí. Antes de borrarlo,
comprueba que **ninguna otra VNet** de la suscripción lo necesita:

```bash
az network vnet list --query "length(@)"
az resource list --resource-group NetworkWatcherRG --query "[].{name:name, location:location}" --output table
```

```text
[PENDIENTE DE CORRIDA] 0 VNets en la suscripción, y en NetworkWatcherRG un único recurso,
NetworkWatcher_eastus2.
```

Si no hay otras VNets, bórralo; si las hay, **déjalo**: es de otras cargas y se volvería a crear.

```bash
az group delete --name NetworkWatcherRG --yes
```

**Role assignments sueltos.** Los que tenían scope dentro de `inv-lab-rg` se fueron con él. Los que
quedarían son los de un scope superior (la suscripción) o los de un principal borrado:

```bash
az role assignment list --all \
  --query "[?principalType=='Unknown' || principalName==''].{scope:scope, role:roleDefinitionName, principalId:principalId}" \
  --output table
```

- Un role assignment cuyo principal se borró aparece sin nombre y con tipo desconocido: el *Identity not
  found* del portal. No da acceso a nadie, pero cuenta para el límite de 5.000 por suscripción y ensucia
  cualquier auditoría.

```text
[PENDIENTE DE CORRIDA] Vacío. Si aparece alguno con scope de la suscripción, bórralo con
az role assignment delete --ids <id>.
```

---

## 10. 🧱 Capa 7: lo que vive en el tenant

Las app registrations de [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) no están en ninguna
suscripción. Se borran con `az ad`, y **quedan 30 días suspendidas** en los objetos eliminados del tenant:

```bash
for name in inv-api inv-cli; do
  id=$(az ad app list --display-name "$name" --query "[0].id" --output tsv)
  [ -n "$id" ] && az ad app delete --id "$id" && echo "borrada $name ($id)"
done
```

- `az ad app list --display-name` busca por nombre; `[0].id` toma el **object ID** de la app
  registration. Si no existe, la variable queda vacía y no se borra nada.
- Borrar la app registration borra su service principal, sus consentimientos y las asignaciones de sus
  app roles, incluida la de `inv-projector-id`.

Y el borrado permanente, para no dejar nombres suspendidos:

```bash
az rest --method get \
  --url "https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.application" \
  --query "value[?starts_with(displayName, 'inv-')].{name:displayName, id:id, deleted:deletedDateTime}" --output table

for id in $(az rest --method get \
    --url "https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.application" \
    --query "value[?starts_with(displayName, 'inv-')].id" --output tsv); do
  az rest --method delete --url "https://graph.microsoft.com/v1.0/directory/deletedItems/$id"
done
```

- `/directory/deletedItems/microsoft.graph.application` lista las aplicaciones borradas del tenant, las
  que siguen recuperables.
- `DELETE /directory/deletedItems/{id}` las borra de forma **permanente**: ni tú ni el soporte de
  Microsoft pueden recuperarlas después.

```text
[PENDIENTE DE CORRIDA] Primero, inv-api e inv-cli con su fecha de borrado; después del bucle, la
misma consulta vacía.
```

---

## 11. 🧱 Capa 8: el perfil local

El directorio `~/.azure-inv-lab` guarda los refresh tokens de tu sesión ([`A01` §3](a01-az-de-supervivencia.md#3--el-perfil-aislado-azure_config_dir)).
Cierra la sesión, y después borra el directorio desde el Finder o con el comando que prefieras, sabiendo
exactamente qué borras:

```bash
az logout
ls -la "$HOME/.azure-inv-lab"
unset AZURE_CONFIG_DIR
```

- `az logout` elimina la cuenta de la caché de tokens del perfil.
- `ls` muestra lo que queda: configuración, logs y la caché. Es local y no cobra, pero no hay razón para
  conservar una sesión de una suscripción que ya no usas.
- `unset` devuelve esta terminal a tu perfil de trabajo.

También puedes quitar las extensiones de la serie (`containerapp`, `application-insights`,
`resource-graph`) con `az extension remove --name`, y los proyectos locales de `~/inv-lab`, que son tu
entregable: el Bicep, los scripts y el código.

---

## 12. 🧪 El barrido final

La misma verificación que usa el curso para cerrar cada tanda de labs: todo tiene que salir vacío
salvo lo que la suscripción tuviera antes de la serie.

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab" && az login --output none
az resource list --tag project=inv-lab --output table
az group list --query "[].name" --output tsv
az keyvault list-deleted --output table
az monitor log-analytics workspace list-deleted-workspaces --output table
az ad app list --filter "startswith(displayName,'inv-')" --query "[].displayName" --output tsv
az graph query --graph-query "Resources | where tags.project == 'inv-lab' | project name, type, resourceGroup" --output table
```

- Vuelve a iniciar sesión solo para verificar: la sesión de la capa 8 se cerró.
- `az resource list --tag` busca lo etiquetado en toda la suscripción; `az group list` muestra los grupos
  que quedan, etiquetados o no; `az graph query` repite la búsqueda en Resource Graph, que consulta el
  inventario de todas tus suscripciones.
- `az ad app list --filter "startswith(displayName,'inv-')"` busca en el tenant.

```text
[PENDIENTE DE CORRIDA] Todo vacío. En az group list, ningún grupo del lab (ni inv-lab-rg, ni
inv-drill-rg, ni NetworkWatcherRG si lo borraste); solo lo que tuviera la suscripción antes de la serie.
```

Cierra la sesión otra vez con `az logout`.

---

## 13. 💰 La comprobación a las 48 horas

Cost Management tarda de 8 a 24 horas en recibir los datos de costo, así que el día del teardown todavía
verás cargos de ese mismo día. Pasadas **48 horas**, repite la consulta de la sección 3 cambiando el
`timeframe` por `"Custom"` con un `timePeriod` que cubra solo el día siguiente al teardown:

```bash
az rest --method post \
  --url "https://management.azure.com/subscriptions/$SUB/providers/Microsoft.CostManagement/query?api-version=2026-06-01" \
  --body "{
    \"type\": \"ActualCost\", \"timeframe\": \"Custom\",
    \"timePeriod\": { \"from\": \"$(date -u -v-1d +%Y-%m-%d)T00:00:00Z\", \"to\": \"$(date -u -v-1d +%Y-%m-%d)T23:59:59Z\" },
    \"dataset\": { \"granularity\": \"None\", \"aggregation\": { \"totalCost\": { \"name\": \"Cost\", \"function\": \"Sum\" } } }
  }" --query "properties.rows"
```

- `"timeframe": "Custom"` con `timePeriod` acota la consulta a un intervalo. `date -u -v-1d` es la
  sintaxis de macOS para "ayer"; en Linux es `date -u -d yesterday`.

```text
[PENDIENTE DE CORRIDA] Un costo de 0 (o una fila vacía) para el día completo posterior al teardown.
```

Si sale algo, la fila sin tag de la sección 3 y `az group list` dicen dónde mirar, y
[`A02`](a02-costos-trampas-y-recursos-huerfanos.md) tiene el catálogo de sospechosos.

---

## 📋 Checklist de salida

- [ ] Guardaste la atribución del gasto por tag y resource group antes de borrar.
- [ ] El budget y el diagnostic setting `inv-lab-activity` ya no existen.
- [ ] Viste `az group delete` fallar por el deny assignment del stack antes de borrar el stack.
- [ ] `az monitor log-analytics workspace list-deleted-workspaces` está vacío.
- [ ] `az group exists` devuelve `false` para `inv-lab-rg` e `inv-drill-rg`.
- [ ] Viste el nombre del vault retenido y `az keyvault list-deleted` está vacío tras el purge.
- [ ] Decidiste qué hacer con `NetworkWatcherRG` comprobando antes si había otras VNets.
- [ ] Ningún role assignment huérfano en la suscripción.
- [ ] `inv-api` e `inv-cli` no aparecen ni en las app registrations ni en los objetos eliminados.
- [ ] A las 48 horas, el costo del día posterior al teardown es cero.

## 🏁 La señal de que quedó bien

`az resource list --tag project=inv-lab` devuelve `[]`, `az keyvault list-deleted` no muestra
`inv-lab-kv-472913`, ninguna app registration `inv-*` existe ni está suspendida, y Cost Management
confirma $0.00 a las 48 horas.

---

## 🧠 Preguntas rápidas

1. ¿Por qué se atribuye el gasto antes del teardown y no después?
2. ¿Qué te dice la fila sin tag en una consulta de Cost Management agrupada por `project`?
3. ¿Por qué el budget se borra antes que el resource group?
4. ¿Qué pasa si ejecutas `az group delete` con el Deployment Stack vivo, y por qué no es inocuo?
5. ¿Qué hace `az stack group delete --action-on-unmanage deleteResources` con el Key Vault que gestiona?
6. ¿Por qué el workspace se borra antes que el grupo y con `--force`?
7. Intentas recrear el vault con el mismo nombre y falla. ¿Por qué, y qué habría pasado con purge protection?
8. ¿Por qué `NetworkWatcherRG` no se borra siempre, y qué compruebas antes?
9. ¿Qué es un role assignment huérfano y por qué conviene borrarlo aunque no dé acceso a nadie?
10. ¿Qué queda en el tenant después de `az ad app delete` y cómo lo eliminas del todo?
11. ¿Por qué el perfil local es parte del teardown?
12. ¿Por qué la comprobación de costo se hace a las 48 horas y sobre qué intervalo?

---

## 📚 Referencias oficiales

- API de consultas de Cost Management: https://learn.microsoft.com/en-us/rest/api/cost-management/query/usage
- Cost analysis por tags: https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/understand-cost-mgt-data
- Crear y administrar budgets: https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets
- Borrar un resource group y sus recursos: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/delete-resource-group
- Deployment Stacks (borrado y deny settings): https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks
- Borrar y recuperar un Log Analytics workspace: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/delete-workspace
- Soft-delete de Key Vault y purge: https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview
- Recuperar una storage account borrada: https://learn.microsoft.com/en-us/azure/storage/common/storage-account-recover
- Network Watcher y `NetworkWatcherRG`: https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-create
- Troubleshooting de Azure RBAC (principals no encontrados): https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting
- Restaurar o eliminar una app registration borrada: https://learn.microsoft.com/en-us/entra/identity-platform/howto-restore-app
- Graph: listar objetos eliminados: https://learn.microsoft.com/en-us/graph/api/directory-deleteditems-list
- Graph: eliminar un objeto de forma permanente: https://learn.microsoft.com/en-us/graph/api/directory-deleteditems-delete
- Referencia de `az monitor diagnostic-settings subscription`: https://learn.microsoft.com/en-us/cli/azure/monitor/diagnostic-settings/subscription
