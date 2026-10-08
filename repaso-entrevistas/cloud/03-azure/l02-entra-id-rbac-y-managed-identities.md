# L02 — Entra ID, Azure RBAC y managed identities

> **Objetivo:** ver con tus propios ojos los dos planos de autorización de Azure: el Owner de la
> suscripción que crea una storage account y no puede escribir un blob en ella, un role assignment en
> el scope equivocado, la propagación, un token decodificado, dos user-assigned managed identities con
> sus roles de datos y un Key Vault con Azure RBAC.
> **Se asume leído:** [`09`](09-identidad-entra-id-y-managed-identities.md) (identidades y tokens),
> [`10`](10-autorizacion-rbac-policy-y-gobierno.md) (role assignments, `actions` y `dataActions`) y
> [`06` §8](06-almacenamiento-storage-accounts.md#8--acceso-claves-sas-y-entra-id) (claves, SAS y
> Entra ID). Complementa [`A01` §12](a01-az-de-supervivencia.md#12--tokens-a-mano-az-account-get-access-token).
> **Costo:** **$0.00** en la práctica. La storage account cobra $0.0184 por GB al mes en hot LRS y
> $0.05 por cada 10.000 escrituras; Key Vault Standard, $0.03 por cada 10.000 operaciones. El lab
> hace unas decenas de operaciones y guarda unos bytes.
> **Duración:** 2–3 horas, buena parte esperando propagaciones.
> **Prerrequisitos:** [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) terminado: perfil
> aislado, providers registrados, `inv-lab-rg` y el budget.
> **Qué queda encendido al terminar:** la storage account `invlab472913` con un contenedor, las
> identidades `inv-api-id` e `inv-projector-id`, el Key Vault `inv-lab-kv-472913` con un secreto, y
> los role assignments de este lab. Nada cobra por hora.
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [Qué vas a ver](#1--qué-vas-a-ver-dos-preguntas-dos-planos) ·
[Arranque](#2--arranque-de-la-sesión) · [Storage sin claves](#3--una-storage-account-sin-access-keys) ·
[Contenedor por ARM](#4--un-contenedor-por-el-control-plane) ·
[El Owner que no puede](#5--el-owner-que-no-puede-escribir-un-blob) ·
[Scope equivocado](#6--el-rol-en-el-scope-equivocado) ·
[Scope correcto](#7--el-scope-correcto-y-la-propagación) ·
[Token](#8--un-token-decodificado) · [Managed identities](#9--dos-user-assigned-managed-identities) ·
[Roles de las identidades](#10--roles-de-datos-para-las-identidades) ·
[Key Vault](#11--key-vault-con-azure-rbac) · [Teardown](#12--teardown-y-lo-que-queda-encendido) ·
[Checklist](#-checklist-de-salida) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Qué vas a ver: dos preguntas, dos planos

La mitad de los errores de permisos en Azure se deben a mezclar dos preguntas que el curso separa
desde [`09`](09-identidad-entra-id-y-managed-identities.md): **quién eres** (Entra ID emite un token
que lo dice) y **qué puedes hacer y dónde** (Azure RBAC lo decide con role assignments sobre un
scope). Y dentro de la segunda, otra frontera que casi nadie ve hasta que se tropieza con ella:

```text
control plane  →  management.azure.com       gestionar el recurso      Actions      (Owner: todas)
data plane     →  invlab472913.blob.core...  usar lo que contiene      DataActions  (Owner: ninguna)
```

Este lab pone esa frontera delante de ti en diez minutos: vas a crear una storage account siendo
Owner y **no vas a poder escribir un blob en ella**. Después vas a arreglarlo mal, en el scope
equivocado, y bien, esperando la propagación.

> 🧠 **Modelo mental.** Owner es el dueño del edificio, no de lo que hay en los cajones. Puede
> construir, derribar y dar llaves a quien quiera —incluso a sí mismo—, pero hasta que se da una llave
> no abre un cajón.

La doctrina de reparto de [`L00` §2](l00-idea-lab-practico.md#2--la-doctrina-de-reparto-qué-se-paga-y-qué-se-practica-en-local)
explica por qué esto no se practica en local: **Azurite no evalúa RBAC**. Acepta claves y SAS, no
tiene roles que denieguen, y el `403` que vas a ver hoy no existe en el emulador.

---

## 2. 🧱 Arranque de la sesión

Cada lab empieza igual, y conviene no saltárselo:

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
SUB=$(az account show --query id --output tsv)
ME=$(az ad signed-in-user show --query id --output tsv)
echo "$SUB $ME"
```

- La primera línea es el perfil aislado de [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md#3--el-perfil-aislado-y-el-login).
- `az ad signed-in-user show` consulta **Microsoft Graph**, no ARM: devuelve tu usuario de Entra ID.
  Su `id` es tu **object ID**, el identificador que reciben los role assignments. No es tu correo ni
  tu nombre de usuario.

```text
[PENDIENTE DE CORRIDA] Dos GUIDs: el id de la suscripción (anonimizado como
11112222-3333-4444-5555-666677778888) y el object ID de tu usuario.
```

---

## 3. 🧱 Una storage account sin access keys

**Teardown antes que el despliegue.** La cuenta muere con `az group delete` en
[`L09`](l09-costos-y-destruccion-verificada.md). Una storage account borrada se puede recuperar
durante 14 días **si nadie ha creado otra con el mismo nombre**: no retiene el nombre, así que no
bloquea recrearla. Los blobs se van con ella.

```bash
az storage account create \
  --name invlab472913 \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --tags project=inv-lab env=lab
```

- `--name invlab472913` admite solo de 3 a 24 minúsculas y dígitos, sin guiones, y es **único en todo
  Azure** porque se convierte en el host `invlab472913.blob.core.windows.net`. Si el nombre ya está
  tomado por otra persona, cambia el sufijo y **anótalo**: el resto de la serie lo usa.
- `--sku Standard_LRS` guarda tres copias en un solo datacenter: la redundancia más barata, que no
  sobrevive a la caída de una zona ([`06` §3](06-almacenamiento-storage-accounts.md#3--redundancia)).
- `--kind StorageV2` es el tipo de cuenta de propósito general actual.
- `--min-tls-version TLS1_2` rechaza clientes con TLS antiguo.
- `--allow-blob-public-access false` impide marcar un contenedor como público, aunque alguien lo
  intente después.
- `--allow-shared-key-access false` es el flag del lab. **Sin él, la cuenta acepta sus dos access
  keys, y cada una da control total sobre todos los datos**, sin role assignment y sin auditoría por
  identidad. Con `false`, solo se entra con un token de Entra ID y un rol de datos.

```text
[PENDIENTE DE CORRIDA] JSON de la cuenta con provisioningState Succeeded, allowSharedKeyAccess
false, allowBlobPublicAccess false, minimumTlsVersion TLS1_2 y primaryEndpoints.blob
https://invlab472913.blob.core.windows.net/.
```

Guarda su resource ID, que vas a usar como scope:

```bash
SA_ID=$(az storage account show --name invlab472913 --resource-group inv-lab-rg --query id --output tsv)
echo "$SA_ID"
```

```text
[PENDIENTE DE CORRIDA] /subscriptions/11112222-3333-4444-5555-666677778888/resourceGroups/inv-lab-rg/providers/Microsoft.Storage/storageAccounts/invlab472913
```

---

## 4. 🧱 Un contenedor por el control plane

Hay dos formas de crear un contenedor de blobs, y la diferencia es la lección entera del lab:

| Comando | Habla con | Lo autoriza | ¿Owner puede? |
|---|---|---|---|
| `az storage container-rm create` | ARM, `management.azure.com` | `Actions` del rol | Sí |
| `az storage container create --auth-mode login` | Data plane, `invlab472913.blob.core.windows.net` | `DataActions` del rol | No, sin rol de datos |

Crea dos contenedores por el control plane: el que usa el lab y otro que sirve para equivocarse de
scope en la sección 6.

```bash
for c in events-archive scratch; do
  az storage container-rm create \
    --storage-account invlab472913 \
    --resource-group inv-lab-rg \
    --name "$c" \
    --public-access off \
    --query "{name:name, publicAccess:publicAccess}" --output table
done
```

- `container-rm` significa *resource manager*: el contenedor se crea como subrecurso de ARM
  (`…/blobServices/default/containers/events-archive`), con los permisos de control plane que tienes
  como Owner.
- `--public-access off` es explícito aunque la cuenta ya lo prohíba.
- El nombre de un contenedor admite minúsculas, dígitos y guiones.

```text
[PENDIENTE DE CORRIDA] Dos tablas de una fila: events-archive y scratch, ambas con publicAccess None.
```

---

## 5. 🩺 El Owner que no puede escribir un blob

Ahora usa el contenedor, que es una operación de datos:

```bash
az storage blob upload \
  --account-name invlab472913 \
  --container-name events-archive \
  --name probe.txt \
  --data "hola desde L02" \
  --auth-mode login
```

- `--auth-mode login` le dice a la CLI que se autentique en el data plane con **tu token de Entra
  ID**. Es la única forma que acepta una cuenta con Shared Key deshabilitado.
- `--data` sube una cadena como contenido del blob, sin archivo local.

```text
[PENDIENTE DE CORRIDA] Un 403 del data plane con el código AuthorizationPermissionMismatch y el
mensaje "This request isn't authorized to perform this operation using this permission."
```

Eres Owner de la suscripción y la operación se deniega. Tres cosas del síntoma:

- **El error no viene de ARM.** No es un `AuthorizationFailed` con tu object ID, la acción y el scope:
  es un `403` de Storage con su propio código. Los errores del data plane los pone cada servicio.
- **Tu token es válido.** Entra ID sabe quién eres; lo que falta es una `DataAction` de escritura de
  blobs, que Owner no tiene ([`10` §3](10-autorizacion-rbac-policy-y-gobierno.md#3--role-definitions-actions-y-dataactions)).
- **No es un problema de red.** Si lo fuera, el código sería `AuthorizationFailure`, el que aparece
  cuando el firewall de la cuenta o el acceso público deshabilitado cortan la petición; lo verás en
  [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md).

Ahora el atajo que un Owner tiene en una cuenta **normal**, y que este lab cortó. Sin
`--auth-mode login`, la CLI intenta autenticarse con la access key: primero la pide por ARM y después
firma la petición con ella.

```bash
az storage blob upload \
  --account-name invlab472913 \
  --container-name events-archive \
  --name probe.txt \
  --data "hola desde L02" \
  --auth-mode key
```

- `--auth-mode key` es el modo heredado, y también lo que hace la CLI si omites `--auth-mode`: llama
  a `listKeys` en el control plane, que tu rol de Owner **sí** permite, y firma la petición de datos
  con la clave.

```text
[PENDIENTE DE CORRIDA] Un 403 con el código KeyBasedAuthenticationNotPermitted y el mensaje
"Key based authentication is not permitted on this storage account."
```

> ⚠️ **Por eso importa `--allow-shared-key-access false`.** En una cuenta con claves habilitadas,
> este segundo comando **habría funcionado**: cualquiera con `listKeys` —Owner, Contributor, Storage
> Account Contributor— entra a todos los datos sin rol de datos y sin dejar su identidad en los logs
> de acceso. Deshabilitar Shared Key convierte el rol de datos en la única puerta.

---

## 6. 🩺 El rol en el scope equivocado

El error típico al arreglarlo es dar el rol correcto en el sitio incorrecto. Provócalo: asígnate
`Storage Blob Data Contributor` **en el contenedor `scratch`**, no en `events-archive`.

```bash
az role assignment create \
  --assignee-object-id "$ME" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$SA_ID/blobServices/default/containers/scratch" \
  --description "L02: scope equivocado a proposito"
```

- `--assignee-object-id` recibe tu object ID. Con `--assignee` a secas la CLI aceptaría también un
  correo o un nombre y lo buscaría en Graph; con el object ID no hay ambigüedad.
- `--assignee-principal-type User` le dice a ARM qué tipo de principal es, sin consultar el
  directorio.
- `--role "Storage Blob Data Contributor"` concede leer, escribir y borrar blobs: son `DataActions`.
- `--scope` es el **resource ID del contenedor**: el ID de la cuenta más
  `/blobServices/default/containers/scratch`. Un rol de datos de Storage se puede asignar en la
  cuenta o en un contenedor concreto.
- `--description` deja constancia de por qué existe la asignación. En un lab es un recordatorio; en
  producción, lo que lee un auditor.

```text
[PENDIENTE DE CORRIDA] JSON del role assignment con principalType User, el roleDefinitionId de
Storage Blob Data Contributor y scope terminado en /containers/scratch.
```

Espera un par de minutos y repite la subida a `events-archive`:

```bash
az storage blob upload --account-name invlab472913 --container-name events-archive \
  --name probe.txt --data "hola desde L02" --auth-mode login
```

```text
[PENDIENTE DE CORRIDA] El mismo 403 AuthorizationPermissionMismatch de la sección 5.
```

Y la prueba de que el rol sí existe, pero en otro sitio:

```bash
az storage blob upload --account-name invlab472913 --container-name scratch \
  --name probe.txt --data "hola desde L02" --auth-mode login
```

```text
[PENDIENTE DE CORRIDA] La subida funciona (JSON con etag y lastModified), o el mismo 403 si el
rol aún no propagó; en ese caso, espera y repite.
```

> 🩺 **Diagnóstico.** Ante un permiso que "tienes pero no funciona", lista tus asignaciones **con su
> scope**: `az role assignment list --assignee "$ME" --all --query "[].{role:roleDefinitionName, scope:scope}" --output table`.
> `--all` busca en todos los scopes de la suscripción, no solo en el nivel de suscripción. El error más
> común no es el rol equivocado: es el scope equivocado.

```text
[PENDIENTE DE CORRIDA] Una fila con Owner en /subscriptions/11112222-... y otra con Storage Blob
Data Contributor en .../containers/scratch.
```

---

## 7. 🧱 El scope correcto, y la propagación

Ahora bien: el rol en el contenedor que usas. Y la prueba **inmediata**, sin esperar, para ver la
propagación:

```bash
az role assignment create \
  --assignee-object-id "$ME" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$SA_ID/blobServices/default/containers/events-archive" \
  --description "L02: escritura del lab en events-archive"

az storage blob upload --account-name invlab472913 --container-name events-archive \
  --name probe.txt --data "hola desde L02" --auth-mode login
```

```text
[PENDIENTE DE CORRIDA] Lo más probable, el 403 otra vez: el role assignment existe en ARM pero
todavía no surtió efecto en el data plane.
```

Es la propagación de [`10` §7](10-autorizacion-rbac-policy-y-gobierno.md#7--propagación-caché-y-límites):
un role assignment **puede tardar hasta 10 minutos** en surtir efecto. Espera y repite, con un bucle
que no te haga adivinar:

```bash
for i in $(seq 1 10); do
  az storage blob upload --account-name invlab472913 --container-name events-archive \
    --name probe.txt --data "hola desde L02" --auth-mode login --overwrite \
    --only-show-errors --output none && { echo "OK en el intento $i"; break; }
  sleep 60
done
```

- `--overwrite` permite repetir la subida sobre un blob que ya existe; sin él, el segundo intento que
  tenga éxito fallaría porque el blob está.
- `--only-show-errors --output none` deja solo el error de cada intento fallido y nada en el que
  funciona.
- El bucle prueba una vez por minuto durante diez minutos, el máximo documentado.

```text
[PENDIENTE DE CORRIDA] Uno o varios 403 y después "OK en el intento N". Anota N: es tu medida real
de la propagación.
```

Comprueba que el blob está y léelo:

```bash
az storage blob list --account-name invlab472913 --container-name events-archive \
  --auth-mode login --query "[].{name:name, size:properties.contentLength}" --output table
az storage blob download --account-name invlab472913 --container-name events-archive \
  --name probe.txt --auth-mode login --file /dev/stdout --only-show-errors
```

```text
[PENDIENTE DE CORRIDA] Una fila con probe.txt y su tamaño en bytes, y el contenido "hola desde L02".
```

Limpia la asignación equivocada, que no tiene por qué seguir existiendo:

```bash
az role assignment delete --assignee "$ME" --role "Storage Blob Data Contributor" \
  --scope "$SA_ID/blobServices/default/containers/scratch"
```

- `az role assignment delete` borra las asignaciones que coinciden con los tres filtros. Sin `--scope`
  borraría las de ese rol en **todos** los scopes, incluida la buena.

> Nunca respondas: "el role assignment surte efecto al instante". Mejor: "puede tardar hasta diez
> minutos por la caché de ARM, y un token ya emitido sigue valiendo hasta que caduca; por eso un
> script de despliegue espera y reintenta tras asignar roles".

---

## 8. 🧱 Un token decodificado

Todo lo anterior ocurrió con un token que no viste. Míralo, como en
[`A01` §12](a01-az-de-supervivencia.md#12--tokens-a-mano-az-account-get-access-token): uno para ARM y
otro para Storage.

```bash
jwt() {
  cut -d. -f2 | python3 -c "import sys,base64,json; p=sys.stdin.read().strip(); p+='='*(-len(p)%4); d=json.loads(base64.urlsafe_b64decode(p)); print(json.dumps({k:d.get(k) for k in ('aud','iss','oid','scp','roles','exp')}, indent=2))"
}
az account get-access-token --query accessToken --output tsv | jwt
az account get-access-token --resource https://storage.azure.com/ --query accessToken --output tsv | jwt
```

- `jwt()` es una función de la shell que decodifica el payload del token y muestra solo seis claims.
  El token entero **no se imprime nunca**: es una credencial al portador.
- El primer comando, sin `--resource`, pide un token para ARM. El segundo, para el data plane de
  Storage.

```text
[PENDIENTE DE CORRIDA] Dos JSON con el mismo "oid" (tu object ID) e "iss" (tu tenant). El "aud"
cambia: https://management.core.windows.net/ (o https://management.azure.com/) en el primero,
https://storage.azure.com en el segundo. "roles" es null en ambos: tus role assignments de Azure
RBAC no viajan en el token.
```

Tres lecturas, y la tercera sorprende:

- **Mismo `oid`, distinto `aud`.** Eres la misma identidad, pero cada token vale para **una**
  audiencia. El de ARM no sirve para Storage aunque la firma sea válida
  ([`09` §7](09-identidad-entra-id-y-managed-identities.md#7--tokens)).
- **`scp` trae `user_impersonation`**: la CLI actúa en tu nombre, con un permiso delegado.
- **Tus roles de Azure RBAC no están en el token.** El token dice quién eres; ARM y Storage evalúan
  qué puedes hacer contra los role assignments, con las cachés que explican la espera de la sección 7.
  El claim `roles` es para los app roles de una API, que verás en [`L06`](l06-identidad-de-aplicaciones-api-protegida.md).

---

## 9. 🧱 Dos user-assigned managed identities

Las dos identidades del sistema, una por servicio ([`L00` §5](l00-idea-lab-practico.md#5--el-sistema-que-vas-a-construir)).
Se crean **antes** que las apps a propósito: una user-assigned existe por sí misma, así que sus roles
se asignan hoy y ya estarán propagados en [`L05`](l05-container-apps-revisiones-trafico-y-escala.md), cuando la app nazca con ellos
([`09` §5](09-identidad-entra-id-y-managed-identities.md#5--managed-identities)).

**Teardown antes que el despliegue.** Una user-assigned identity vive en `inv-lab-rg` y muere con él;
al borrarse, se borra su service principal. Los role assignments cuyo scope está dentro del grupo se
van con sus recursos; uno en un scope superior quedaría como *Identity not found* y habría que
borrarlo a mano ([`L09`](l09-costos-y-destruccion-verificada.md) lo comprueba).

```bash
for id in inv-api-id inv-projector-id; do
  az identity create --name "$id" --resource-group inv-lab-rg --location eastus2 \
    --tags project=inv-lab env=lab \
    --query "{name:name, clientId:clientId, principalId:principalId}" --output table
done
```

- El nombre de una user-assigned identity admite de 3 a 128 caracteres: letras, dígitos, guiones y
  guiones bajos, empezando por letra o dígito.
- La respuesta completa trae tres identificadores, y cada uno sirve para una cosa distinta:

```text
id           /subscriptions/…/providers/Microsoft.ManagedIdentity/userAssignedIdentities/inv-api-id
             → el resource ID: para ASOCIARLA a un recurso (Container Apps, en L05)
clientId     → para que el CÓDIGO elija esta identidad (AZURE_CLIENT_ID, managedIdentityClientId)
principalId  → el object ID de su service principal: el que RECIBE los role assignments
```

```text
[PENDIENTE DE CORRIDA] Dos tablas de una fila con el nombre, el clientId y el principalId (GUIDs
distintos) de cada identidad.
```

Guárdalos:

```bash
API_PID=$(az identity show --name inv-api-id --resource-group inv-lab-rg --query principalId --output tsv)
PROJ_PID=$(az identity show --name inv-projector-id --resource-group inv-lab-rg --query principalId --output tsv)
```

> ⚠️ **Una managed identity no se puede usar desde tu portátil.** Su token solo se obtiene del
> endpoint de identidad del host de Azure donde corre el recurso al que está asociada. Hoy le das
> roles; **quien los ejerce es `inv-api` en [`L05`](l05-container-apps-revisiones-trafico-y-escala.md)**, el primer lab con un
> host de Azure. Es la pregunta 7 de `09`.

---

## 10. 🧱 Roles de datos para las identidades

`inv-api-id` recibe lectura y escritura de blobs en la cuenta, exactamente el role assignment de
[`10` §6](10-autorizacion-rbac-policy-y-gobierno.md#6--asignar-un-rol-y-diagnosticar-un-authorizationfailed):

```bash
az role assignment create \
  --assignee-object-id "$API_PID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$SA_ID" \
  --description "L02: inv-api escribe blobs en invlab472913"
```

- `--assignee-object-id "$API_PID"` es el **`principalId`**. Pasar el `clientId` es el error más
  frecuente: no hay ningún principal con ese object ID.
- `--assignee-principal-type ServicePrincipal` evita la consulta al directorio y el `PrincipalNotFound`
  cuando la identidad se acaba de crear y aún no se replicó en Entra ID.
- `--scope "$SA_ID"` es la cuenta, no el grupo: el permiso vale para esta cuenta y nada más.

```text
[PENDIENTE DE CORRIDA] JSON del role assignment con principalType ServicePrincipal y scope
terminado en /storageAccounts/invlab472913.
```

`inv-projector-id` no recibe nada en Storage: su trabajo es leer de Service Bus y escribir en Cosmos
DB, y sus roles llegan en [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md). Privilegio mínimo es también **no** dar lo que no se usa.

Comprueba lo que tiene cada una:

```bash
for pid in "$API_PID" "$PROJ_PID"; do
  az role assignment list --assignee "$pid" --all \
    --query "[].{role:roleDefinitionName, scope:scope}" --output table
done
```

```text
[PENDIENTE DE CORRIDA] Para inv-api-id, una fila (Storage Blob Data Contributor en la cuenta);
tras la sección 11, dos. Para inv-projector-id, vacío.
```

> 💡 **Truco.** Ni una identidad del lab tiene un rol de control plane —ni Contributor ni Reader—.
> Una app no necesita gestionar los recursos que usa, solo usarlos. Si alguna vez te ves dándole
> `Contributor` a una managed identity "para que funcione", revisa qué `DataAction` le falta de
> verdad.

---

## 11. 🧱 Key Vault con Azure RBAC

**Teardown antes que el despliegue, y aquí importa más que en ningún otro recurso de la serie.** Un
Key Vault borrado **queda soft-deleted** 7 días —la retención que se fija abajo— y durante ese tiempo
**su nombre no se puede reutilizar**. `az group delete` no lo purga. El teardown completo es
`az keyvault delete` (o el borrado del grupo) **más** `az keyvault purge --name inv-lab-kv-472913
--location eastus2`, y se comprueba con `az keyvault list-deleted`. [`L09`](l09-costos-y-destruccion-verificada.md) lo hace; si abandonas la
serie antes, hazlo tú. El vault se crea **sin purge protection**, porque con ella el purge no existe
([`11` §5](11-secretos-cifrado-y-key-vault.md#5--soft-delete-y-purge-protection)).

El vault, con el mismo comando de [`11` §4](11-secretos-cifrado-y-key-vault.md#4--crear-el-vault-del-laboratorio):

```bash
az keyvault create \
  --name inv-lab-kv-472913 \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --sku standard \
  --enable-rbac-authorization true \
  --retention-days 7 \
  --tags project=inv-lab env=lab
KV_ID=$(az keyvault show --name inv-lab-kv-472913 --query id --output tsv)
```

- `--name` admite de 3 a 24 caracteres, letras, dígitos y guiones, empezando por letra, sin guiones
  consecutivos, y es **único en todo Azure**: forma `https://inv-lab-kv-472913.vault.azure.net`.
- `--enable-rbac-authorization true` hace que el data plane del vault se autorice con Azure RBAC, no
  con access policies. Es el valor por defecto, pero el lab depende de él.
- `--retention-days 7` es el mínimo, y **solo se fija al crear**.
- Sin `--enable-purge-protection`, a propósito.

```text
[PENDIENTE DE CORRIDA] JSON del vault con properties.enableRbacAuthorization true,
enableSoftDelete true, softDeleteRetentionInDays 7, enablePurgeProtection null y vaultUri
https://inv-lab-kv-472913.vault.azure.net/.
```

Ahora el mismo error de la sección 5, en otro servicio. Intenta crear un secreto sin rol de datos:

```bash
az keyvault secret set --vault-name inv-lab-kv-472913 --name partner-api-key \
  --value "replace-me" --expires "2026-12-31T00:00:00Z"
```

```text
[PENDIENTE DE CORRIDA] Un 403 con el código ForbiddenByRbac: el mensaje trae el Caller (tu
object ID), la acción de datos que faltó y el scope del vault.
```

El `ForbiddenByRbac` de Key Vault es más generoso que el `403` de Storage: trae el **caller**, la
**acción** y el **vault**, las mismas tres piezas que un `AuthorizationFailed` de ARM. Asígnate el rol
y repite, con el mismo bucle de propagación:

```bash
az role assignment create \
  --assignee-object-id "$ME" \
  --assignee-principal-type User \
  --role "Key Vault Secrets Officer" \
  --scope "$KV_ID" \
  --description "L02: gestion de secretos del lab"

for i in $(seq 1 10); do
  az keyvault secret set --vault-name inv-lab-kv-472913 --name partner-api-key \
    --value "replace-me" --expires "2026-12-31T00:00:00Z" \
    --only-show-errors --output none && { echo "OK en el intento $i"; break; }
  sleep 60
done
```

- `Key Vault Secrets Officer` permite crear, leer, actualizar y borrar secretos. Es el rol de quien
  administra; las apps reciben menos.
- `--expires` pone fecha de expiración. Es **informativa**: un `get` sigue devolviendo un secreto
  caducado, pero la expiración dispara eventos y aparece en las recomendaciones de seguridad
  ([`11` §8](11-secretos-cifrado-y-key-vault.md#8--rotación-y-expiración)).

```text
[PENDIENTE DE CORRIDA] Uno o varios 403 y después "OK en el intento N".
```

Léelo, y dale a `inv-api-id` **solo lectura**:

```bash
az keyvault secret show --vault-name inv-lab-kv-472913 --name partner-api-key \
  --query "{name:name, enabled:attributes.enabled, expires:attributes.expires}" --output table

az role assignment create \
  --assignee-object-id "$API_PID" \
  --assignee-principal-type ServicePrincipal \
  --role "Key Vault Secrets User" \
  --scope "$KV_ID" \
  --description "L02: inv-api lee secretos del vault del lab"
```

- El `--query` evita imprimir `value`. **No se imprime un secreto en la terminal**, ni en un lab: queda
  en el historial de la shell y en las capturas.
- `Key Vault Secrets User` solo lee secretos. `inv-api` lo ejercerá en [`L05`](l05-container-apps-revisiones-trafico-y-escala.md), cuando lea este secreto
  como Key Vault reference de Container Apps ([`11` §7](11-secretos-cifrado-y-key-vault.md#7--consumir-secretos-desde-la-aplicación)).

```text
[PENDIENTE DE CORRIDA] Una fila con partner-api-key, enabled True y la fecha de expiración.
```

---

## 12. 🧪 Teardown, y lo que queda encendido

Este lab deja casi todo encendido a propósito: los labs siguientes lo usan. La tabla dice qué cobra,
qué sobrevive a qué y quién lo destruye.

| Recurso | ¿Cobra? | Sobrevive a `az group delete` | Quién lo destruye |
|---|---|---|---|
| `invlab472913` y su blob | Céntimos por GB y por operación | No (recuperable 14 días, sin retener el nombre) | [`L09`](l09-costos-y-destruccion-verificada.md) |
| Contenedores `events-archive` y `scratch` | No | No | Con la cuenta |
| `inv-api-id`, `inv-projector-id` | No | No | [`L09`](l09-costos-y-destruccion-verificada.md) |
| Role assignments con scope en el grupo | No | No | Con su scope |
| `inv-lab-kv-472913` | $0.03 por 10.000 operaciones | **Sí: soft-deleted 7 días, nombre retenido** | [`L09`](l09-costos-y-destruccion-verificada.md), con `az keyvault purge` |
| Secreto `partner-api-key` | Incluido en las operaciones | Con el vault | Con el vault |

Verificación de lo que hay:

```bash
az resource list --resource-group inv-lab-rg --query "[].{name:name, type:type}" --output table
```

```text
[PENDIENTE DE CORRIDA] Cinco recursos: inv-lab-ag, invlab472913, inv-api-id, inv-projector-id e
inv-lab-kv-472913.
```

> ⚠️ Tus propios role assignments de este lab —`Storage Blob Data Contributor` en `events-archive` y
> `Key Vault Secrets Officer` en el vault— tienen scope **dentro** de `inv-lab-rg` y se van con sus
> recursos. Si en algún momento asignaste un rol en el scope de la suscripción "para probar", ese no
> se va con nada: bórralo ahora con `az role assignment delete`.

---

## 📋 Checklist de salida

- [ ] `az storage account show --name invlab472913 --query allowSharedKeyAccess` devuelve `false`.
- [ ] Viste el `403 AuthorizationPermissionMismatch` siendo Owner y el `KeyBasedAuthenticationNotPermitted` con `--auth-mode key`, y sabes qué significa cada uno.
- [ ] Provocaste el rol en el scope equivocado (`scratch`) y lo borraste después.
- [ ] Anotaste en cuántos minutos propagó tu role assignment.
- [ ] `az storage blob list --auth-mode login` en `events-archive` devuelve `probe.txt`.
- [ ] Decodificaste dos tokens y viste el mismo `oid` con distinto `aud`.
- [ ] `az identity list --resource-group inv-lab-rg` devuelve `inv-api-id` e `inv-projector-id`, y sabes para qué sirve cada uno de sus tres identificadores.
- [ ] `inv-api-id` tiene exactamente dos role assignments (Storage Blob Data Contributor y Key Vault Secrets User); `inv-projector-id`, ninguno.
- [ ] Viste el `ForbiddenByRbac` de Key Vault y el secreto `partner-api-key` existe con fecha de expiración.

## 🏁 La señal de que quedó bien

`az role assignment list --assignee "$API_PID" --all` devuelve dos roles de datos y ninguno de control
plane, `az role assignment list --assignee "$ME" --all` ya no muestra nada sobre `scratch`, y puedes
explicar por qué siendo Owner no podías escribir un blob.

---

## 🧠 Preguntas rápidas

1. ¿Por qué el Owner de la suscripción recibe `403` al subir un blob con `--auth-mode login`?
2. ¿Qué hace la CLI si omites `--auth-mode` en un comando de blobs, y por qué en este lab también falla?
3. ¿Qué diferencia hay entre `az storage container-rm create` y `az storage container create --auth-mode login`?
4. ¿Qué te dice cada uno de estos códigos de Storage: `AuthorizationPermissionMismatch`, `KeyBasedAuthenticationNotPermitted` y `AuthorizationFailure`?
5. Tienes `Storage Blob Data Contributor` y sigue fallando la subida. ¿Qué comando corres primero y qué miras en su salida?
6. ¿Cuál es el resource ID de un contenedor y por qué es un scope válido para un rol de datos?
7. Asignaste el rol hace un minuto y la operación sigue fallando. ¿Qué haces y cuánto esperas como máximo?
8. ¿Por qué un token para ARM no sirve para el data plane de Storage, y qué claim lo muestra?
9. ¿Por qué tus role assignments de Azure RBAC no aparecen en el claim `roles` de tu token?
10. ¿Para qué sirven el `id`, el `clientId` y el `principalId` de una user-assigned identity?
11. ¿Por qué las identidades se crean en `L02` si las apps no existen hasta `L05`?
12. ¿Por qué no puedes comprobar desde tu portátil que `inv-api-id` puede leer el secreto?
13. ¿Qué información trae un `ForbiddenByRbac` de Key Vault que no trae el `403` de Storage?
14. ¿Qué sobrevive a `az group delete` de lo que creó este lab y cómo se elimina del todo?

---

## 📚 Referencias oficiales

- Autorizar el acceso a blobs con la CLI (`--auth-mode`): https://learn.microsoft.com/en-us/azure/storage/blobs/authorize-data-operations-cli
- Impedir la autorización con Shared Key: https://learn.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent
- Errores 403 de Storage y sus códigos: https://learn.microsoft.com/en-us/troubleshoot/azure/azure-storage/blobs/authentication/storage-troubleshoot-403-errors
- Recuperar una storage account borrada: https://learn.microsoft.com/en-us/azure/storage/common/storage-account-recover
- Referencia de `az storage account`: https://learn.microsoft.com/en-us/cli/azure/storage/account
- Referencia de `az storage container-rm`: https://learn.microsoft.com/en-us/cli/azure/storage/container-rm
- Referencia de `az storage blob`: https://learn.microsoft.com/en-us/cli/azure/storage/blob
- Asignar roles con la CLI: https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli
- Referencia de `az role assignment`: https://learn.microsoft.com/en-us/cli/azure/role/assignment
- Roles integrados de Azure: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
- Troubleshooting de Azure RBAC (propagación): https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting
- Managed identities: https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview
- Referencia de `az identity`: https://learn.microsoft.com/en-us/cli/azure/identity
- Access tokens de la plataforma de identidad: https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens
- Key Vault con Azure RBAC: https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide
- Soft-delete de Key Vault: https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview
- Referencia de `az keyvault`: https://learn.microsoft.com/en-us/cli/azure/keyvault
- Precios de Storage (blobs): https://azure.microsoft.com/en-us/pricing/details/storage/blobs/
- Precios de Key Vault: https://azure.microsoft.com/en-us/pricing/details/key-vault/
