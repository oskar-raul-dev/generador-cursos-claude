# A03 — Catálogo de errores y diagnóstico

> **Objetivo:** reunir cada error que el curso provoca o describe con su causa, la hipótesis que lo
> explica, el comando que la confirma y la corrección, ordenados por la capa en que ocurren. Es el
> apéndice que se abre con un mensaje de error en la otra pantalla.
> **Se asume leído:** [`A01`](a01-az-de-supervivencia.md) (la mecánica de `az`, y los errores que son de
> la CLI y no de Azure). Complementa todos los labs, que provocan estos errores a propósito.
> **Vigencia:** 29 de septiembre de 2026. Los textos de error citados entre comillas son los de la
> documentación de Microsoft; los que el curso solo describe, se describen.

**Salto rápido:** [El método](#1--el-método-una-variable-a-la-vez) ·
[Resource Manager](#2--resource-manager-providers-cuotas-y-throttling) ·
[Autorización de control plane](#3--autorización-de-control-plane) ·
[Data plane](#4--data-plane-el-token-es-válido-y-aun-así-403) ·
[Nombres y soft-delete](#5--nombres-retenidos-y-soft-delete) · [Tokens](#6--tokens-y-apis-protegidas) ·
[Container Apps](#7--container-apps) · [Red y DNS](#8--red-y-dns-cuando-no-hay-error-solo-silencio) ·
[Datos y mensajería](#9--datos-y-mensajería) · [Observabilidad](#10--observabilidad-el-dato-que-no-está) ·
[Tabla de un vistazo](#11--tabla-de-un-vistazo) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El método: una variable a la vez

Cuatro preguntas ordenan cualquier diagnóstico en Azure, y ahorran la mitad del tiempo si se hacen en
este orden:

```text
1. ¿Es de la CLI o de Azure?         --debug: si no hay "Request URL", el error nació en tu terminal (A01 §14)
2. ¿Control plane o data plane?      management.azure.com → ARM y Azure RBAC
                                     <recurso>.<servicio>  → el servicio, con sus propios códigos
3. ¿Qué código exacto?               el código separa causas que el HTTP 403 junta
4. ¿Qué cambió?                      un rol recién asignado, una revisión nueva, un default de API
```

Dos reglas de método que atraviesan la serie práctica:

- **Una variable a la vez.** Si cambias el rol, el scope y la red a la vez y funciona, no sabes qué lo
  arregló, y la próxima vez tampoco.
- **Reproducir antes de reparar.** Un error que no sabes provocar es un error que no sabes si
  corregiste.

> 🧠 **Modelo mental.** Un `403` no es un diagnóstico: es una categoría. `AuthorizationFailed`,
> `AuthorizationPermissionMismatch`, `KeyBasedAuthenticationNotPermitted`, `AuthorizationFailure` y
> `ForbiddenByRbac` son cinco `403` con cinco causas y cinco correcciones distintas.

---

## 2. 🩺 Resource Manager: providers, cuotas y throttling

### `MissingSubscriptionRegistration`

- **Síntoma.** "The subscription is not registered to use namespace {namespace}" al crear el primer
  recurso de un tipo.
- **Causa.** La suscripción no está registrada en el resource provider. El portal y la CLI registran la
  mayoría automáticamente, pero no todos; una llamada directa a ARM, nunca.
- **Confirmar.** `az provider show --namespace Microsoft.App --query registrationState`.
- **Corregir.** `az provider register --namespace Microsoft.App`; mientras está en `Registering`, esperar
  y reintentar.
- **Prevenir.** Registrar los providers de la carga al preparar la suscripción ([`L01` §4](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md#4--resource-providers-y-provocar-missingsubscriptionregistration)).

### `NoRegisteredProviderFound`

- **Síntoma.** "No registered resource provider found for location {location} and API version
  {api-version} for type {resource-type}".
- **Causa.** El provider existe, pero no admite esa **región** o esa **versión de API** para ese tipo.
- **Confirmar.** `az provider show --namespace <ns> --query "resourceTypes[?resourceType=='<tipo>'].{locations:locations, versions:apiVersions}"`.
- **Corregir.** Cambiar la región o la `api-version` por una de la lista.

### `429` de Resource Manager

- **Síntoma.** Un script que consulta el estado de un recurso en bucle empieza a recibir `429`.
- **Causa.** Throttling de ARM: se agotó el cupo de peticiones de la suscripción o del principal
  ([`01` §12](01-infraestructura-global-y-resource-manager.md#12--throttling-de-resource-manager)).
- **Corregir.** Respetar la cabecera `Retry-After`, sondear menos y dejar que el SDK reintente con
  backoff; `az ... wait` en vez de un bucle propio.

### `DeploymentQuotaExceeded`

- **Síntoma.** Un despliegue nuevo falla en un resource group con mucha historia.
- **Causa.** El historial de despliegues del scope llegó a **800** y ARM no pudo recortarlo, casi siempre
  porque un lock `CanNotDelete` en el grupo lo impide ([`15` §5](15-bicep-iac.md#5--scopes-de-despliegue)).
- **Corregir.** Borrar despliegues antiguos del historial (`az deployment group delete`) o quitar el lock
  que bloquea la limpieza automática.

---

## 3. 🩺 Autorización de control plane

### `AuthorizationFailed`

- **Síntoma.** "The client '…' with object id '…' does not have authorization to perform action '…' over
  scope '…' or the scope is invalid."
- **Causa.** Falta un rol con esa **acción** en ese **scope** para ese **principal**. Tres piezas, las
  tres en el mensaje ([`10` §6](10-autorizacion-rbac-policy-y-gobierno.md#6--asignar-un-rol-y-diagnosticar-un-authorizationfailed)).
- **Confirmar.** `az role assignment list --assignee <object-id> --all --include-inherited --query "[].{role:roleDefinitionName, scope:scope}"`.
  ¿Es el principal correcto (el `principalId`, no el `clientId`)? ¿Incluye el rol la acción? ¿Contiene
  el scope del rol al del error?
- **Corregir.** Asignar el rol mínimo que incluye la acción, en el scope justo. Si se acaba de asignar,
  es **propagación**: hasta 10 minutos, y renovar el token.

### `PrincipalNotFound`

- **Síntoma.** Un role assignment sobre una identidad recién creada falla diciendo que el principal no
  existe.
- **Causa.** La identidad existe en ARM, pero aún no se replicó en Entra ID cuando ARM consultó el
  directorio.
- **Corregir.** `--assignee-principal-type ServicePrincipal` en la CLI, o `principalType:
  'ServicePrincipal'` en Bicep: ARM no consulta el directorio ([`15` §3](15-bicep-iac.md#3--un-archivo-bicep-del-laboratorio)).

### `RoleAssignmentExists`

- **Síntoma.** "Conflict: RoleAssignmentExists" al desplegar una plantilla que declara un role
  assignment.
- **Causa.** Ya existe una asignación con el mismo principal, rol y scope, **con otro nombre**: creada a
  mano, o por una plantilla que genera el nombre al azar.
- **Confirmar.** `az role assignment list --assignee <principalId> --scope <scope> --role <rol>`.
- **Corregir.** Nombres deterministas con `guid(scope, principal, rol)` y, una vez, borrar la asignación
  creada fuera de la plantilla ([`L03` §5](l03-bicep-desde-la-cli.md#5--what-if-contra-lo-que-ya-existe-y-roleassignmentexists)).

### `RequestDisallowedByPolicy`

- **Síntoma.** Un despliegue o un `create` se rechaza aunque eres Owner.
- **Causa.** Una Azure Policy con efecto `deny` en ese scope o en uno superior. El mensaje nombra la
  asignación y la definición.
- **Confirmar.** `az policy assignment list --scope <scope> --disable-scope-strict-match`, y leer la
  definición que nombra el error.
- **Corregir.** Cumplir la policy (el tag, la región, el SKU que exige) o, si procede, una exención. No
  se arregla con un rol: Policy no da ni quita permisos ([`L03` §10](l03-bicep-desde-la-cli.md#10--una-azure-policy-que-rechaza-lo-que-no-lleva-tags)).

### Scope bloqueado por un lock

- **Síntoma.** `az group delete`, o el borrado o la modificación de un recurso, falla con un error de
  scope bloqueado que nombra el lock.
- **Causa.** Un lock `CanNotDelete` o `ReadOnly` en el recurso, en el grupo o en la suscripción; se
  heredan y aplican al Owner. `ReadOnly` bloquea también las operaciones `POST`, como listar las claves de
  una storage account.
- **Confirmar.** `az lock list --resource-group <rg>`, y en la suscripción `az lock list`.
- **Corregir.** Quitar el lock (Owner o User Access Administrator) y repetir ([`L03` §8](l03-bicep-desde-la-cli.md#8--un-lock-que-bloquea-az-group-delete)).

### Denegado por un deny assignment

- **Síntoma.** Siendo Owner, el borrado (o la escritura) de un recurso se deniega, y el mensaje menciona
  un deny assignment.
- **Causa.** Un Deployment Stack con deny settings, o una Managed Application: los únicos que crean deny
  assignments. Un deny gana a cualquier role assignment.
- **Confirmar.** `az rest --method get --url ".../resourceGroups/<rg>/providers/Microsoft.Authorization/denyAssignments?api-version=2022-04-01"`.
- **Corregir.** Operar a través del stack (`az stack group delete --action-on-unmanage
  deleteResources`), o ser uno de sus principals exentos ([`L03` §9](l03-bicep-desde-la-cli.md#9--el-deployment-stack-y-su-deny-assignment)).

---

## 4. 🩺 Data plane: el token es válido y aun así `403`

La causa de fondo de toda esta sección es la de [`10` §3](10-autorizacion-rbac-policy-y-gobierno.md#3--role-definitions-actions-y-dataactions):
**Owner y Contributor no tienen `DataActions`**. Gestionar el recurso no da acceso a lo que contiene.

### Storage: tres `403`, tres causas

| Código | Mensaje | Causa | Corrección |
|---|---|---|---|
| `AuthorizationPermissionMismatch` | "This request isn't authorized to perform this operation using this permission." | Token válido sin el rol de datos en ese scope (o SAS sin el permiso) | Rol de datos (`Storage Blob Data Reader/Contributor`) en la cuenta o el contenedor |
| `KeyBasedAuthenticationNotPermitted` | "Key based authentication is not permitted on this storage account." | Petición firmada con clave en una cuenta con Shared Key deshabilitado | `--auth-mode login` y un rol de datos |
| `AuthorizationFailure` | "This request isn't authorized to perform this operation" | La **red**: acceso público deshabilitado, IP o VNet fuera del firewall | Entrar por el private endpoint o ajustar el firewall |

Se reproducen los tres en [`L02` §5](l02-entra-id-rbac-y-managed-identities.md#5--el-owner-que-no-puede-escribir-un-blob)
y [`L04` §10](l04-red-vnet-nsg-private-endpoint-y-dns.md#10--cerrar-el-acceso-público-y-leer-el-403-de-red).

### Key Vault: `ForbiddenByRbac`

- **Síntoma.** `403 ForbiddenByRbac` al leer o escribir un secreto; el mensaje trae el caller, la acción
  de datos y el vault.
- **Causa.** Sin rol de datos de Key Vault (`Key Vault Secrets User` para leer, `Secrets Officer` para
  gestionar), o recién asignado y sin propagar. Si el vault tiene el acceso público cerrado, el `403` es de
  red.
- **Corregir.** El rol mínimo en el scope del vault, y esperar la propagación ([`L02` §11](l02-entra-id-rbac-y-managed-identities.md#11--key-vault-con-azure-rbac)).

### Cosmos DB: el rol que no es de Azure RBAC

- **Síntoma.** El SDK o la API REST reciben `403` con una identidad que tiene roles de Azure RBAC sobre
  la cuenta.
- **Causa.** El data plane de Cosmos DB for NoSQL **tiene su propio RBAC**: los role assignments de
  `az role assignment` no le sirven. Y con `disableLocalAuth`, las claves tampoco.
- **Confirmar.** `az cosmosdb sql role assignment list --account-name <cuenta> --resource-group <rg>`.
- **Corregir.** `az cosmosdb sql role assignment create` con un rol integrado de Cosmos DB y un scope
  dentro de la cuenta (`/dbs/inv/colls/events`) ([`L07` §5](l07-datos-y-eventos-cosmos-db-y-service-bus.md#5--roles-de-datos-el-rbac-propio-de-cosmos-db)).

### Service Bus: el rol en la entidad equivocada

- **Síntoma.** El emisor o el receptor no autorizan con Entra ID.
- **Causa.** Falta `Azure Service Bus Data Sender` o `Data Receiver`, o está en otra entidad: el emisor
  necesita el rol en el topic (o el namespace), el receptor en su subscription. Con `--disable-local-auth`,
  una connection string con clave no sirve.
- **Confirmar.** `az role assignment list --assignee <principalId> --all`, mirando el scope.
- **Corregir.** El rol de datos en la entidad justa ([`L07` §7](l07-datos-y-eventos-cosmos-db-y-service-bus.md#7--el-namespace-el-topic-y-la-subscription)).

### Application Insights: telemetría rechazada

- **Síntoma.** La app funciona y no llega telemetría; el agente escribe `403` en los logs de consola.
- **Causa.** Con `DisableLocalAuth=true`, la identidad no tiene **Monitoring Metrics Publisher** sobre el
  recurso de Application Insights.
- **Corregir.** El rol sobre el recurso ([`L08` §7](l08-observabilidad-kql-y-auditoria.md#7--la-telemetría-que-no-llega)).

---

## 5. 🩺 Nombres retenidos y soft-delete

### Key Vault con el nombre en estado eliminado

- **Síntoma.** Crear un vault falla con un conflicto de nombre, aunque no ves ninguno con ese nombre.
- **Causa.** Existe un vault **soft-deleted** con ese nombre: la documentación es explícita, no se puede
  reutilizar hasta que termine la retención, y en estado eliminado solo admite `recover` y `purge`.
- **Confirmar.** `az keyvault list-deleted`.
- **Corregir.** `az keyvault purge --name <vault> --location <región>`, o `az keyvault recover`. Con purge
  protection, esperar la retención o cambiar de nombre ([`L09` §8](l09-costos-y-destruccion-verificada.md#8--capa-5-lo-soft-deleted)).
- **Después de un `recover`.** Los role assignments del vault no vuelven: hay que reasignarlos.

### Log Analytics workspace con el nombre reservado

- **Síntoma.** Recrear un workspace con el mismo nombre falla tras borrarlo.
- **Causa.** Soft-delete de 14 días.
- **Corregir.** Recuperarlo (`az monitor log-analytics workspace recover`) y borrarlo con `--force`; la
  próxima vez, borrarlo directamente con `--force` ([`L09` §6](l09-costos-y-destruccion-verificada.md#6--capa-3-el-workspace-sin-soft-delete)).

### Nombre global ya tomado

- **Síntoma.** Crear una storage account, un registry, un vault, un namespace o una cuenta de Cosmos DB
  falla porque el nombre no está disponible.
- **Causa.** Esos nombres forman un hostname y son **únicos en todo Azure**: otra persona, en otra
  suscripción, lo tiene.
- **Corregir.** Otro sufijo, anotado para el resto del trabajo. No es un problema de permisos.

---

## 6. 🩺 Tokens y APIs protegidas

### `401` por audiencia

- **Síntoma.** Un token válido, bien firmado, recibe `401` con una queja sobre el claim `aud`.
- **Causa.** El token se emitió para **otro recurso**: ARM en vez de Storage, o ARM en vez de tu API.
- **Confirmar.** Decodificar el payload y mirar `aud` ([`A01` §12](a01-az-de-supervivencia.md#12--tokens-a-mano-az-account-get-access-token)).
- **Corregir.** Pedir el token para la audiencia correcta: `--resource https://storage.azure.com/`, o el
  scope `api://<appId>/...` de tu API ([`L06` §7](l06-identidad-de-aplicaciones-api-protegida.md#7--error-1-la-audiencia-equivocada)).

### `401` por issuer: la versión del token

- **Síntoma.** "The iss claim is not valid" con el tenant correcto.
- **Causa.** La API recibe tokens **v1** (`iss` = `https://sts.windows.net/<tenant>/`) y valida el emisor
  v2 (`…/v2.0`). La versión la decide la API receptora con `requestedAccessTokenVersion`, y `null` es v1.
- **Corregir.** Fijar `requestedAccessTokenVersion` a `2` en la app registration de la API y pedir un
  token nuevo ([`L06` §9](l06-identidad-de-aplicaciones-api-protegida.md#9--error-2-el-issuer-de-un-token-v1)).

### `403` con `roles` en el token

- **Síntoma.** Los usuarios pasan y los clientes máquina reciben `403`, aunque su token trae `roles`.
- **Causa.** El convertidor por defecto de Spring Security solo mapea `scp`; ignora `roles`.
- **Corregir.** Un `JwtAuthenticationConverter` que sume `roles` con su prefijo ([`L06` §11](l06-identidad-de-aplicaciones-api-protegida.md#11--error-3-el-403-de-un-convertidor-que-ignora-roles)).

### `roles` vacío en el token de una managed identity

- **Síntoma.** El app role se asignó y el token no lo trae.
- **Causa probable.** La caché del token de la managed identity, de hasta unas 24 horas.
- **Descartar antes.** Que la asignación use el `principalId` de la identidad y el **object ID del
  service principal de la API** como `resourceId`, no su `appId`.

### `AADSTS70021` en un pipeline con OIDC

- **Síntoma.** El login federado de GitHub Actions falla.
- **Causa.** Ninguna federated credential coincide con el token: `issuer`, `subject` o `audience`
  distintos, distinguiendo mayúsculas; típicamente, un job con `environment` contra una credencial de
  rama.
- **Corregir.** Alinear el `subject` con lo que emite el workflow ([`16` §5](16-orquestacion-y-cicd.md#5--github-actions-con-oidc)).

---

## 7. 🩺 Container Apps

| Síntoma | Causa | Comando que la confirma | Corrección |
|---|---|---|---|
| La revisión nueva no llega a estar lista; el tráfico sigue en la anterior | Imagen para otra arquitectura (`arm64`) | `docker image inspect --format '{{.Os}}/{{.Architecture}}'` | `docker build --platform linux/amd64` |
| La revisión no tira la imagen | La identidad del registry sin `AcrPull`, o registry en modo `rbac-abac` | `az role assignment list --assignee <principalId> --all`; `az acr show --query roleAssignmentMode` | `AcrPull` (o el rol ABAC) sobre el registry |
| Todas las revisiones dejan de responder a la vez | Cambio de **aplicación**: `--target-port` distinto del puerto del contenedor | `az containerapp logs show --type system` (probes fallando) | Target port igual al puerto real |
| La app sin ingress se queda en cero réplicas | Sin regla de escalado propia: la HTTP por defecto no la despierta | `az containerapp show --query properties.template.scale` | Regla de KEDA del origen de eventos |
| La revisión con una Key Vault reference no arranca | `identityref` que no es una identidad de la app, o sin `Key Vault Secrets User` | Logs de sistema; `az role assignment list` | Asignar la identidad y el rol |
| La revisión nueva no recibe tráfico, sin errores | Modo **multiple**: una revisión nueva nace sin peso | `az containerapp revision list --query "[].{n:name, w:properties.trafficWeight}"` | `az containerapp ingress traffic set` |

El detalle, con los fallos provocados, en [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) y
[`L07` §9](l07-datos-y-eventos-cosmos-db-y-service-bus.md#9--inv-projector-consume-y-escala).

---

## 8. 🩺 Red y DNS: cuando no hay error, solo silencio

### El FQDN resuelve a la IP pública

- **Síntoma.** Desde la VNet, la app no llega a un recurso con private endpoint, o recibe `403`.
- **Orden de revisión** ([`03` §11](03-conectividad-privada-y-dns.md#11--diagnóstico-el-nombre-resuelve-a-la-ip-pública)):
  `nslookup` del FQDN **público** desde dentro de la VNet; si da una IP pública, la Private DNS zone con el
  nombre exacto `privatelink.*`, su **VNet link** a esa VNet, el registro A del zone group, y el reenvío a
  `168.63.129.16` si la VNet usa un DNS propio.
- **Reproducido en** [`L04` §9](l04-red-vnet-nsg-private-endpoint-y-dns.md#9--la-resolución-que-falla-sin-el-vnet-link).

### La VM no sale a Internet

- **Orden de revisión** ([`02` §11](02-redes-vnet-nsg-y-enrutamiento.md#11--diagnóstico-de-conectividad)):
  IP flow verify (`az network watcher test-ip-flow`) para descartar el NSG; next hop y rutas efectivas para
  descartar una UDR; y la subnet: ¿es privada (`defaultOutboundAccess: false`) y sin NAT Gateway?
- **Reproducido en** [`L04` §5](l04-red-vnet-nsg-private-endpoint-y-dns.md#5--la-vm-que-no-contesta).

### Run Command no devuelve el resultado

- **Causa.** Run Command necesita salida por el puerto 443 hacia IPs públicas de Azure para devolver la
  salida; sin ella, el script puede ejecutarse y el resultado no volver. Un script enviado no se puede
  cancelar.
- **Corregir.** Un método de salida en la subnet y, si el NSG restringe la salida, una regla hacia el
  service tag `AzureCloud` por el 443.

> Regla de diagnóstico: IP flow verify dice `Allow` y la conexión falla → el NSG no es el problema.
> Mira las rutas efectivas y el método de salida de la subnet.

---

## 9. 🩺 Datos y mensajería

### Cosmos DB `429 Too Many Requests`

- **Causa.** Se superó el throughput provisionado. Si el consumo total es bajo, es una **hot partition**.
- **Confirmar.** Métrica `TotalRequests` filtrada por `StatusCode` 429 y consumo por partition key; la
  cabecera `x-ms-retry-after-ms` dice cuánto esperar.
- **Corregir.** Primero la partition key y el costo de las operaciones; subir RU solo si la carga está
  repartida ([`L07` §6](l07-datos-y-eventos-cosmos-db-y-service-bus.md#6--un-429-en-crudo-contra-la-api-rest)).

### Cosmos DB `412 Precondition Failed`

- **Causa.** Una escritura condicionada con `If-Match` y un `_etag` que ya no es el actual: otro escribió
  antes. Es la concurrencia optimista funcionando, no un fallo.
- **Corregir.** Releer y reintentar; en un consumidor de mensajes, dejar que el mensaje vuelva a la cola.

### Mensajes en la DLQ con `MaxDeliveryCountExceeded`

- **Causa.** El consumidor falla o **no liquida** el mensaje: el lock expira, vuelve, y al superar
  `MaxDeliveryCount` el broker lo aparta. Sin excepción en los logs, sospecha de un `complete` que nunca
  se llama o de un procesamiento más largo que el lock.
- **Confirmar.** `az servicebus topic subscription show --query countDetails`; el motivo, en el mensaje
  (Service Bus Explorer).
- **Corregir.** El bug del consumidor, y reenviar desde la DLQ lo que tenga arreglo ([`L07` §12](l07-datos-y-eventos-cosmos-db-y-service-bus.md#12--el-mensaje-envenenado-y-la-dlq)).

### El mismo movimiento aplicado dos veces

- **Causa.** At-least-once: una redelivery tras un lock expirado, que duplicate detection no ve.
- **Corregir.** Consumidor idempotente: el id del mensaje guardado en la misma escritura que el efecto
  ([`13` §10](13-mensajeria-y-eventos.md#10--at-least-once-idempotencia-y-outbox)).

---

## 10. 🩺 Observabilidad: el dato que no está

| Síntoma | Causa | Qué haces |
|---|---|---|
| No encuentras quién leyó un secreto ayer | No había diagnostic setting del vault: los resource logs no se guardaron | Nada hacia atrás; crearlo (y una policy `deployIfNotExists`) para el futuro |
| El Activity Log no está en el workspace | Falta el diagnostic setting **de la suscripción** | `az monitor diagnostic-settings subscription create`; antes, `az monitor activity-log list` |
| La consulta no devuelve lo de hace un minuto | Latencia de ingesta: minutos | Esperar antes de dudar |
| `count()` da menos peticiones que el balanceador | Sampling del agente Java (5 por segundo por defecto) | Métricas para conteos exactos |
| La telemetría no llega | Latencia, agente no cargado, o ingesta rechazada | Logs de consola de la app ([`L08` §7](l08-observabilidad-kql-y-auditoria.md#7--la-telemetría-que-no-llega)) |

---

## 11. 📋 Tabla de un vistazo

| Error o síntoma | Capa | Causa en una línea | Comando que la confirma |
|---|---|---|---|
| `MissingSubscriptionRegistration` | ARM | Provider sin registrar | `az provider show --query registrationState` |
| `AuthorizationFailed` | ARM | Rol, scope o principal equivocados, o propagación | `az role assignment list --assignee … --all` |
| `RoleAssignmentExists` | ARM | Misma asignación con otro nombre | `az role assignment list --scope …` |
| `RequestDisallowedByPolicy` | ARM | Policy `deny` | `az policy assignment list --scope …` |
| Scope bloqueado | ARM | Lock | `az lock list` |
| Deny assignment | ARM | Deployment Stack | `az rest … /denyAssignments` |
| `AuthorizationPermissionMismatch` | Storage | Sin rol de datos | `az role assignment list` |
| `KeyBasedAuthenticationNotPermitted` | Storage | Clave con Shared Key deshabilitado | `az storage account show --query allowSharedKeyAccess` |
| `AuthorizationFailure` | Storage | Red | `az storage account show --query publicNetworkAccess` |
| `ForbiddenByRbac` | Key Vault | Sin rol de datos del vault | `az role assignment list --scope <vault>` |
| Nombre del vault en conflicto | Key Vault | Soft-delete | `az keyvault list-deleted` |
| `401` aud / iss | Tu API | Audiencia o versión de token | Decodificar el token |
| `403` con `roles` | Tu API | Convertidor que ignora `roles` | Revisar el mapeo de authorities |
| Revisión que no arranca | Container Apps | Arquitectura, pull o secreto | `az containerapp logs show --type system` |
| FQDN a IP pública | Red | Sin VNet link o zona mal nombrada | `nslookup` desde la VNet |
| VM sin salida | Red | Subnet privada sin NAT | `az network vnet subnet show` |
| `429` | Cosmos DB | Throughput o hot partition | Métrica `TotalRequests` por `StatusCode` |
| `MaxDeliveryCountExceeded` | Service Bus | Consumidor que falla o no liquida | `countDetails` de la subscription |
| Log que no existe | Monitor | Sin diagnostic setting previo | `az monitor diagnostic-settings list --resource …` |

---

## 🧠 Preguntas rápidas

1. ¿Qué cuatro preguntas ordenan un diagnóstico en Azure y por qué en ese orden?
2. ¿Cómo sabes si un error nació en la CLI o en Azure?
3. ¿Qué tres piezas trae un `AuthorizationFailed` y qué compruebas con cada una?
4. ¿Por qué `--assignee-principal-type ServicePrincipal` evita un `PrincipalNotFound`?
5. Recibes `403` de Storage. ¿Cómo distingues un problema de permisos, de clave o de red?
6. ¿Por qué un rol de Azure RBAC sobre la cuenta no te da acceso a los datos de Cosmos DB?
7. No puedes recrear un Key Vault con el mismo nombre. ¿Qué compruebas y qué dos salidas tienes?
8. ¿Qué dos claims de un token miras ante un `401` de tu API, y qué te dice cada uno?
9. Una revisión nueva de Container Apps no recibe tráfico y no hay errores. ¿Qué pasa?
10. IP flow verify devuelve `Allow` y la conexión falla. ¿Qué miras después?
11. ¿Cuándo un `412` de Cosmos DB no es un error?
12. Te piden quién leyó un secreto ayer y no hay datos. ¿Por qué, y qué no puedes arreglar?

---

## 📚 Referencias oficiales

- Errores comunes de despliegue de ARM: https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/common-deployment-errors
- Errores de registro de resource providers: https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider
- Throttling de Resource Manager: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/request-limits-and-throttling
- Troubleshooting de Azure RBAC: https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting
- Role assignments en plantillas (`RoleAssignmentExists`): https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-template
- Deny assignments: https://learn.microsoft.com/en-us/azure/role-based-access-control/deny-assignments
- Resource locks: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources
- Errores 403 de Storage: https://learn.microsoft.com/en-us/troubleshoot/azure/azure-storage/blobs/authentication/storage-troubleshoot-403-errors
- Key Vault con Azure RBAC: https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide
- Soft-delete de Key Vault: https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview
- RBAC del data plane de Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-connect-role-based-access-control
- Códigos de estado de Cosmos DB: https://learn.microsoft.com/en-us/rest/api/cosmos-db/http-status-codes-for-cosmosdb
- Dead-letter queues de Service Bus: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues
- Access tokens (validación): https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens
- Workload identity federation (troubleshooting): https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation
- Health probes de Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/health-probes
- Configuración DNS de los private endpoints: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
- Run Command en VMs Linux: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/run-command
- Autenticación de Entra ID para Application Insights: https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-ad-authentication
- Borrar y recuperar un Log Analytics workspace: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/delete-workspace
