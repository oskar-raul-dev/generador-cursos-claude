# 15 — Bicep e Infrastructure as Code

> **Objetivo:** describir la infraestructura de Azure como código con Bicep, entender por qué en Azure
> **el estado es ARM mismo**, desplegar con `what-if` antes de cada cambio, borrar lo que sobra con
> Deployment Stacks y saber cuándo gana Terraform.
> **Se asume leído:** [`01`](01-infraestructura-global-y-resource-manager.md) (ARM, scopes y resource
> IDs) y [`10`](10-autorizacion-rbac-policy-y-gobierno.md) (role assignments, deny assignments y el
> retiro de Blueprints).
> **Se toca más con:** el [`16`](16-orquestacion-y-cicd.md) (CI/CD), que ejecuta estos despliegues desde un pipeline sin secretos.
> **Se practica en:** [`L03`](l03-bicep-desde-la-cli.md) (Bicep desde la CLI: `what-if`, un despliegue incremental, un Deployment
> Stack con deny settings, un lock y una policy). Ver [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 28 de septiembre de 2026.

**Salto rápido:** [El estado es ARM](#1--el-problema-y-la-idea-el-estado-es-arm) ·
[ARM JSON y Bicep](#2--de-arm-json-a-bicep) · [Un archivo Bicep](#3--un-archivo-bicep-del-laboratorio) ·
[Parámetros y módulos](#4--parámetros-módulos-loops-y-existing) · [Scopes](#5--scopes-de-despliegue) ·
[What-if y modos](#6--what-if-y-los-modos-de-despliegue) · [Deployment Stacks](#7--deployment-stacks) ·
[Reutilizar](#8--reutilizar-template-specs-y-azure-verified-modules) · [Drift](#9--drift-sin-archivo-de-estado) ·
[⚖ Terraform](#10--terraform-con-azurerm-cuándo-gana-cada-uno) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El problema y la idea: el estado es ARM

**El problema:** el ambiente de producción del banco se creó a mano en el portal hace dos años. Nadie
sabe exactamente qué tiene, montar un ambiente de pruebas idéntico lleva una semana y un cambio no
revisado tumbó la red el mes pasado.

Infrastructure as Code resuelve las tres cosas: la infraestructura se describe en archivos versionados,
se revisa en un pull request y se despliega igual en cada ambiente. En Azure, la herramienta nativa es
**Bicep**, y tiene una diferencia de fondo con Terraform que es la primera pregunta de cualquier
entrevista:

```text
Terraform:  código  +  archivo de state (lo que Terraform cree que existe)  →  plan  →  API
Bicep:      código  →  ARM compara con lo que EXISTE en Azure              →  despliegue
```

**Bicep no tiene archivo de estado.** Cada despliegue le entrega a ARM el estado deseado y ARM lo
compara con los recursos reales. No hay un `terraform.tfstate` que guardar, bloquear, cifrar ni
reparar cuando se corrompe; la contrapartida es que ARM solo sabe lo que hay, no lo que *tú* creaste
antes (§7 y §9).

> Nunca respondas: "Bicep guarda el estado como Terraform". Mejor: "Bicep no tiene state propio: ARM es
> la fuente de verdad y cada despliegue se compara con los recursos que existen. Por eso no hay state
> que proteger, y por eso borrar lo que sale del código exige un mecanismo aparte, los Deployment
> Stacks".

---

## 2. 🧱 De ARM JSON a Bicep

El formato nativo de ARM son las **plantillas ARM en JSON**: completas, pero verbosas, con funciones
dentro de cadenas (`"[resourceId('Microsoft.Storage/storageAccounts', parameters('name'))]"`) y
dependencias declaradas a mano. Nadie las escribe a mano hoy.

**Bicep** es un lenguaje declarativo de Microsoft que **se compila a ARM JSON**: ARM no sabe que
existe Bicep. Lo que aporta:

- sintaxis concisa, con tipos y validación en el editor;
- **dependencias implícitas**: si un recurso usa `storage.id`, Bicep sabe que va después;
- **soporte del día cero**: cualquier tipo y versión de API que ARM expone está disponible en Bicep sin
  esperar a que nadie actualice un provider;
- módulos, loops, condiciones y funciones legibles.

Se instala y se versiona con la CLI: `az bicep install` y `az bicep version`. La versión vigente a la
fecha es la **0.47.16**.

---

## 3. 🧱 Un archivo Bicep del laboratorio

Una identidad, una storage account sin claves y el rol de datos que une las dos:

```bicep
// main.bicep — identidad, storage account sin claves y rol de datos para inv-api
@description('Región de todos los recursos')
param location string = resourceGroup().location

@description('Nombre global de la storage account')
@minLength(3)
@maxLength(24)
param storageName string

var tags = {
  project: 'inv-lab'
  env: 'lab'
}
var blobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor

resource apiIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'inv-api-id'
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
    allowSharedKeyAccess: false
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
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

output storageId string = storage.id
output apiClientId string = apiIdentity.properties.clientId
```

- `param` declara entradas; los **decoradores** (`@description`, `@minLength`, `@maxLength`,
  `@allowed`, `@secure`) validan y documentan. `@secure()` evita que un valor aparezca en el historial
  de despliegues.
- `resource <nombre> '<tipo>@<versión-de-api>'` declara un recurso con una **versión de API fija**. La
  versión determina qué propiedades existen; fijarla hace el despliegue reproducible. Las de este archivo
  son las vigentes en la referencia de plantillas a la fecha.
- `allowSharedKeyAccess: false` es el `--allow-shared-key-access false` de la CLI ([`06` §8](06-almacenamiento-storage-accounts.md#8--acceso-claves-sas-y-entra-id)): el
  mismo recurso, declarado.
- `guid(storage.id, apiIdentity.id, blobDataContributor)` da al role assignment un **nombre
  determinista**: el mismo en cada despliegue. Con un nombre aleatorio, el segundo despliegue intentaría
  crear otra asignación idéntica y fallaría con `RoleAssignmentExists`.
- `scope: storage` asigna el rol sobre la storage account, no sobre el resource group.
- `principalType: 'ServicePrincipal'` evita el `PrincipalNotFound` cuando la identidad se acaba de crear
  en el mismo despliegue y aún no se replicó ([`10` §6](10-autorizacion-rbac-policy-y-gobierno.md#6--asignar-un-rol-y-diagnosticar-un-authorizationfailed)).
- `apiIdentity.properties.principalId` crea una **dependencia implícita**: Bicep ordena la identidad
  antes del role assignment sin `dependsOn`.
- `output` expone valores para el pipeline o para otros módulos.

---

## 4. 🧱 Parámetros, módulos, loops y `existing`

**Archivos de parámetros.** Los valores por ambiente van en un `.bicepparam`, que Bicep valida contra
el archivo principal:

```bicep
// main.bicepparam — valores del laboratorio
using './main.bicep'

param storageName = 'invlab472913'
```

- `using './main.bicep'` liga el archivo de parámetros a su plantilla: un parámetro que no existe o con
  el tipo equivocado es un error de compilación, no de despliegue.

**Módulos.** Un archivo Bicep puede usar otro como módulo, con sus parámetros y sus outputs:
`module network './network.bicep' = { params: { ... } }`. Es la unidad de reutilización.

**Loops y condiciones.** `[for name in names: { ... }]` crea N recursos o N propiedades;
`resource x '...' = if (deployCache) { ... }` crea un recurso solo si se cumple la condición.

**`existing`.** Referencia un recurso que ya existe **sin gestionarlo**, para usar su id o sus
propiedades:

```bicep
resource law 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = {
  name: 'inv-lab-law'
}
```

- `existing` no crea ni modifica el workspace; solo permite escribir `law.id` en otro recurso, por
  ejemplo en un diagnostic setting ([`14` §5](14-observabilidad-monitor-log-analytics-app-insights.md#5--diagnostic-settings)).

---

## 5. 🧱 Scopes de despliegue

Un despliegue apunta a un **scope** de la jerarquía del [`01` §6](01-infraestructura-global-y-resource-manager.md#6--la-jerarquía-de-scopes), y cada uno tiene su comando:

| Scope | Comando | Qué se despliega típicamente |
|---|---|---|
| Resource group | `az deployment group create` | La carga: apps, bases, redes de la carga |
| Suscripción | `az deployment sub create` | Resource groups, policies y roles de la suscripción, budgets |
| Management group | `az deployment mg create` | Policies e iniciativas de la organización |
| Tenant | `az deployment tenant create` | Management groups |

Un archivo Bicep declara su scope con `targetScope = 'subscription'` (por defecto, `resourceGroup`), y
un módulo puede desplegar en un scope distinto al de su padre: desde un despliegue de suscripción se crea
el resource group y, con un módulo, lo que va dentro.

Cada scope guarda un **historial de despliegues** de hasta **800**; al llegar, ARM borra los más
antiguos hasta dejar 600. Un lock `CanNotDelete` en el resource group impide ese borrado automático y
hace fallar los despliegues nuevos ([`10` §12](10-autorizacion-rbac-policy-y-gobierno.md#12--resource-locks)).

---

## 6. 🧱 What-if y los modos de despliegue

**What-if** es el equivalente de `terraform plan`: pregunta a ARM qué cambiaría el despliegue, sin
aplicarlo.

```bash
az deployment group what-if \
  --resource-group inv-lab-rg \
  --template-file main.bicep \
  --parameters main.bicepparam
```

- `what-if` compila el Bicep, lo envía a ARM y muestra cada recurso con su efecto: **Create**,
  **Modify** (con las propiedades que cambian), **Delete**, **NoChange** o **Ignore**.
- `--parameters main.bicepparam` usa los valores del laboratorio.
- Se ejecuta **siempre** antes de desplegar, y en un pipeline se publica su salida en el pull request.

El despliegue real cambia `what-if` por `create`. Y aquí está la trampa de los **modos**:

- **incremental** (por defecto y recomendado): ARM crea o actualiza lo que está en la plantilla y **no
  toca lo que no está**. Borrar un recurso del Bicep **no lo borra en Azure**;
- **complete**: ARM **borra** del resource group todo lo que no esté en la plantilla. Un módulo olvidado
  o un recurso creado por otro equipo en el mismo grupo desaparece. Microsoft lo desaconseja y anuncia
  que **se irá retirando** en favor de los Deployment Stacks.

> ⚠️ **En modo incremental, un recurso que se despliega entero reemplaza sus propiedades.** Si la
> plantilla declara una storage account sin una propiedad que alguien activó en el portal, el despliegue
> la devuelve a su valor por defecto. What-if lo muestra como **Modify**; por eso se lee antes de
> aplicar.

> Nunca respondas: "si lo borro del Bicep, se borra en Azure". Mejor: "en modo incremental, que es el
> recomendado, quitarlo del Bicep lo deja huérfano en Azure; el modo complete lo borraría, pero está
> desaconsejado; la forma correcta de que lo que sale del código se borre es un Deployment Stack con
> `--action-on-unmanage`".

---

## 7. 🧱 Deployment Stacks

Un **Deployment Stack** es un recurso de Azure que agrupa los recursos de un despliegue y **recuerda
cuáles gestiona**. Es lo que le faltaba a Bicep sin state:

- si un recurso **deja de estar** en la plantilla, el stack decide qué hacer con él según
  `--action-on-unmanage`: **borrarlo** o solo **desvincularlo**;
- con **deny settings**, crea un **deny assignment** sobre sus recursos —la única forma de que tú
  obtengas uno, [`10` §8](10-autorizacion-rbac-policy-y-gobierno.md#8--deny-assignments)— para que nadie los borre o modifique fuera del stack;
- sustituye a Blueprints, que se retira el 31 de enero de 2027 ([`10` §13](10-autorizacion-rbac-policy-y-gobierno.md#13--tags-landing-zones-y-el-fin-de-blueprints)).

```bash
az stack group create \
  --name inv-lab-stack \
  --resource-group inv-lab-rg \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --action-on-unmanage deleteResources \
  --deny-settings-mode denyDelete \
  --deny-settings-excluded-principals "$PIPELINE_PRINCIPAL_ID"
```

- `az stack group create` crea (o actualiza) un stack en el scope de resource group; existen `az stack
  sub` y `az stack mg` para los otros scopes.
- `--action-on-unmanage deleteResources` **borra** los recursos que salgan de la plantilla. `detachAll`
  los dejaría existir sin gestión; `deleteAll` borraría además los resource groups gestionados.
- `--deny-settings-mode denyDelete` crea un deny assignment que impide **borrar** los recursos del stack
  a cualquiera, incluido un Owner. `denyWriteAndDelete` impide además modificarlos; `none` no bloquea.
- `--deny-settings-excluded-principals` exime hasta 5 principals del deny, típicamente la identidad del
  pipeline, que es quien debe poder cambiar la infraestructura.

> ⚠️ Con `denyDelete` activo, **tú tampoco puedes borrar** a mano un recurso del stack, y `az group
> delete` falla. El teardown pasa por `az stack group delete --action-on-unmanage deleteResources`, que
> [`L03`](l03-bicep-desde-la-cli.md) y [`L09`](l09-costos-y-destruccion-verificada.md) hacen explícito.

---

## 8. 🧱 Reutilizar: Template Specs y Azure Verified Modules

- **Template Specs**: una plantilla guardada **como recurso de Azure**, versionada y con permisos de
  RBAC. Un equipo de plataforma publica "la red corporativa v3" y los demás la despliegan sin acceso al
  repositorio. Sustituyen, con los stacks, a Blueprints.
- **Azure Verified Modules** (AVM): la biblioteca oficial de módulos de Microsoft para Bicep y Terraform,
  mantenida y con los valores seguros por defecto. Se consumen desde el registro público, por ejemplo
  `br/public:avm/res/storage/storage-account:0.33.1`, siempre con **versión exacta**.
- **Registros privados**: una Azure Container Registry puede alojar módulos Bicep propios
  (`br:invlabacr472913.azurecr.io/bicep/modules/network:1.2.0`).
- **`azd`** (Azure Developer CLI) empaqueta infraestructura en Bicep, código y pipeline en plantillas de
  aplicación completas. Útil para arrancar; en un banco el pipeline suele ser propio.

| | Módulo local | Template Spec | Azure Verified Module |
|---|---|---|---|
| Dónde vive | En el repositorio | Recurso de Azure | Registro público de Microsoft |
| Versionado | El del repositorio | Versiones del recurso | Semver en el registro |
| Control de acceso | Acceso al repositorio | Azure RBAC | Público |
| Para qué | Estructura del propio proyecto | Plantillas corporativas compartidas | No reinventar recursos comunes |

---

## 9. 🧱 Drift sin archivo de estado

**Drift** es la diferencia entre el código y lo que existe, casi siempre por un cambio hecho a mano en el
portal. Sin state, se detecta **ejecutando what-if**: lo que aparece como Modify sin que nadie haya
cambiado el código es drift. En un pipeline se programa un what-if diario contra producción y se alerta
si la salida no está vacía.

Qué pasa con un cambio hecho en el portal según lo que toque:

- si cambia una **propiedad declarada** en el Bicep, el siguiente despliegue **la revierte**;
- si cambia una propiedad **no declarada**, puede sobrevivir o volver a su valor por defecto según cómo
  el resource provider trate las propiedades omitidas; what-if lo dice;
- si **crea un recurso nuevo**, el despliegue incremental **no lo ve**: queda fuera del código. Un stack
  tampoco lo gestiona, porque nunca fue suyo.

Con deny settings `denyWriteAndDelete`, el drift manual directamente no es posible: nadie salvo el
pipeline puede cambiar los recursos del stack.

---

## 10. ⚖ Terraform con `azurerm`: cuándo gana cada uno

Terraform con el provider `azurerm` es la alternativa más usada, y en muchos bancos el estándar:

```hcl
# versions.tf — versiones exactas, nunca rangos
terraform {
  required_version = "= 1.16.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.7.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

- `required_version = "= 1.16.4"` y `version = "= 5.7.0"` fijan Terraform y el provider en las versiones
  vigentes a la fecha; con `=` no se acepta ninguna otra.
- `features {}` es obligatorio en el provider `azurerm`, aunque esté vacío: agrupa comportamientos
  opcionales, como purgar un Key Vault al destruirlo.
- El **state** se guarda en un backend remoto; en Azure, un contenedor de Blob Storage con el backend
  `azurerm`, que además usa el lease del blob como **bloqueo** para que dos `apply` no pisen el mismo
  state.

| Criterio | Bicep | Terraform (`azurerm`) |
|---|---|---|
| Estado | ARM mismo; nada que guardar | Archivo de state que hay que guardar, bloquear y proteger (contiene secretos) |
| Plan | `what-if` | `terraform plan`, más maduro y más fiable |
| Borrar lo que sale del código | Deployment Stacks | Nativo: lo que sale del código se destruye |
| Nuevas APIs de Azure | Día cero | Cuando el provider las incorpora (o con el provider `azapi`) |
| Multi-cloud y SaaS | Solo Azure | AWS, GCP, Datadog, GitHub, Entra ID… con el mismo flujo |
| Ecosistema | Microsoft | Enorme; módulos, políticas (Sentinel, OPA), Terraform Cloud |
| Soporte | Microsoft, incluido en Azure | HashiCorp; licencia BSL desde 2023 (OpenTofu como bifurcación abierta) |

```text
Regla de arquitectura:
Solo Azure y un equipo que vive en Azure  → Bicep: sin state, día cero, soporte de Microsoft.
Varias nubes o mucho SaaS alrededor        → Terraform: un solo flujo para todo.
La decisión la toma el estándar de la organización, no la preferencia del equipo.
```

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Bicep tiene state como Terraform" | No tiene: ARM es la fuente de verdad |
| "El modo complete solo agrega lo que falta" | Borra del resource group todo lo que no esté en la plantilla |
| "Si lo borro del Bicep, se borra en Azure" | En incremental queda huérfano; se borra con un stack y `--action-on-unmanage` |
| "What-if es opcional" | Es el plan: sin él, un despliegue incremental puede revertir propiedades sin avisar |
| "El role assignment puede llamarse como sea" | Necesita un `guid()` determinista o falla al redesplegar |
| "Con `denyDelete` puedo borrar el resource group igual" | El deny assignment lo impide; se borra con `az stack group delete` |
| "El drift no existe sin state" | Existe; se detecta con what-if |
| "Uso el último AVM" | Versión exacta del módulo, como cualquier dependencia |

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia de fondo hay entre Bicep y Terraform respecto del estado?
2. ¿Qué relación hay entre Bicep y las plantillas ARM JSON?
3. ¿Por qué un role assignment en Bicep se nombra con `guid(...)` y qué pasa si no?
4. ¿Para qué sirven `principalType` en un role assignment y `existing` en un recurso?
5. ¿Qué aporta un archivo `.bicepparam` frente a pasar los parámetros sueltos?
6. ¿Qué se despliega en cada scope (resource group, suscripción, management group, tenant)?
7. ¿Qué te dice `what-if` y por qué se ejecuta antes de cada despliegue?
8. ¿Qué diferencia hay entre los modos incremental y complete, y por qué el complete es peligroso?
9. Quitaste un recurso del Bicep y sigue existiendo en Azure. ¿Por qué y cómo haces que se borre?
10. ¿Qué es un Deployment Stack y qué hacen `--action-on-unmanage` y `--deny-settings-mode`?
11. Con un stack en `denyDelete`, `az group delete` falla. ¿Por qué y cómo haces el teardown?
12. ¿Qué diferencia hay entre un módulo local, una Template Spec y un Azure Verified Module?
13. ¿Cómo detectas drift sin archivo de estado y qué pasa con un cambio hecho en el portal?
14. ¿Qué problemas tiene el state de Terraform y cómo se gestiona en Azure?
15. ¿Cuándo elegirías Terraform en lugar de Bicep para una organización que usa Azure?

---

## 📚 Referencias oficiales

- ¿Qué es Bicep?: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview
- Estructura y sintaxis de un archivo Bicep: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/file
- Parámetros y decoradores: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameters
- Archivos `.bicepparam`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameter-files
- Módulos Bicep: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules
- Loops: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/loops
- Recursos `existing`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/existing-resource
- Role assignments con Bicep: https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-template
- Scopes de despliegue: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-to-subscription
- What-if: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if
- Modos de despliegue: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-modes
- Borrado automático del historial de despliegues: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-history-deletions
- Deployment Stacks: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks
- Template Specs: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/template-specs
- Registros privados de módulos Bicep: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/private-module-registry
- Azure Verified Modules: https://learn.microsoft.com/en-us/community/content/azure-verified-modules
- Referencia de plantillas: storage accounts: https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
- Terraform en Azure: https://learn.microsoft.com/en-us/azure/developer/terraform/overview
- Estado de Terraform en Azure Storage: https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage
- Comparar Bicep y Terraform: https://learn.microsoft.com/en-us/azure/developer/terraform/comparing-terraform-and-bicep
- `az deployment group`: https://learn.microsoft.com/en-us/cli/azure/deployment/group
- `az stack group`: https://learn.microsoft.com/en-us/cli/azure/stack/group

### Terraform (excepción de la guía §10.1)

- Provider `azurerm`: https://registry.terraform.io/providers/hashicorp/azurerm/5.7.0/docs
- Backend `azurerm`: https://developer.hashicorp.com/terraform/language/backend/azurerm
