# L03 — Bicep desde la CLI

> **Objetivo:** reescribir en Bicep lo que [`L02`](l02-entra-id-rbac-y-managed-identities.md) creó a mano, con versiones de API fijas, y usarlo
> para ver las cinco cosas que solo se entienden rompiéndolas: un `what-if` que no dice lo que
> esperabas, el `RoleAssignmentExists` de un role assignment sin nombre determinista, un drift
> provocado y revertido, un modo complete que borra lo que no sabías que existía, un lock que bloquea
> `az group delete`, una Azure Policy que rechaza un recurso sin tags, y un Deployment Stack cuyos
> deny settings crean el deny assignment que tú no puedes crear.
> **Se asume leído:** [`15`](15-bicep-iac.md) (Bicep, `what-if`, modos y Deployment Stacks) y
> [`10` §8–§12](10-autorizacion-rbac-policy-y-gobierno.md#8--deny-assignments) (deny assignments,
> Policy y locks).
> **Costo:** **$0.00**. Un despliegue, un stack, un lock y una policy assignment no cobran; los
> recursos son los de [`L02`](l02-entra-id-rbac-y-managed-identities.md).
> **Duración:** 2–3 horas.
> **Prerrequisitos:** [`L02`](l02-entra-id-rbac-y-managed-identities.md) terminado: la storage
> account, las dos identidades, el vault con su secreto y los role assignments.
> **Qué queda encendido al terminar:** lo mismo que dejó [`L02`](l02-entra-id-rbac-y-managed-identities.md) más el action group de [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md), ahora
> gestionado por el Deployment Stack `inv-lab-stack` con `denyDelete`. **No** quedan el lock, la
> policy ni `inv-drill-rg`.
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026. Bicep **0.47.16**.

**Salto rápido:** [Qué cambia](#1--qué-cambia-de-comandos-a-estado-deseado) ·
[Bicep fijo](#2--arranque-y-bicep-con-versión-fija) · [El archivo](#3--el-archivo-mainbicep) ·
[Compilar](#4--compilar-y-leer-lo-que-recibe-arm) ·
[What-if y RoleAssignmentExists](#5--what-if-contra-lo-que-ya-existe-y-roleassignmentexists) ·
[Drift](#6--drift-provocado-desde-az) · [Modo complete](#7--el-modo-complete-y-lo-que-no-sabías-que-existía) ·
[Lock](#8--un-lock-que-bloquea-az-group-delete) · [Deployment Stack](#9--el-deployment-stack-y-su-deny-assignment) ·
[Policy](#10--una-azure-policy-que-rechaza-lo-que-no-lleva-tags) ·
[Teardown](#11--teardown-y-lo-que-queda-encendido) · [Checklist](#-checklist-de-salida) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Qué cambia: de comandos a estado deseado

En [`L02`](l02-entra-id-rbac-y-managed-identities.md) cada recurso nació de un comando, y el orden importaba: la identidad antes que su role
assignment, la cuenta antes que su contenedor. Si mañana quieres el mismo entorno en otra suscripción,
tienes que repetir la secuencia y acertar cada flag.

Bicep invierte la pregunta: en vez de **qué comandos corro**, **cómo tiene que quedar**. Y aquí está
la propiedad de Azure que [`15` §1](15-bicep-iac.md#1--el-problema-y-la-idea-el-estado-es-arm) pone
en el centro:

> Regla importante: en Bicep no hay archivo de estado. El estado es Azure Resource Manager mismo, y
> cada despliegue compara lo que declaras con lo que existe de verdad.

Eso tiene dos consecuencias que este lab provoca a propósito: **ARM no recuerda qué creaste tú**
(y por eso quitar algo del código no lo borra), y **lo que existe manda** (y por eso un role
assignment creado a mano choca con el que declaras).

Y un recordatorio de la doctrina de reparto: Bicep se practica en la nube porque **lo único que
enseña es la conversación con ARM** —`what-if`, modos, deny assignments, policies—, y nada de eso
existe en local.

---

## 2. 🧱 Arranque, y Bicep con versión fija

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
SUB=$(az account show --query id --output tsv)
az bicep install --version v0.47.16
az bicep version
```

- `az bicep install` descarga el compilador de Bicep que usa la CLI, dentro del perfil. `--version
  v0.47.16` lo fija: la misma plantilla puede compilar distinto con otra versión, y el curso no deja
  nada a `latest`.
- `az bicep version` confirma cuál quedó.

```text
[PENDIENTE DE CORRIDA] "Bicep CLI version 0.47.16" y el hash de la compilación.
```

Crea una carpeta de trabajo **fuera del repositorio del curso** para los archivos del lab:

```bash
mkdir -p ~/inv-lab/infra && cd ~/inv-lab/infra
```

---

## 3. 🧱 El archivo `main.bicep`

El archivo describe lo que dejó [`L02`](l02-entra-id-rbac-y-managed-identities.md): las dos identidades, la cuenta con su contenedor, el vault y
los dos roles de datos de `inv-api-id`. **No** declara tus propios role assignments de usuario: son
permisos de una persona para operar el lab, no infraestructura, y no deben vivir en la plantilla.

```bicep
// main.bicep — el núcleo de identidad y datos del laboratorio (L02, ahora declarado)
@description('Región de todos los recursos')
param location string = resourceGroup().location

@description('Nombre global de la storage account (3-24 minúsculas y dígitos)')
@minLength(3)
@maxLength(24)
param storageName string

@description('Nombre global del Key Vault (3-24 caracteres)')
@minLength(3)
@maxLength(24)
param vaultName string

var tags = {
  project: 'inv-lab'
  env: 'lab'
}
// GUIDs de los roles integrados: se usan los ID porque no cambian si Microsoft renombra el rol
var blobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
var secretsUser = '4633458b-17de-408a-b874-0445c86b69e6'         // Key Vault Secrets User

resource apiIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'inv-api-id'
  location: location
  tags: tags
}

resource projectorIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'inv-projector-id'
  location: location
  tags: tags
}

resource storage 'Microsoft.Storage/storageAccounts@2026-06-01' = {
  name: storageName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowSharedKeyAccess: false   // solo Entra ID: ninguna access key sirve
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource archive 'Microsoft.Storage/storageAccounts/blobServices/containers@2026-06-01' = {
  name: '${storage.name}/default/events-archive'
  properties: {
    publicAccess: 'None'
  }
}

resource vault 'Microsoft.KeyVault/vaults@2026-02-01' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true   // el data plane se autoriza con Azure RBAC
    enableSoftDelete: true
    softDeleteRetentionInDays: 7    // igual que al crearlo: no se puede cambiar
    accessPolicies: []              // obligatorio en la plantilla aunque no se usen
  }
}

resource apiBlobAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, apiIdentity.id, blobDataContributor)
  scope: storage
  properties: {
    principalId: apiIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobDataContributor)
  }
}

resource apiSecretsAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, apiIdentity.id, secretsUser)
  scope: vault
  properties: {
    principalId: apiIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', secretsUser)
  }
}

output apiClientId string = apiIdentity.properties.clientId
output vaultUri string = vault.properties.vaultUri
```

Lo que es nuevo respecto de [`15` §3](15-bicep-iac.md#3--un-archivo-bicep-del-laboratorio), que
explica el resto línea por línea:

- **Cada `@versión` está fijada y verificada** en la referencia de plantillas a la fecha:
  `userAssignedIdentities@2023-01-31`, `storageAccounts@2026-06-01` y sus contenedores con la misma,
  `vaults@2026-02-01`, `roleAssignments@2022-04-01`.
- **El contenedor se declara con el nombre compuesto** `cuenta/default/events-archive`: es un
  subrecurso, y su resource ID es el que usaste como scope en [`L02`](l02-entra-id-rbac-y-managed-identities.md). El contenedor `scratch` no está:
  la sección 7 explica qué le pasa.
- **El vault declara `tenantId`, `sku` y `accessPolicies: []`**, que la plantilla exige aunque la
  autorización sea por RBAC. `softDeleteRetentionInDays` tiene que coincidir con el valor que se fijó
  al crear el vault; `enablePurgeProtection` no se declara, porque activarlo es irreversible.
- **El secreto `partner-api-key` no está en la plantilla.** Un valor secreto no se escribe en un
  archivo versionado; lo crea el operador o un pipeline desde un origen seguro.
- **Los nombres de los role assignments son deterministas** con `guid(scope, identidad, rol)`. Esta es
  la línea que la sección 5 pone a prueba.

Y los parámetros del lab, en su archivo:

```bicep
// main.bicepparam — valores del laboratorio
using './main.bicep'

param storageName = 'invlab472913'
param vaultName = 'inv-lab-kv-472913'
```

- Si en [`L02`](l02-entra-id-rbac-y-managed-identities.md) tuviste que cambiar el sufijo de la storage account o del vault, cámbialo aquí.

---

## 4. 🧱 Compilar, y leer lo que recibe ARM

ARM no sabe que existe Bicep: recibe una plantilla JSON. Míralo una vez:

```bash
az bicep build --file main.bicep --stdout | python3 -c "import sys,json; t=json.load(sys.stdin); print([r['type'] + '@' + r['apiVersion'] for r in (t['resources'].values() if isinstance(t['resources'], dict) else t['resources'])])"
```

- `az bicep build --file main.bicep --stdout` compila y escribe el ARM JSON en la salida estándar sin
  crear `main.json`.
- El `python3` extrae el tipo y la versión de API de cada recurso. Según las funciones que use el
  archivo, Bicep emite `resources` como lista o como objeto con nombres simbólicos; el script admite
  los dos.

```text
[PENDIENTE DE CORRIDA] Una lista con los seis recursos: dos userAssignedIdentities@2023-01-31, la
storageAccounts@2026-06-01, el contenedor, el vault@2026-02-01 y dos roleAssignments@2022-04-01.
```

Un error de sintaxis o de tipo sale **aquí**, en tu máquina, sin llamar a Azure: esa es la primera
ventaja de Bicep frente a escribir JSON a mano.

---

## 5. 🩺 What-if contra lo que ya existe, y `RoleAssignmentExists`

```bash
az deployment group what-if \
  --resource-group inv-lab-rg \
  --template-file main.bicep \
  --parameters main.bicepparam
```

- `what-if` compila, envía la plantilla a ARM y devuelve, recurso por recurso, qué haría el
  despliegue: **Create**, **Modify**, **Delete**, **NoChange** o **Ignore**. No cambia nada.

```text
[PENDIENTE DE CORRIDA] Las dos identidades, la cuenta, el contenedor y el vault en NoChange o
Modify (con las propiedades que la CLI puso en L02 y el Bicep no declara, si ARM las considera
cambio), y los dos roleAssignments en Create. Ningún Delete.
```

Léelo con calma, porque tiene dos lecciones:

- **Los recursos creados a mano aparecen como existentes.** ARM no distingue quién los creó: si el
  resource ID coincide, la plantilla los "adopta". Si ves **Modify**, lee qué propiedad cambia antes
  de seguir: puede ser ruido (una propiedad que la CLI rellenó y el Bicep omite) o un cambio real que
  no querías.
- **Los role assignments aparecen como Create aunque ya existen.** El nombre de un role assignment es
  un GUID, y los de [`L02`](l02-entra-id-rbac-y-managed-identities.md) los generó la CLI al azar. Para ARM, el recurso
  `guid(storage.id, apiIdentity.id, blobDataContributor)` no existe. What-if no sabe que hay otro con
  el mismo principal, el mismo rol y el mismo scope.

Despliega y mira qué pasa:

```bash
az deployment group create \
  --name l03-core \
  --resource-group inv-lab-rg \
  --template-file main.bicep \
  --parameters main.bicepparam
```

- `--name l03-core` nombra el despliegue en el historial del resource group. Sin nombre, la CLI usa
  el del archivo (`main`) y cada despliegue sobrescribe la entrada anterior del historial.
- El modo por defecto es **incremental**: crea o actualiza lo declarado y no toca lo demás.

```text
[PENDIENTE DE CORRIDA] El despliegue falla en los dos roleAssignments con Conflict:
RoleAssignmentExists; el resto de recursos queda en Succeeded.
```

Es el error que [`15`](15-bicep-iac.md) describe en su pregunta 3, visto de verdad: **ARM no admite dos
role assignments con el mismo principal, rol y scope**, aunque tengan nombres distintos. Hay dos
salidas, y solo una es buena:

| Opción | Qué haces | Por qué sí o no |
|---|---|---|
| Borrar los de [`L02`](l02-entra-id-rbac-y-managed-identities.md) y dejar que Bicep los cree | `az role assignment delete` de los dos | ✅ A partir de hoy, la plantilla es la única dueña de esos permisos |
| Quitar los role assignments del Bicep | Nada que desplegar | ❌ Los permisos de la app quedan fuera del código: el próximo entorno nace sin ellos |

```bash
API_PID=$(az identity show --name inv-api-id --resource-group inv-lab-rg --query principalId --output tsv)
az role assignment delete --assignee "$API_PID" --role "Storage Blob Data Contributor" \
  --scope "$(az storage account show --name invlab472913 --resource-group inv-lab-rg --query id --output tsv)"
az role assignment delete --assignee "$API_PID" --role "Key Vault Secrets User" \
  --scope "$(az keyvault show --name inv-lab-kv-472913 --query id --output tsv)"

az deployment group create --name l03-core --resource-group inv-lab-rg \
  --template-file main.bicep --parameters main.bicepparam \
  --query "{state:properties.provisioningState, outputs:properties.outputs}"
```

- Cada `delete` usa los tres filtros —principal, rol y scope— para no llevarse otra asignación.
- El segundo `create` repite el mismo despliegue; el `--query` se queda con el estado y los outputs.

```text
[PENDIENTE DE CORRIDA] state "Succeeded" y los outputs apiClientId (GUID) y vaultUri
(https://inv-lab-kv-472913.vault.azure.net/).
```

> ⚠️ Durante los segundos entre el `delete` y el `create`, `inv-api-id` no tiene permisos. En un lab
> da igual; en producción, esa migración se hace en una ventana o creando primero los nuevos
> (imposible aquí por el propio `RoleAssignmentExists`). Es la mejor razón para declarar los role
> assignments en Bicep **desde el primer día**.

Repite el `what-if`: ahora todo tiene que salir **NoChange**. Esa es la propiedad que querías: el mismo
despliegue, dos veces, no hace nada la segunda.

---

## 6. 🩺 Drift, provocado desde `az`

Drift es la diferencia entre el código y lo que existe, casi siempre por un cambio a mano
([`15` §9](15-bicep-iac.md#9--drift-sin-archivo-de-estado)). Provócalo con el cambio más peligroso
que se le puede hacer a esta cuenta:

```bash
az storage account update --name invlab472913 --resource-group inv-lab-rg \
  --allow-blob-public-access true --query allowBlobPublicAccess
```

- `az storage account update` hace un `PATCH` sobre la cuenta: cambia solo lo que le pasas.
- `--allow-blob-public-access true` **no hace público ningún contenedor**: solo permite que alguien
  lo marque como público después. Es exactamente el tipo de cambio "inofensivo" que se hace a mano un
  viernes.

```text
[PENDIENTE DE CORRIDA] true
```

Ahora pregúntale al código:

```bash
az deployment group what-if --resource-group inv-lab-rg \
  --template-file main.bicep --parameters main.bicepparam \
  --exclude-change-types NoChange Ignore
```

- `--exclude-change-types NoChange Ignore` quita del informe lo que no cambia. En un what-if diario de
  producción es lo que hace legible la salida: lo que queda **es** el drift.

```text
[PENDIENTE DE CORRIDA] Un único Modify sobre invlab472913: properties.allowBlobPublicAccess
true => false.
```

Y el despliegue lo revierte, porque la propiedad está declarada:

```bash
az deployment group create --name l03-core --resource-group inv-lab-rg \
  --template-file main.bicep --parameters main.bicepparam --output none
az storage account show --name invlab472913 --resource-group inv-lab-rg --query allowBlobPublicAccess
```

```text
[PENDIENTE DE CORRIDA] false
```

> 🧠 **Modelo mental.** Sin archivo de estado, **detectar drift es ejecutar what-if**. Si la propiedad
> está declarada, el siguiente despliegue la revierte; si no lo está, puede sobrevivir. Con un stack en
> `denyWriteAndDelete`, el cambio manual ni siquiera habría sido posible.

---

## 7. ⚖ El modo complete, y lo que no sabías que existía

En modo **complete**, ARM **borra del resource group todo lo que no esté en la plantilla**. La
[documentación](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-modes)
lo desaconseja y avisa de que se irá retirando en favor de los Deployment Stacks, pero se sigue
preguntando, y hay que haberlo visto una vez.

Crea algo que "sobra", como si otra persona lo hubiera dejado en el grupo:

```bash
az identity create --name inv-temp-id --resource-group inv-lab-rg --location eastus2 \
  --tags project=inv-lab env=lab --output none
```

Y pregunta qué haría un despliegue complete, **sin desplegar**:

```bash
az deployment group what-if --resource-group inv-lab-rg \
  --template-file main.bicep --parameters main.bicepparam \
  --mode Complete --exclude-change-types NoChange Ignore
```

- `--mode Complete` en `what-if` simula el modo complete. **Nunca se despliega en complete sin haber
  leído este informe.**

```text
[PENDIENTE DE CORRIDA] Dos Delete: inv-temp-id… e inv-lab-ag, el action group de L01.
```

El segundo es la lección. **El action group no estaba en tu plantilla** porque lo creaste con la CLI
en [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md#6--el-action-group-a-quién-avisar), y el
modo complete lo habría borrado, con lo que el budget se habría quedado sin a quién avisar. En un
resource group compartido, ese Delete sería el recurso de otro equipo.

Fíjate también en lo que **no** aparece, porque la documentación de borrado en modo complete lo
detalla por tipo: el contenedor `scratch`, el secreto `partner-api-key` y tus role assignments de
usuario no se borran, porque son subrecursos o recursos de extensión que el modo complete no elimina
por sí mismos (se van si se borra su padre).

La corrección es la de siempre: **que el código describa todo lo que vive en el grupo**. Añade el
action group al final de `main.bicep`:

```bicep
@description('Correo al que avisa el action group del lab')
param alertEmail string

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'inv-lab-ag'
  location: 'global'   // un action group es un recurso global
  tags: tags
  properties: {
    groupShortName: 'invlab'   // máximo 12 caracteres
    enabled: true
    emailReceivers: [
      {
        name: 'owner'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
  }
}
```

Y el parámetro a `main.bicepparam`:

```bicep
param alertEmail = 'tu-correo@example.com'
```

- `actionGroups@2023-01-01` es la última versión estable en la referencia de plantillas a la fecha.
- `location: 'global'` es obligatorio en el sentido práctico: el recurso es global y así lo creó la
  CLI en [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md).
- `useCommonAlertSchema: true` hace que los correos lleguen con el esquema común de alertas de Azure
  Monitor, el mismo para métricas, logs y budgets.

Repite el what-if complete: ahora solo tiene que salir **`inv-temp-id`**. Y despliega en complete una
única vez, para ver el borrado:

```bash
az deployment group create --name l03-complete --resource-group inv-lab-rg \
  --template-file main.bicep --parameters main.bicepparam --mode Complete --output none
az identity list --resource-group inv-lab-rg --query "[].name" --output tsv
```

```text
[PENDIENTE DE CORRIDA] inv-api-id e inv-projector-id: inv-temp-id ya no existe.
```

> Nunca respondas: "si lo borro del Bicep, se borra en Azure". Mejor: "en modo incremental, que es el
> recomendado, quitarlo del Bicep lo deja huérfano; el modo complete lo borraría junto con cualquier
> otra cosa que no esté en la plantilla; lo correcto es un Deployment Stack con
> `--action-on-unmanage`".

---

## 8. 🩺 Un lock que bloquea `az group delete`

Un lock `CanNotDelete` protege contra el borrado a **todos**, incluido el Owner
([`10` §12](10-autorizacion-rbac-policy-y-gobierno.md#12--resource-locks)). El lab lo prueba en un
resource group aparte, `inv-drill-rg`, por una razón que conviene enunciar:

> ⚠️ **Nunca pruebes un lock intentando borrar el grupo que quieres conservar.** Si el lock no está
> donde crees, el comando no falla: borra. Los drills de la serie viven en `inv-drill-rg` justo para
> que un error no se lleve el tronco.

```bash
az group create --name inv-drill-rg --location eastus2 --tags project=inv-lab env=lab --output none
az lock create --name inv-drill-nodelete --lock-type CanNotDelete --resource-group inv-drill-rg \
  --notes "L03: demostrar que bloquea az group delete"
az lock list --resource-group inv-drill-rg --query "[].{name:name, level:level}" --output table
```

- `az lock create` sin `--resource` aplica el lock al **resource group entero**; por herencia, a todo
  lo que contenga.
- `--notes` documenta por qué existe. Un lock sin nota es un lock que nadie se atreve a quitar.
- `az lock list` confirma que está antes de intentar nada.

```text
[PENDIENTE DE CORRIDA] Una fila: inv-drill-nodelete, CanNotDelete.
```

Ahora el borrado que tiene que fallar:

```bash
az group delete --name inv-drill-rg --yes
```

```text
[PENDIENTE DE CORRIDA] Un error de scope bloqueado (el código que suele devolver ARM es
ScopeLocked) que nombra el lock y el scope; el grupo sigue existiendo.
```

La corrección es quitar el lock, con permiso para hacerlo (Owner o User Access Administrator), y
repetir:

```bash
az lock delete --name inv-drill-nodelete --resource-group inv-drill-rg
az group delete --name inv-drill-rg --yes
az group exists --name inv-drill-rg
```

- `az group exists` responde `true` o `false` sin error si el grupo no existe.

```text
[PENDIENTE DE CORRIDA] false
```

> 📝 **Contexto.** En `inv-lab-rg` el lab **no** deja un lock, a propósito: un `CanNotDelete` en un
> resource group impide que ARM recorte el historial de despliegues, y al llegar a 800 los despliegues
> nuevos fallan. Además, en modo complete ARM no borra nada en un grupo bloqueado. Lo que protege el
> tronco es el stack de la sección siguiente.

---

## 9. 🧱 El Deployment Stack, y su deny assignment

Un **Deployment Stack** es un recurso de Azure que agrupa los recursos de un despliegue y **recuerda
cuáles gestiona** ([`15` §7](15-bicep-iac.md#7--deployment-stacks)). Resuelve lo que el modo complete
resolvía mal: borrar lo que sale del código **sin tocar lo que no es suyo**.

**Teardown antes que el despliegue.** Con `denyDelete`, **ni tú** puedes borrar a mano los recursos del
stack, y `az group delete --name inv-lab-rg` fallará mientras exista. El teardown de [`L09`](l09-costos-y-destruccion-verificada.md) empieza por
`az stack group delete --name inv-lab-stack --resource-group inv-lab-rg --action-on-unmanage
deleteResources --yes`, que borra los recursos gestionados y el deny assignment; después, el grupo y
el purge del vault.

```bash
az stack group create \
  --name inv-lab-stack \
  --resource-group inv-lab-rg \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --action-on-unmanage deleteResources \
  --deny-settings-mode denyDelete \
  --description "Nucleo de identidad y datos del laboratorio (L03)" \
  --tags project=inv-lab env=lab \
  --yes
```

- `--action-on-unmanage deleteResources`: si un recurso **sale de la plantilla** en una actualización
  futura del stack, se borra. `detachAll` lo dejaría vivo sin gestión; `deleteAll` borraría además los
  resource groups gestionados.
- `--deny-settings-mode denyDelete`: el stack crea un **deny assignment** que impide borrar sus
  recursos a cualquiera. `denyWriteAndDelete` impediría además modificarlos; `none`, nada.
- No se pasa `--deny-settings-excluded-principals`, a propósito: en un equipo real se excluye la
  identidad del pipeline (hasta cinco principals); aquí quieres ver que el deny te alcanza a ti.
- No se pasa `--deny-settings-apply-to-child-scopes`: el deny protege los recursos gestionados, no sus
  hijos. Eso deja operar sobre subrecursos, como la conexión de private endpoint que [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) crea en la
  cuenta.
- `--tags` etiqueta el propio stack, que también es un recurso.
- `--yes` confirma sin preguntar lo que el stack hará con los recursos no gestionados.

```text
[PENDIENTE DE CORRIDA] JSON del stack con provisioningState succeeded, actionOnUnmanage con
resources "delete", denySettings.mode "denyDelete" y la lista resources con los resource IDs de
las dos identidades, la cuenta, el contenedor, el vault, los dos role assignments y el action group.
```

Ahora el deny assignment que tú no puedes crear, creado por el stack. Intenta borrar una identidad
gestionada:

```bash
az identity delete --name inv-projector-id --resource-group inv-lab-rg
```

```text
[PENDIENTE DE CORRIDA] Un error de autorización de ARM que indica que la operación se deniega por
un deny assignment, con su nombre y el scope; la identidad sigue existiendo.
```

Eres Owner, y se deniega: un deny assignment **gana a cualquier role assignment**. Míralo:

```bash
az rest --method get \
  --url "https://management.azure.com/subscriptions/$SUB/resourceGroups/inv-lab-rg/providers/Microsoft.Authorization/denyAssignments?api-version=2022-04-01" \
  --query "value[].{name:properties.denyAssignmentName, scope:properties.scope, systemProtected:properties.isSystemProtected, notActions:length(properties.permissions[0].notActions)}"
```

- No hay un comando `az` de primera clase para listar deny assignments, así que se leen con `az rest`
  contra la API de `Microsoft.Authorization/denyAssignments` ([`A01` §11](a01-az-de-supervivencia.md#11--az-rest-la-api-sin-intermediarios)).
- `isSystemProtected` marca los deny assignments que crea Azure —los únicos que existen—, y
  `notActions` cuenta las acciones exentas del deny. El nombre del deny assignment dice qué stack lo
  creó.

```text
[PENDIENTE DE CORRIDA] Uno o varios deny assignments creados por el stack, con isSystemProtected
true y el scope de cada recurso gestionado.
```

> 📝 **Contexto.** El stack gestiona **el núcleo de identidad y datos** de [`L02`](l02-entra-id-rbac-y-managed-identities.md). Los recursos que
> crean [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md)–[`L08`](l08-observabilidad-kql-y-auditoria.md) —red, registry, Container Apps, Cosmos DB, Service Bus, workspace— se crean con
> `az` y **no** entran en el stack: cada uno se enseña primero con su comando, por la regla de "primero
> el mecanismo" de la guía, y el tiempo de un lab no da para escribirlo dos veces. Viven en
> `inv-lab-rg`, llevan los tags y [`L09`](l09-costos-y-destruccion-verificada.md) los destruye con el grupo, después del stack.

---

## 10. 🩺 Una Azure Policy que rechaza lo que no lleva tags

Los tags de la serie se han puesto por disciplina. Ahora se imponen, con la asignación de
[`10` §10](10-autorizacion-rbac-policy-y-gobierno.md#10--azure-policy):

```bash
RG_ID=$(az group show --name inv-lab-rg --query id --output tsv)
az policy assignment create \
  --name require-project-tag \
  --display-name "L03: exigir el tag project en inv-lab-rg" \
  --policy 871b6d14-10aa-478d-b590-94f262ecfa99 \
  --scope "$RG_ID" \
  --params '{"tagName": {"value": "project"}}'
```

- `--policy 871b6d14-10aa-478d-b590-94f262ecfa99` es la definición integrada **"Require a tag on
  resources"**, con efecto `deny`. Las integradas se identifican por GUID.
- `--scope "$RG_ID"` la limita a `inv-lab-rg`.
- `--params` rellena su único parámetro, `tagName`.

La [documentación de Policy](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data)
indica que una asignación nueva tarda **unos cinco minutos** en aplicarse. Espera, y provoca el
rechazo:

```bash
az identity create --name inv-untagged-id --resource-group inv-lab-rg --location eastus2
```

```text
[PENDIENTE DE CORRIDA] Un error RequestDisallowedByPolicy que nombra la asignación
require-project-tag y la definición que lo rechazó. Si la identidad se crea, la asignación todavía
no se aplicó: bórrala, espera unos minutos y repite.
```

Tres cosas del síntoma:

- **Eres Owner y se rechaza.** Policy no da ni quita permisos: decide cómo tienen que quedar los
  recursos, para todos ([`10` §11](10-autorizacion-rbac-policy-y-gobierno.md#11--policy-frente-a-rbac)).
- **El mensaje nombra la asignación.** Es lo que buscas cuando un despliegue de producción falla por
  una policy que no conocías.
- **El `deny` actúa en la petición**, aunque el panel de cumplimiento tarde en reflejar el estado.

Con el tag, pasa; y el recurso de prueba se borra:

```bash
az identity create --name inv-untagged-id --resource-group inv-lab-rg --location eastus2 \
  --tags project=inv-lab env=lab --output none
az identity delete --name inv-untagged-id --resource-group inv-lab-rg
```

Y la asignación se **retira** al terminar la sección:

```bash
az policy assignment delete --name require-project-tag --scope "$RG_ID"
```

> 📝 **Por qué se retira.** En una organización, esta policy viviría en el management group y nunca se
> quitaría. En el lab se retira para que [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md)–[`L08`](l08-observabilidad-kql-y-auditoria.md) no mezclen un diagnóstico de Policy con los de
> red, cómputo y mensajería: cuando algo falle allí, tiene que poder fallar por una sola causa. Los
> tags se siguen poniendo en cada comando.

---

## 11. 🧪 Teardown, y lo que queda encendido

| Recurso | ¿Cobra? | Estado al terminar | Quién lo destruye |
|---|---|---|---|
| `inv-lab-stack` y su deny assignment | No | Vivo, gestiona el núcleo | [`L09`](l09-costos-y-destruccion-verificada.md), con `az stack group delete` |
| Recursos del núcleo ([`L02`](l02-entra-id-rbac-y-managed-identities.md) + action group) | Lo mismo que en [`L02`](l02-entra-id-rbac-y-managed-identities.md) | Vivos, gestionados por el stack | [`L09`](l09-costos-y-destruccion-verificada.md), a través del stack |
| Contenedor `scratch` | No | Vivo, fuera del stack | Con la cuenta |
| Secreto `partner-api-key` | Incluido | Vivo, fuera del stack | Con el vault |
| `inv-temp-id` | No | Borrado por el modo complete | — |
| `inv-drill-rg` y su lock | No | Borrados | — |
| `require-project-tag` | No | Retirada | — |
| `~/inv-lab/infra` | Local | `main.bicep` y `main.bicepparam` | Se conserva: [`L09`](l09-costos-y-destruccion-verificada.md) los usa |

Verificación:

```bash
az stack group list --resource-group inv-lab-rg --query "[].{name:name, deny:denySettings.mode, resources:length(resources)}" --output table
az lock list --resource-group inv-lab-rg --output table
az policy assignment list --scope "$RG_ID" --query "[].name" --output tsv
az group exists --name inv-drill-rg
```

```text
[PENDIENTE DE CORRIDA] Una fila con inv-lab-stack, denyDelete y el número de recursos gestionados;
ningún lock; ninguna policy assignment; false.
```

---

## 📋 Checklist de salida

- [ ] `az bicep version` devuelve 0.47.16.
- [ ] Viste `RoleAssignmentExists` y sabes por qué el nombre de un role assignment en Bicep es `guid(...)`.
- [ ] Un `what-if` sobre el despliegue actual devuelve todo `NoChange`.
- [ ] Provocaste el drift de `allowBlobPublicAccess` y el despliegue lo revirtió a `false`.
- [ ] El what-if en modo complete te mostró el action group como Delete antes de añadirlo a la plantilla.
- [ ] Viste fallar `az group delete` sobre `inv-drill-rg` por el lock, y el grupo ya no existe.
- [ ] Viste `RequestDisallowedByPolicy` al crear un recurso sin tags, y la asignación ya no existe.
- [ ] `az identity delete --name inv-projector-id` falla por el deny assignment del stack.
- [ ] `main.bicep` y `main.bicepparam` están guardados en `~/inv-lab/infra`.

## 🏁 La señal de que quedó bien

`az stack group show --name inv-lab-stack --resource-group inv-lab-rg` muestra `denyDelete` y los
recursos del núcleo, un what-if del stack no devuelve cambios, `az lock list` y `az policy assignment
list` sobre el grupo están vacíos, y puedes explicar por qué un Owner no pudo borrar su propia
identidad.

---

## 🧠 Preguntas rápidas

1. ¿Por qué `what-if` muestra como Create unos role assignments que ya existen?
2. ¿Qué dice exactamente `RoleAssignmentExists` y por qué lo evita `guid(scope, identidad, rol)`?
3. ¿Por qué el secreto del vault y tus propios role assignments de usuario no están en `main.bicep`?
4. ¿Qué te dice `az bicep build` que no te diga `what-if`, y cuándo falla cada uno?
5. ¿Qué hace `--exclude-change-types NoChange Ignore` y por qué es la opción de un what-if diario?
6. Cambiaste `allowBlobPublicAccess` a mano. ¿Qué pasa en el siguiente despliegue y por qué?
7. ¿Qué borró el modo complete que no esperabas, y qué no borra aunque no esté en la plantilla?
8. ¿Por qué el lab prueba el lock en `inv-drill-rg` y no en `inv-lab-rg`?
9. ¿Qué efecto secundario tiene un lock `CanNotDelete` sobre el historial de despliegues?
10. ¿Qué diferencia hay entre `deleteResources`, `detachAll` y `deleteAll` en `--action-on-unmanage`?
11. ¿Por qué el Owner no puede borrar `inv-projector-id` después de crear el stack, y cómo se hace el teardown?
12. ¿Cómo listas los deny assignments de un resource group y qué te dice `isSystemProtected`?
13. ¿Cuánto tarda en aplicarse una policy assignment nueva y qué error devuelve un `deny`?
14. ¿Qué gestiona el stack y qué queda fuera de él en el resto de la serie?

---

## 📚 Referencias oficiales

- Instalar Bicep: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install
- Comandos de Bicep en la CLI (`az bicep`): https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-cli
- What-if de despliegues Bicep: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if
- Modos de despliegue: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-modes
- Borrado de recursos en modo complete, por tipo: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-complete-mode-deletion
- Role assignments en plantillas (idempotencia y `RoleAssignmentExists`): https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-template
- RBAC en Bicep: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac
- Referencia de plantillas de `Microsoft.KeyVault/vaults`: https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
- Referencia de plantillas de contenedores de blobs: https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
- Referencia de plantillas de `Microsoft.Insights/actionGroups`: https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/actiongroups
- Deployment Stacks: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks
- Referencia de `az stack group`: https://learn.microsoft.com/en-us/cli/azure/stack/group
- Deny assignments: https://learn.microsoft.com/en-us/azure/role-based-access-control/deny-assignments
- API de deny assignments (listar por resource group): https://learn.microsoft.com/en-us/rest/api/authorization/deny-assignments/list-for-resource-group
- Resource locks: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources
- Obtener datos de cumplimiento de Azure Policy: https://learn.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data
- Referencia de `az policy assignment`: https://learn.microsoft.com/en-us/cli/azure/policy/assignment
- Errores comunes de despliegue: https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/common-deployment-errors
