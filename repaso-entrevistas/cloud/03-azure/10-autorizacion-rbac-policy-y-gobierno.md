# 10 — Autorización: Azure RBAC, Policy y gobierno

> **Objetivo:** decidir qué puede hacer cada identidad y dónde, y cómo tienen que quedar los recursos
> aunque alguien con permisos intente otra cosa: Azure RBAC, deny assignments, PIM, Azure Policy,
> locks, tags y landing zones.
> **Se asume leído:** [`01`](01-infraestructura-global-y-resource-manager.md) (la jerarquía de scopes
> y el control plane frente al data plane) y [`09`](09-identidad-entra-id-y-managed-identities.md)
> (las identidades).
> **Se toca más con:** [`09`](09-identidad-entra-id-y-managed-identities.md), que crea las identidades
> que aquí reciben permisos, y el [`15`](15-bicep-iac.md) (Bicep), que despliega role assignments, policies,
> locks y Deployment Stacks como código.
> **Se practica en:** [`L02`](l02-entra-id-rbac-y-managed-identities.md) (role assignments en el scope correcto y en el equivocado, el plano de
> datos, la propagación) y [`L03`](l03-bicep-desde-la-cli.md) (un lock, una policy y un Deployment Stack con deny settings). Ver
> [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [Dos preguntas](#1--dos-preguntas-distintas) ·
[Role assignment](#2--el-role-assignment-quién-qué-dónde) · [Role definitions](#3--role-definitions-actions-y-dataactions) ·
[Roles clave](#4--los-roles-que-hay-que-saber) · [Custom roles y conditions](#5--custom-roles-y-conditions) ·
[Asignar y diagnosticar](#6--asignar-un-rol-y-diagnosticar-un-authorizationfailed) ·
[Propagación y límites](#7--propagación-caché-y-límites) · [Deny assignments](#8--deny-assignments) ·
[PIM](#9--privileged-identity-management) · [Azure Policy](#10--azure-policy) ·
[⚖ Policy frente a RBAC](#11--policy-frente-a-rbac) · [Locks](#12--resource-locks) ·
[Tags y landing zones](#13--tags-landing-zones-y-el-fin-de-blueprints) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Dos preguntas distintas

Un banco te pide dos cosas que suenan parecidas y no lo son:

1. *"Que el equipo de pagos pueda desplegar en su resource group y no en el de tarjetas"*. Es una
   pregunta de **permisos**: quién puede hacer qué, dónde. La responde **Azure RBAC**.
2. *"Que nadie, ni siquiera un Owner, pueda crear una storage account con acceso público"*. Es una
   pregunta de **cumplimiento**: cómo tienen que quedar los recursos, independientemente de quién los
   cree. La responde **Azure Policy**.

Y una tercera, más operativa: *"que nadie borre por accidente la base de producción"*. Esa la
responden los **locks**.

El capítulo recorre las tres, sobre la jerarquía de scopes del [`01` §6](01-infraestructura-global-y-resource-manager.md#6--la-jerarquía-de-scopes).

---

## 2. 🧱 El role assignment: quién, qué, dónde

Todo permiso de Azure RBAC es un **role assignment**, y todo role assignment tiene tres partes:

```text
Security principal   ¿quién?   usuario, grupo, service principal o managed identity
Role definition      ¿qué?     conjunto de acciones permitidas (Owner, Reader, Storage Blob Data Reader…)
Scope                ¿dónde?   management group, suscripción, resource group o recurso
```

Tres reglas que rigen todo lo demás:

- **se hereda hacia abajo**: un rol asignado en la suscripción aplica a todos sus resource groups y
  recursos; uno asignado en un resource group, a todos sus recursos;
- **es aditivo**: los permisos efectivos son la suma de todos los role assignments del principal
  (directos y por grupo) en ese scope y los superiores. No hay un "deny" que tú escribas (§8);
- **el scope importa tanto como el rol**: `Storage Blob Data Contributor` sobre una storage account da
  acceso a esa cuenta; sobre la suscripción, a todas las cuentas de la suscripción.

> 🧠 **Modelo mental.** Privilegio mínimo en Azure es elegir el rol más pequeño **y** el scope más
> bajo. Un rol correcto en un scope demasiado alto es un permiso excesivo igual.

---

## 3. 🧱 Role definitions: `actions` y `dataActions`

Un rol es un documento JSON con cinco listas:

```json
{
  "Name": "Storage Blob Data Reader",
  "Actions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/read"
  ],
  "NotActions": [],
  "DataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"
  ],
  "NotDataActions": [],
  "AssignableScopes": ["/"]
}
```

- `Actions` son operaciones de **control plane**: gestionar el recurso a través de ARM ([`01`](01-infraestructura-global-y-resource-manager.md)
  §10). Aquí, listar los contenedores.
- `DataActions` son operaciones de **data plane**: usar el recurso. Aquí, leer el contenido de los
  blobs.
- `NotActions` y `NotDataActions` **restan** de lo concedido en el mismo rol. **No son un deny**: si
  otro role assignment concede esa acción, el principal la tiene.
- `AssignableScopes` dice dónde se puede asignar el rol; `/` es "en cualquier sitio", propio de los
  roles integrados.

Esta separación es la respuesta a la pregunta favorita de las entrevistas:

> Nunca respondas: "el Owner de la suscripción puede leer todos los blobs". Mejor: "Owner concede
> `*` en `Actions`, es decir, todo el control plane, pero ninguna `DataAction`. Para leer datos de
> un blob con Entra ID necesita un rol de datos como `Storage Blob Data Reader`. Puede asignárselo,
> porque puede asignar roles, pero no lo tiene por defecto".

El matiz: Owner sí puede **listar las access keys** de la cuenta, que es una acción de control plane,
y con la clave entraría a los datos. Por eso el laboratorio deshabilita Shared Key ([`06` §8](06-almacenamiento-storage-accounts.md#8--acceso-claves-sas-y-entra-id)):
cierra ese atajo.

---

## 4. 🧱 Los roles que hay que saber

| Rol | Qué concede | Lo que no puede |
|---|---|---|
| **Owner** | Todo el control plane y asignar roles | Leer datos sin un rol de datos |
| **Contributor** | Todo el control plane | Asignar roles ni gestionar asignaciones |
| **Reader** | Ver recursos | Cambiar nada |
| **User Access Administrator** | Gestionar el acceso: asignar cualquier rol, incluido Owner | Gestionar recursos |
| **Role Based Access Control Administrator** | Asignar roles, limitable con conditions | Gestionar acceso por otras vías, como Azure Policy |

Y los **roles de datos**, que son los que usa una aplicación: `Storage Blob Data Reader`,
`Storage Blob Data Contributor`, `Key Vault Secrets User`, `Azure Service Bus Data Sender` y
`Azure Service Bus Data Receiver`. Cosmos DB for NoSQL es la excepción: su plano de datos tiene sus
propias role definitions y assignments, que se gestionan con `az cosmosdb sql role` ([`08`](08-cosmos-db.md)
§11).

Dos detalles que se preguntan: **Contributor no puede asignar roles**, así que un pipeline de
despliegue con Contributor no puede crear los role assignments de las identidades que despliega; y
**User Access Administrator puede asignarse Owner a sí mismo**, así que es tan sensible como Owner.

---

## 5. 🧱 Custom roles y conditions

Cuando ningún rol integrado encaja, se crea un **custom role** con las acciones exactas. Son
recursos del tenant (hasta 5.000 por directorio) y se asignan igual que los integrados. Un custom
role con `DataActions` **no se puede asignar en un management group**, solo en suscripciones o más
abajo.

Las **conditions** (ABAC, *attribute-based access control*) afinan un role assignment con atributos:

- en **Storage**, "puede leer blobs **solo** si el blob tiene el tag de índice `proyecto=inv`" o
  "solo en el contenedor `facturas`", sin crear un rol por contenedor;
- en la **delegación**, "puede asignar roles, **pero solo** `Storage Blob Data Reader` y **solo** a
  service principals". Es la forma segura de dejar que un equipo gestione los permisos de sus propias
  identidades sin darle User Access Administrator.

---

## 6. 🧱 Asignar un rol y diagnosticar un `AuthorizationFailed`

Dar a `inv-api-id` lectura y escritura de blobs **solo en la storage account del laboratorio**:

```bash
az role assignment create \
  --assignee-object-id "$(az identity show --name inv-api-id --resource-group inv-lab-rg --query principalId --output tsv)" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$(az storage account show --name invlab472913 --resource-group inv-lab-rg --query id --output tsv)"
```

- `--assignee-object-id` recibe el **`principalId`** de la identidad (el object ID de su service
  principal, [`09` §5](09-identidad-entra-id-y-managed-identities.md#5--managed-identities)), no su `clientId` ni su resource ID. Pasar el `clientId` es el error
  más frecuente, y falla con un principal que no existe.
- `--assignee-principal-type ServicePrincipal` le dice a ARM qué tipo de principal es. Evita que la
  CLI consulte el directorio, que un pipeline sin permisos de lectura en Entra ID no puede hacer, y
  evita el error `PrincipalNotFound` cuando la identidad se acaba de crear y aún no se replicó.
- `--role` admite el nombre o el ID del rol. En código (Bicep) se usa el ID, que no cambia si
  Microsoft renombra el rol.
- `--scope` es el **resource ID de la storage account**: el permiso vale para esa cuenta y nada más.
  Con `--scope` del resource group valdría para todas las cuentas del grupo, y con el de la
  suscripción, para todas las de la suscripción.

Cuando falta un permiso, ARM responde con un mensaje que trae todo lo necesario para diagnosticar:

```text
The client '<clientName>' with object id '<objectId>' does not have authorization to perform
action '<action>' over scope '<scope>' or the scope is invalid.
If access was recently granted, please refresh your credentials. (code: AuthorizationFailed)
```

> 🩺 **Diagnóstico.** Un `AuthorizationFailed` se lee de izquierda a derecha: **quién** (el object
> ID), **qué acción** exacta faltó y **en qué scope**. Con esas tres piezas se busca qué rol incluye
> la acción y si el principal lo tiene en ese scope o en uno superior:
> `az role assignment list --assignee <object-id> --all --include-inherited`. El error más común no es
> el rol equivocado sino el scope equivocado.

[`L02`](l02-entra-id-rbac-y-managed-identities.md) provoca los dos casos: el rol en el scope equivocado y el Owner que no puede leer el blob.

---

## 7. 🧱 Propagación, caché y límites

**El problema:** asignas el rol, pruebas enseguida y sigue fallando. Diez minutos después funciona,
sin haber cambiado nada.

- **Un role assignment puede tardar hasta 10 minutos en surtir efecto**, porque ARM cachea
  configuración. Cerrar sesión y volver a entrar en la CLI, o pedir un token nuevo, fuerza el refresco.
- **Retirar un role assignment no invalida los tokens ya emitidos**: un token sigue siendo válido
  hasta que caduca. Para una revocación inmediata hace falta más (Continuous Access Evaluation en los
  servicios que la soportan, deshabilitar la identidad).
- **Las managed identities cachean pertenencias a grupos**: si das un rol a un grupo y metes en él una
  managed identity, el cambio puede tardar **horas** en notarse, porque los servicios mantienen una
  caché del token de la identidad de unas 24 horas por recurso. Por eso a las managed identities se les
  asignan roles directamente, no por grupo.
- Un **role assignment a un principal borrado** aparece como *Identity not found* y hay que
  limpiarlo a mano.
- **Límites**: 5.000 role assignments por suscripción (fijo, no ampliable) y 500 por management
  group. Asignar a grupos en vez de a personas es la forma de no llegar.

> Nunca respondas: "el role assignment surte efecto al instante". Mejor: "puede tardar hasta diez
> minutos por la caché de ARM, y un token ya emitido sigue valiendo hasta que caduca; por eso los
> scripts de despliegue esperan y reintentan tras asignar roles".

---

## 8. 🧱 Deny assignments

Un **deny assignment** bloquea acciones concretas a principals en un scope **aunque un role assignment
las conceda**, y admite excepciones (*excluded principals*). Tiene precedencia sobre los role
assignments. Pero:

> Punto importante: tú no puedes crear un deny assignment directamente. Los crea Azure.

Aparecen por dos vías:

- **Azure Managed Applications** y servicios que se implementan como tales, que protegen su resource
  group de infraestructura;
- **Deployment Stacks** con *deny settings*: el stack crea un deny assignment sobre los recursos que
  administra, por ejemplo "nadie puede borrarlos salvo el pipeline". Es la única forma de que *tú*
  obtengas un deny ([`15`](15-bicep-iac.md)).

Por eso la respuesta a "¿cómo le quito a alguien un permiso que le da un grupo?" no es un deny: es
sacarlo del grupo, reestructurar los role assignments o, si lo que se quiere es impedir una
configuración, una Azure Policy.

---

## 9. 🧱 Privileged Identity Management

Los roles poderosos asignados permanentemente son un riesgo: una cuenta comprometida tiene Owner las
24 horas. **Privileged Identity Management** (PIM, requiere Entra ID P2) convierte las asignaciones en
**elegibles**:

- el usuario **no tiene** el rol hasta que lo **activa**, con justificación, MFA y, si se configura,
  aprobación;
- la activación dura un tiempo limitado y queda auditada;
- las asignaciones elegibles **no cuentan** para el límite de 5.000 por suscripción.

Es el *just-in-time access* aplicado a Azure RBAC y a los roles de Entra ID. En banca es la respuesta
esperada a "¿quién tiene acceso de administración a producción?": nadie de forma permanente.

---

## 10. 🧱 Azure Policy

**El problema:** quieres que ninguna storage account de la organización tenga acceso público, que todo
recurso lleve el tag `costCenter` y que nada se cree fuera de dos regiones, sin depender de que cada
equipo lo recuerde.

**Azure Policy** evalúa los recursos contra reglas y actúa según el **efecto**. Sus piezas:

- **policy definition**: la regla (una condición sobre las propiedades del recurso) y su efecto.
  Microsoft publica cientos de definiciones integradas;
- **initiative** (*policy set*): un grupo de definiciones que se asigna junto, como un estándar de
  cumplimiento;
- **assignment**: la definición o iniciativa aplicada a un scope, con sus parámetros y exclusiones;
- **exemption**: una excepción temporal o permanente, justificada, para un recurso o scope.

Los efectos que se preguntan:

| Efecto | Qué hace |
|---|---|
| `deny` | Rechaza la creación o actualización que no cumple |
| `audit` | Permite, pero marca el recurso como no conforme |
| `modify` | Añade, cambia o quita propiedades o tags en la petición (y remedia lo existente) |
| `append` | Añade campos a la petición |
| `deployIfNotExists` | Tras crear el recurso, despliega un recurso relacionado si falta (un diagnostic setting, por ejemplo) |
| `auditIfNotExists` | Marca como no conforme si falta el recurso relacionado |
| `denyAction` | Bloquea una acción concreta, como borrar |
| `disabled` | Desactiva la regla sin quitar la asignación |

Cuatro hechos de funcionamiento:

- **el orden de evaluación** en una petición es: `disabled`, luego `append` y `modify` (que pueden
  cambiar la petición), luego `deny`, luego `audit`; `deployIfNotExists` y `auditIfNotExists` actúan
  después de que el recurso se crea;
- varias asignaciones se combinan como **lo más restrictivo acumulado**: si una policy exige `westus`
  y otra `eastus`, con `deny` en ambas no se puede crear nada;
- **los recursos existentes no se corrigen solos**: una policy nueva con `deny` no borra ni cambia lo
  que ya había; lo marca como no conforme. Para corregirlo están las **remediation tasks**, que usan
  una managed identity de la asignación para aplicar `modify` o `deployIfNotExists` sobre lo existente;
- las policies actúan sobre el **control plane**; solo algunos modos de resource provider evalúan el
  data plane;
- **cuándo se evalúa el cumplimiento**: una asignación nueva o modificada tarda unos cinco minutos en
  aplicarse al scope y luego arranca su ciclo de evaluación; un recurso creado o actualizado muestra su
  estado unos 15 minutos después; todas las asignaciones se reevalúan una vez cada 24 horas; y se
  puede forzar un escaneo con `az policy state trigger-scan --resource-group inv-lab-rg`. Por eso el
  panel de cumplimiento no refleja un cambio al instante, aunque el `deny` sí actúa en la petición.

El ejemplo del laboratorio, exigir el tag `project` en todo recurso del resource group:

```bash
az policy assignment create \
  --name require-project-tag \
  --policy 871b6d14-10aa-478d-b590-94f262ecfa99 \
  --scope "$(az group show --name inv-lab-rg --query id --output tsv)" \
  --params '{"tagName": {"value": "project"}}'
```

- `--policy 871b6d14-10aa-478d-b590-94f262ecfa99` es el identificador de la definición integrada
  **"Require a tag on resources"**, con efecto `deny`. Las definiciones integradas se identifican por
  GUID, no por nombre.
- `--scope` limita la asignación al resource group del laboratorio: no afecta al resto de la
  suscripción.
- `--params` rellena el parámetro `tagName` de la definición. Desde que la asignación surte efecto,
  crear un recurso sin el tag `project` en ese resource group falla con `RequestDisallowedByPolicy`,
  que dice qué asignación lo rechazó. Esa definición no aplica a los resource groups, que tienen su
  propia variante.

---

## 11. ⚖ Policy frente a RBAC

| Criterio | Azure RBAC | Azure Policy |
|---|---|---|
| Pregunta | ¿Quién puede hacer esta acción aquí? | ¿Cómo tiene que quedar este recurso? |
| Se centra en | El principal | Las propiedades del recurso |
| Un Owner puede saltárselo | Es quien lo administra | ❌ una policy `deny` le aplica igual |
| Da permisos | ✅ | ❌ nunca |
| Actúa sobre lo existente | — | Lo audita; lo corrige con remediación |

```text
Regla de arquitectura:
RBAC decide si puedes crear una storage account.
Policy decide si la storage account que creas puede tener acceso público.
Hacen falta las dos.
```

---

## 12. 🧱 Resource locks

Un **lock** protege un recurso, un resource group o una suscripción contra cambios accidentales,
**para todos los usuarios y roles**, incluido el Owner:

- **`CanNotDelete`**: se puede leer y modificar, no borrar;
- **`ReadOnly`**: se puede leer, no modificar ni borrar; equivale a restringir a todos al rol Reader.

Los locks se **heredan** hacia abajo, gana el más restrictivo, y un lock en un recurso **bloquea el
borrado de todo su resource group**: no hay borrado parcial. Solo Owner y User Access Administrator
(o roles con `Microsoft.Authorization/locks/*`) pueden crearlos y quitarlos.

Lo que convierte a `ReadOnly` en una fuente de sorpresas es que **bloquea toda petición `POST` al
control plane**, y muchas operaciones que parecen de lectura son `POST`:

- en una storage account, **listar las access keys**, lo que además rompe al portal y a cualquier
  herramienta que entre a los datos con la clave;
- en un resource group con VMs, **arrancar o reiniciar** una VM;
- en un resource group con un App Service plan, **escalarlo**;
- en un Application Gateway, **consultar la salud del backend**.

Y la frontera de siempre: **los locks solo afectan al control plane**. Un `CanNotDelete` en una
storage account no impide borrar sus blobs por el data plane ([`01` §10](01-infraestructura-global-y-resource-manager.md#10--control-plane-y-data-plane)).

```bash
az lock create \
  --name inv-lab-nodelete \
  --lock-type CanNotDelete \
  --resource-group inv-lab-rg
```

- `az lock create` sin `--resource-name` aplica el lock al **resource group entero**, y por herencia a
  todo lo que contiene.
- `--lock-type CanNotDelete` permite seguir trabajando pero hace fallar `az group delete` con un error
  de scope bloqueado hasta que alguien con permiso quite el lock. [`L03`](l03-bicep-desde-la-cli.md) lo provoca y lo resuelve.

> ⚠️ **Un lock `CanNotDelete` en un resource group impide que ARM borre automáticamente el historial
> de despliegues**, y al llegar a 800 despliegues en el historial, los despliegues nuevos fallan. Es un
> efecto secundario de los locks que aparece meses después.

---

## 13. 🧱 Tags, landing zones y el fin de Blueprints

**Tags como gobierno.** Los tags no se heredan ([`01` §13](01-infraestructura-global-y-resource-manager.md#13--tags)). Con Azure Policy se consiguen tres
cosas: **exigir** un tag (`deny`), **heredarlo** del resource group o la suscripción (`modify`, con
remediación para lo existente) y **auditarlo**. Es la base de la atribución de costos por proyecto o
centro de costo en Cost Management.

**Landing zones.** El *Cloud Adoption Framework* de Microsoft propone una arquitectura de referencia
para organizaciones: una jerarquía de management groups (plataforma, landing zones corporativas y
online, sandbox), suscripciones separadas para identidad, conectividad (el hub del [`02` §10](02-redes-vnet-nsg-y-enrutamiento.md#10--hub-and-spoke-y-azure-firewall)) y
gestión, y un conjunto de Azure Policies asignadas en los management groups. Una **landing zone** es
la suscripción preparada —red, identidad, políticas, monitoreo— donde un equipo despliega su carga. En
una entrevista de arquitecto basta con saber explicar por qué se separa en management groups y
suscripciones y qué se asigna en cada nivel.

> 📝 **Contexto.** **Azure Blueprints**, que empaquetaba plantillas, role assignments y policies,
> **se retira**: su retiro por fases empieza el 31 de julio de 2026 y termina el **31 de enero de
> 2027**, cuando las definiciones y asignaciones no exportadas se borran. Sus sustitutos son las
> **Template Specs** (almacenar y versionar las plantillas) y los **Deployment Stacks** (desplegar,
> gestionar el ciclo de vida y bloquear los recursos con deny settings). El [`15`](15-bicep-iac.md) los
> desarrolla.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "El Owner puede leer los datos del blob" | Owner no tiene `DataActions`; necesita un rol de datos (aunque puede asignárselo o listar las claves) |
| "El role assignment surte efecto al instante" | Hasta 10 minutos por caché, y los tokens emitidos siguen valiendo hasta caducar |
| "`NotActions` deniega la acción" | Resta dentro del mismo rol; otro role assignment puede concederla |
| "Creo un deny assignment para quitarle el permiso" | No se pueden crear directamente; los crean Managed Applications y Deployment Stacks |
| "Azure Policy da permisos" | Nunca; restringe o corrige configuraciones |
| "Una policy `deny` nueva arregla lo existente" | Lo marca como no conforme; corregir exige remediación |
| "Un lock `ReadOnly` solo impide borrar" | Bloquea toda escritura y todo `POST`: listar claves, arrancar VMs, escalar planes |
| "Un lock protege los datos" | Solo el control plane; los datos se borran por el data plane |

---

## 🧠 Preguntas rápidas

1. ¿Cuáles son las tres partes de un role assignment?
2. ¿Qué diferencia hay entre `Actions` y `DataActions` en una role definition?
3. ¿Por qué el Owner de una suscripción no puede leer un blob con Entra ID sin hacer nada más, y qué atajo tiene si la cuenta admite claves?
4. ¿Qué rol le darías a un pipeline que despliega recursos y además tiene que crear los role assignments de las identidades que despliega, sin darle Owner?
5. ¿Qué hace `NotActions` y por qué no es un deny?
6. ¿Para qué sirven las conditions en un role assignment? Da un ejemplo de delegación segura.
7. Asignaste un rol a `inv-api-id` y el primer intento sigue fallando con `AuthorizationFailed`. ¿Qué tres datos del mensaje miras y qué causas descartas?
8. ¿Qué identificador de una managed identity recibe `--assignee-object-id` y qué pasa si pasas otro?
9. ¿Por qué no conviene dar roles a una managed identity a través de un grupo?
10. ¿Puedes crear un deny assignment para impedir que un grupo borre recursos? ¿Qué alternativas tienes?
11. ¿Qué cambia PIM respecto de un role assignment permanente?
12. ¿Qué diferencia hay entre los efectos `deny`, `audit`, `modify` y `deployIfNotExists` de Azure Policy?
13. Asignaste una policy `deny` que exige un tag. ¿Qué pasa con los recursos que ya existían sin ese tag?
14. ¿En qué se diferencia Azure Policy de Azure RBAC y por qué necesitas las dos?
15. ¿Por qué un lock `ReadOnly` en una storage account impide listar sus claves, y protege un lock los blobs de la cuenta?
16. ¿Qué pasa con Azure Blueprints y con qué se sustituye?

---

## 📚 Referencias oficiales

- ¿Qué es Azure RBAC?: https://learn.microsoft.com/en-us/azure/role-based-access-control/overview
- Entender los role assignments: https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments
- Entender las role definitions: https://learn.microsoft.com/en-us/azure/role-based-access-control/role-definitions
- Entender el scope en Azure RBAC: https://learn.microsoft.com/en-us/azure/role-based-access-control/scope-overview
- Roles integrados de Azure: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
- Custom roles: https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles
- Conditions en role assignments (ABAC): https://learn.microsoft.com/en-us/azure/role-based-access-control/conditions-overview
- Delegar la gestión de role assignments con conditions: https://learn.microsoft.com/en-us/azure/role-based-access-control/delegate-role-assignments-overview
- Asignar roles con la CLI: https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli
- Troubleshooting de Azure RBAC (propagación, identidades no encontradas): https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting
- Límites de Azure RBAC: https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshoot-limits
- Limitación de las managed identities en autorización por grupos: https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/managed-identity-best-practice-recommendations
- Deny assignments: https://learn.microsoft.com/en-us/azure/role-based-access-control/deny-assignments
- ¿Qué es Privileged Identity Management?: https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure
- ¿Qué es Azure Policy?: https://learn.microsoft.com/en-us/azure/governance/policy/overview
- Efectos de Azure Policy y orden de evaluación: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effect-basics
- Cuándo se evalúa el cumplimiento: https://learn.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data
- Remediar recursos no conformes: https://learn.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources
- Definiciones integradas de Azure Policy: https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies
- Políticas de tags: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-policies
- Resource locks: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources
- Landing zones del Cloud Adoption Framework: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/
- Retiro de Azure Blueprints: https://learn.microsoft.com/en-us/azure/governance/blueprints/blueprint-retirement
- Migrar de Blueprints a Deployment Stacks: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/migrate-blueprint
- `az role assignment`: https://learn.microsoft.com/en-us/cli/azure/role/assignment
- `az policy assignment`: https://learn.microsoft.com/en-us/cli/azure/policy/assignment
- `az lock`: https://learn.microsoft.com/en-us/cli/azure/lock
