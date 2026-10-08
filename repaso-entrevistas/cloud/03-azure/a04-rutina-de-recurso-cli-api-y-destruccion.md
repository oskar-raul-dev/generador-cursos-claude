# A04 — Rutina de recurso: CLI, API y destrucción

> **Objetivo:** aprender a crear, inspeccionar, modificar, destruir y verificar **un recurso
> cualquiera** desde cero, primero con `az`, después con la API que hay debajo y por último con el Azure
> SDK for Java. Es la rutina de [`L00` §7.4](l00-idea-lab-practico.md#74-la-rutina-de-recurso-cli-api-y-destrucción),
> aplicada entera a una storage account.
> **Se asume leído:** [`A01`](a01-az-de-supervivencia.md) (`--debug`, `az rest`, tokens) y
> [`01` §9–§10](01-infraestructura-global-y-resource-manager.md#9--azure-resource-manager-y-el-resource-id)
> (resource ID, control plane y data plane).
> **Costo:** **$0.00** en la práctica. Una storage account Standard LRS con un blob de pocos bytes, durante
> una hora: fracciones de centavo ($0.0184 por GB al mes y $0.05 por cada 10.000 escrituras en
> `eastus2`). El resource group y el role assignment no cobran.
> **Duración:** 1–2 horas por vuelta.
> **Prerrequisitos:** sesión abierta en el perfil aislado ([`L01` §3](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md#3--el-perfil-aislado-y-el-login)),
> y para el paso 6, JDK 21 y Maven 3.9.
> **Qué queda encendido al terminar:** nada. La rutina se abre y se cierra en `inv-drill-rg`.
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026. Azure SDK BOM **1.3.8** (`azure-resourcemanager` 2.63.0,
> `azure-storage-blob` 12.35.0, `azure-identity` 1.18.4).

**Salto rápido:** [Por qué esta rutina](#1--por-qué-esta-rutina-y-no-un-tutorial-más) ·
[La forma fija](#2--la-forma-fija-seis-pasos) · [El recurso](#3--por-qué-una-storage-account) ·
[Crear](#4--paso-1-crear) · [Inspeccionar](#5--paso-2-inspeccionar) · [Modificar](#6--paso-3-modificar-y-encontrar-la-frontera-inmutable) ·
[Destruir](#7--paso-4-destruir) · [Verificar](#8--paso-5-verificar-qué-quedó) ·
[Desde el SDK](#9--paso-6-lo-mismo-desde-el-sdk-de-java) · [Lo que enseña el SDK](#10--tres-lecciones-que-solo-da-el-paso-6) ·
[El entregable](#11--el-entregable-no-es-el-recurso) · [Checklist](#-checklist-de-salida) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Por qué esta rutina, y no un tutorial más

Los labs recorren un sistema. Esta rutina entrena otra cosa: la capacidad de enfrentarte a **cualquier**
servicio que no conoces y saber, en una hora, cómo se crea, qué propiedades tiene de verdad, cuáles se
pueden cambiar, cómo se destruye y qué deja al destruirlo. Es lo que se pregunta con la forma *"¿cómo
harías X en Azure?"*, y lo que diferencia a quien recita la documentación de quien la ha usado.

Y lo hace en tres niveles, para que el tercero deje de ser magia:

```text
az storage account create ...        ← la comodidad
      │  --debug
      ▼
PUT https://management.azure.com/subscriptions/…/storageAccounts/…?api-version=…   ← lo que pasa de verdad
      │  la misma llamada, con un cliente tipado
      ▼
azure.storageAccounts().define(…).create()                                         ← tu código
```

---

## 2. 🧱 La forma fija: seis pasos

La forma es la misma para cualquier servicio, y se repite idéntica:

```text
1. Crear         az … create                      + --debug: método, URL, api-version
2. Inspeccionar  az … show --output json          + --query; y lo mismo con az rest
3. Modificar     az … update                      ¿qué es mutable y qué obliga a recrear?
4. Destruir      az … delete                      ¿qué borra de verdad?
5. Verificar     az … list / list-deleted         ¿qué quedó vivo, soft-deleted o huérfano?
6. Repetir 1–5 desde el Azure SDK for Java
```

Las reglas del curso para cada vuelta: el costo se declara antes, el teardown se escribe junto al
recurso, y **lo que sobrevive a la sesión es el apunte**, no el recurso.

---

## 3. 🧱 Por qué una storage account

Para la primera vuelta conviene un recurso que enseñe mucho y cueste casi nada. La storage account lo
cumple:

- **Tiene control plane y data plane separados**, con hosts distintos: se gestiona en
  `management.azure.com` y se usa en `<cuenta>.blob.core.windows.net`. Es el ejemplo exacto de
  [`L00` §7.4](l00-idea-lab-practico.md#74-la-rutina-de-recurso-cli-api-y-destrucción).
- **Tiene propiedades mutables e inmutables**: el SKU y los tags se cambian; la región y el tipo, no.
- **Su borrado tiene letra pequeña**: se puede recuperar durante 14 días, pero no retiene el nombre.
- **Cuesta fracciones de centavo** en una hora.

> ⚠️ **Desviación del baseline, declarada.** La rutina usa la cuenta `invlabrt472913` en el grupo de
> drills `inv-drill-rg`, no la `invlab472913` del tronco: así puede correrse en cualquier momento de la
> serie sin tocar un recurso de los labs. El nombre sigue la regla de las storage accounts: de 3 a 24
> minúsculas y dígitos, único en todo Azure.

Para una segunda vuelta, la misma forma sirve con una user-assigned managed identity (gratis, sin data
plane), un NSG (gratis, con reglas como subrecursos) o un Key Vault (con soft-delete de verdad y purge).

---

## 4. 🧱 Paso 1: crear

**Teardown antes que el despliegue:** el paso 4 borra la cuenta y el grupo; el paso 5 verifica que no
queda nada, ni la cuenta recuperable.

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
SUB=$(az account show --query id --output tsv)
az group create --name inv-drill-rg --location eastus2 --tags project=inv-lab env=lab --output none

az storage account create \
  --name invlabrt472913 --resource-group inv-drill-rg --location eastus2 \
  --sku Standard_LRS --kind StorageV2 \
  --allow-blob-public-access false --allow-shared-key-access false \
  --tags project=inv-lab env=lab \
  --debug 2>&1 | grep -E "Request URL|Request method|Response status" | head -6
```

- Los flags son los de [`L02` §3](l02-entra-id-rbac-y-managed-identities.md#3--una-storage-account-sin-access-keys):
  cada uno está explicado allí.
- `--debug 2>&1 | grep ...` se queda con las líneas del puente CLI→API ([`A01` §10](a01-az-de-supervivencia.md#10----debug-y---verbose-el-microscopio)).

```text
[PENDIENTE DE CORRIDA] Una petición PUT sobre
https://management.azure.com/subscriptions/11112222-3333-4444-5555-666677778888/resourceGroups/inv-drill-rg/providers/Microsoft.Storage/storageAccounts/invlabrt472913?api-version=…
con Response status 202, y a continuación varios GET a una URL de operación con Response status 202 y
después 200.
```

Léelo, porque es la lección del paso:

- **El `create` es un `PUT` sobre el resource ID**. El nombre, el grupo y el tipo están en la URL; lo
  demás, en el cuerpo.
- **El `api-version` que usa tu CLI** para este tipo de recurso aparece en la URL. Es el que escribirás en
  `az rest` y el que el SDK usa por dentro.
- **`202 Accepted` y después sondeos**: crear una storage account es una **operación de larga
  duración**. ARM acepta la petición y devuelve una URL de estado; la CLI la sondea hasta el `200`. Por eso
  parece síncrona. Con `--no-wait`, no esperaría ([`A01` §9](a01-az-de-supervivencia.md#9--operaciones-de-larga-duración---no-wait-y-wait)).

---

## 5. 🧱 Paso 2: inspeccionar

Lo que el recurso **es** de verdad, no lo que pediste:

```bash
az storage account show --name invlabrt472913 --resource-group inv-drill-rg --output json > account.json
az storage account show --name invlabrt472913 --resource-group inv-drill-rg \
  --query "{sku:sku.name, kind:kind, tier:accessTier, tls:minimumTlsVersion, sharedKey:allowSharedKeyAccess, blob:primaryEndpoints.blob}"
```

- Guardar el JSON completo en un archivo es parte del entregable: es el mapa de propiedades del recurso.
- El `--query` recorta a las que importan. Busca en el JSON las que **no pediste** y tienen valor: son los
  defaults del servicio para esa versión de API (`accessTier`, `minimumTlsVersion`, cifrado…).

```text
[PENDIENTE DE CORRIDA] sku Standard_LRS, kind StorageV2, tier Hot, tls TLS1_2, sharedKey false y
blob https://invlabrt472913.blob.core.windows.net/.
```

La misma lectura, sin la CLI de por medio, con la `api-version` que viste en el paso 1:

```bash
API_VERSION=2026-06-01
az rest --method get \
  --url "https://management.azure.com/subscriptions/$SUB/resourceGroups/inv-drill-rg/providers/Microsoft.Storage/storageAccounts/invlabrt472913?api-version=$API_VERSION" \
  --query "{sku:sku.name, kind:kind, tls:properties.minimumTlsVersion}"
```

- `2026-06-01` es la versión de `Microsoft.Storage/storageAccounts` que fija el Bicep de
  [`15` §3](15-bicep-iac.md#3--un-archivo-bicep-del-laboratorio). Si tu CLI usa otra, las dos sirven.
- Fíjate en la diferencia: `az storage account show` **aplana** `properties` (devuelve
  `minimumTlsVersion` arriba); la API devuelve el objeto tal cual, con `properties.minimumTlsVersion`.
  Cuando traduzcas un `--query` de la CLI al SDK o a `az rest`, esa es la trampa.

```text
[PENDIENTE DE CORRIDA] {"sku": "Standard_LRS", "kind": "StorageV2", "tls": "TLS1_2"}
```

Y ahora el **data plane**, que es otro host y otro permiso. Un contenedor por ARM y un blob por el
endpoint de la cuenta, como en [`L02` §4](l02-entra-id-rbac-y-managed-identities.md#4--un-contenedor-por-el-control-plane):

```bash
ME=$(az ad signed-in-user show --query id --output tsv)
ACCOUNT_ID=$(az storage account show --name invlabrt472913 --resource-group inv-drill-rg --query id --output tsv)
az storage container-rm create --storage-account invlabrt472913 --resource-group inv-drill-rg \
  --name routine --public-access off --output none
az role assignment create --assignee-object-id "$ME" --assignee-principal-type User \
  --role "Storage Blob Data Contributor" --scope "$ACCOUNT_ID" --output none
sleep 120
az storage blob upload --account-name invlabrt472913 --container-name routine --name hello.txt \
  --data "rutina A04" --auth-mode login --debug 2>&1 | grep -E "Request URL|Response status" | head -2
```

- El contenedor se crea en `management.azure.com`; el blob se sube a `invlabrt472913.blob.core.windows.net`.
  Mira la `Request URL` de cada uno.
- El role assignment es tuyo y en el scope de la cuenta: sin él, el upload sería el `403` de [`L02`](l02-entra-id-rbac-y-managed-identities.md). El
  `sleep 120` da margen a la propagación; si aun así falla, espera y repite.

```text
[PENDIENTE DE CORRIDA] Una petición PUT sobre
https://invlabrt472913.blob.core.windows.net/routine/hello.txt con Response status 201.
```

---

## 6. 🧱 Paso 3: modificar, y encontrar la frontera inmutable

Tres cambios, y uno que **no se deja hacer**:

```bash
az storage account update --name invlabrt472913 --resource-group inv-drill-rg \
  --tags project=inv-lab env=lab routine=a04 --query tags
az storage account update --name invlabrt472913 --resource-group inv-drill-rg \
  --sku Standard_GRS --query sku.name
az storage account update --name invlabrt472913 --resource-group inv-drill-rg \
  --sku Standard_LRS --query sku.name
```

- `update` hace un `PATCH`: cambia solo lo que le pasas. `--tags` **sustituye** el conjunto de tags,
  así que se repiten los dos obligatorios.
- `--sku Standard_GRS` cambia la redundancia a geo-redundante: la cuenta empieza a replicar a la región
  pareja ([`06` §3](06-almacenamiento-storage-accounts.md#3--redundancia)). Se devuelve a LRS enseguida:
  GRS cuesta más y la rutina no lo necesita.

```text
[PENDIENTE DE CORRIDA] Los tres tags; "Standard_GRS"; "Standard_LRS".
```

Ahora la frontera. La **región** de un recurso no se cambia: mover una storage account de región es
crear otra y copiar los datos. Pruébalo con un `PUT` que pide otra región para el mismo resource ID:

```bash
az rest --method put \
  --url "https://management.azure.com/subscriptions/$SUB/resourceGroups/inv-drill-rg/providers/Microsoft.Storage/storageAccounts/invlabrt472913?api-version=$API_VERSION" \
  --body '{"location": "centralus", "sku": {"name": "Standard_LRS"}, "kind": "StorageV2"}'
```

```text
[PENDIENTE DE CORRIDA] Un error de ARM que rechaza el cambio de ubicación de un recurso existente.
```

Anota en tu apunte, para este tipo de recurso, qué es **mutable** (tags, SKU dentro de ciertas
conversiones, TLS mínimo, acceso público, Shared Key) y qué es **inmutable** (nombre, región, tipo). Esa
tabla, por servicio, es la que te salva de un `terraform apply` o un despliegue de Bicep que "solo
cambiaba una propiedad" y en realidad recrea el recurso.

---

## 7. 🧱 Paso 4: destruir

```bash
az storage account delete --name invlabrt472913 --resource-group inv-drill-rg --yes
az role assignment list --assignee "$ME" --all --query "[?contains(scope, 'invlabrt472913')]" --output table
```

- `az storage account delete --yes` borra la cuenta, sus contenedores y sus blobs.
- El role assignment tenía scope **en la cuenta**: se va con ella. La segunda línea lo comprueba.

```text
[PENDIENTE DE CORRIDA] El delete no imprime nada; la lista de role assignments con ese scope, vacía.
```

---

## 8. 🧱 Paso 5: verificar qué quedó

Lo que el `delete` dejó, que en una storage account no es "nada":

```bash
az rest --method get \
  --url "https://management.azure.com/subscriptions/$SUB/providers/Microsoft.Storage/deletedAccounts?api-version=$API_VERSION" \
  --query "value[?name=='invlabrt472913'].{name:name, location:properties.location, deleted:properties.deletionTime}"
```

- No hay un comando `az` para listar storage accounts borradas: se lee la API de `deletedAccounts`. Una
  cuenta borrada es **recuperable durante 14 días** si nadie crea otra con el mismo nombre; no retiene el
  nombre y no cobra.

```text
[PENDIENTE DE CORRIDA] Una entrada con invlabrt472913 y su fecha de borrado.
```

Y el cierre de la vuelta:

```bash
az group delete --name inv-drill-rg --yes
az group exists --name inv-drill-rg
az resource list --tag project=inv-lab --query "[?resourceGroup=='inv-drill-rg']" --output table
```

```text
[PENDIENTE DE CORRIDA] false, y ninguna fila.
```

---

## 9. 🧪 Paso 6: lo mismo desde el SDK de Java

El mismo recorrido, en un solo programa. En `~/inv-lab/routine`, un `pom.xml` con el Azure SDK BOM:

```xml
<!-- pom.xml de la rutina: versiones fijadas por el Azure SDK BOM -->
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>com.azure</groupId>
      <artifactId>azure-sdk-bom</artifactId>
      <version>1.3.8</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>
<dependencies>
  <dependency><groupId>com.azure.resourcemanager</groupId><artifactId>azure-resourcemanager</artifactId></dependency>
  <dependency><groupId>com.azure</groupId><artifactId>azure-storage-blob</artifactId></dependency>
  <dependency><groupId>com.azure</groupId><artifactId>azure-identity</artifactId></dependency>
</dependencies>
<build>
  <plugins>
    <plugin>
      <groupId>org.codehaus.mojo</groupId>
      <artifactId>exec-maven-plugin</artifactId>
      <version>3.6.4</version>
      <configuration><mainClass>dev.invlab.routine.StorageRoutine</mainClass></configuration>
    </plugin>
  </plugins>
</build>
```

- `azure-sdk-bom` **1.3.8** fija `azure-resourcemanager` 2.63.0 (el SDK de control plane, que agrupa
  storage, autorización y el resto), `azure-storage-blob` 12.35.0 (data plane) y `azure-identity`
  1.18.4.
- `exec-maven-plugin` 3.6.4 permite ejecutar la clase con `mvn exec:java`, con versión fija.

El programa, con los cinco pasos marcados:

```java
// StorageRoutine.java — la rutina de A04, del control plane al data plane y vuelta
package dev.invlab.routine;

import com.azure.core.management.profile.AzureProfile;
import com.azure.core.models.AzureCloud;
import com.azure.core.util.BinaryData;
import com.azure.identity.DefaultAzureCredential;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.resourcemanager.AzureResourceManager;
import com.azure.resourcemanager.authorization.models.BuiltInRole;
import com.azure.resourcemanager.storage.models.PublicAccess;
import com.azure.resourcemanager.storage.models.StorageAccount;
import com.azure.resourcemanager.storage.models.StorageAccountSkuType;
import com.azure.storage.blob.BlobServiceClientBuilder;
import java.util.UUID;

public class StorageRoutine {

    public static void main(String[] args) throws Exception {
        String subscription = System.getenv("AZURE_SUBSCRIPTION_ID");
        String myObjectId = System.getenv("MY_OBJECT_ID");
        String rg = "inv-drill-rg";
        String name = "invlabrt472913";

        // en tu portátil, la cadena encuentra la sesión de az del perfil aislado
        DefaultAzureCredential credential = new DefaultAzureCredentialBuilder().build();
        AzureResourceManager azure = AzureResourceManager
                .authenticate(credential, new AzureProfile(AzureCloud.AZURE_PUBLIC_CLOUD))
                .withSubscription(subscription);

        // 1. crear — la llamada bloquea hasta que la operación de larga duración termina
        azure.resourceGroups().define(rg).withRegion("eastus2")
                .withTag("project", "inv-lab").withTag("env", "lab").create();
        StorageAccount account = azure.storageAccounts().define(name)
                .withRegion("eastus2")
                .withExistingResourceGroup(rg)
                .withSku(StorageAccountSkuType.STANDARD_LRS)
                .withGeneralPurposeAccountKindV2()
                .disableBlobPublicAccess()
                .disableSharedKeyAccess()
                .withTag("project", "inv-lab").withTag("env", "lab")
                .create();

        // 2. inspeccionar — lo que el recurso es, no lo que pediste
        account = azure.storageAccounts().getByResourceGroup(rg, name);
        System.out.println(account.id() + " " + account.skuType().name() + " " + account.endPoints().primary().blob());

        // el contenedor, por el control plane; el rol de datos, por Azure RBAC
        azure.storageBlobContainers().defineContainer("routine")
                .withExistingStorageAccount(rg, name).withPublicAccess(PublicAccess.NONE).create();
        azure.accessManagement().roleAssignments().define(UUID.randomUUID().toString())
                .forObjectId(myObjectId)
                .withBuiltInRole(BuiltInRole.STORAGE_BLOB_DATA_CONTRIBUTOR)
                .withResourceScope(account)
                .create();
        Thread.sleep(120_000);   // propagación del role assignment: hasta 10 minutos

        // el blob, por el data plane: otro host, otro cliente, la misma credencial
        new BlobServiceClientBuilder().endpoint(account.endPoints().primary().blob()).credential(credential)
                .buildClient().getBlobContainerClient("routine").getBlobClient("hello.txt")
                .upload(BinaryData.fromString("rutina A04 desde Java"), true);

        // 3. modificar — PATCH con solo lo que cambia
        account.update().withTag("routine", "a04").apply();

        // 4. destruir, y 5. verificar
        azure.storageAccounts().deleteByResourceGroup(rg, name);
        azure.resourceGroups().deleteByName(rg);
        System.out.println("¿queda el grupo? " + azure.resourceGroups().contain(rg));
    }
}
```

- `AzureResourceManager.authenticate(credential, profile).withSubscription(...)` es el cliente de
  **control plane**: detrás de cada llamada fluent hay un `PUT`, `GET`, `PATCH` o `DELETE` sobre
  `management.azure.com`, los mismos del paso 1.
- `define(name)...create()` es el `az storage account create`, con los mismos flags en forma de
  métodos: `disableSharedKeyAccess()` es `--allow-shared-key-access false`.
- `BlobServiceClientBuilder().endpoint(...).credential(credential)` es el cliente de **data plane**: otro
  host, otra audiencia de token, la misma `DefaultAzureCredential`.
- `update().withTag(...).apply()` es el `PATCH` del paso 3.
- `deleteByResourceGroup` y `resourceGroups().deleteByName` son los `DELETE` del paso 4.

Ejecútalo con tu sesión y tu object ID:

```bash
cd ~/inv-lab/routine
AZURE_SUBSCRIPTION_ID="$SUB" MY_OBJECT_ID="$ME" mvn -q compile exec:java
```

```text
[PENDIENTE DE CORRIDA] El resource ID de la cuenta, Standard_LRS y el endpoint de blobs; al final,
"¿queda el grupo? false". El programa tarda varios minutos: las operaciones de larga duración y la
espera de la propagación.
```

---

## 10. 🧪 Tres lecciones que solo da el paso 6

**Las operaciones de larga duración.** El `create()` fluent **bloquea** hasta que la operación termina,
igual que la CLI. Por debajo hay un poller, y el cliente interno lo expone:

```java
// la misma creación, con el poller a la vista
SyncPoller<PollResult<StorageAccountInner>, StorageAccountInner> poller = azure.storageAccounts().manager()
        .serviceClient().getStorageAccounts()
        .beginCreate(rg, name, new StorageAccountCreateParameters()
                .withLocation("eastus2")
                .withSku(new Sku().withName(SkuName.STANDARD_LRS))
                .withKind(Kind.STORAGE_V2)
                .withAllowSharedKeyAccess(false)
                .withAllowBlobPublicAccess(false));
StorageAccountInner created = poller.getFinalResult();   // aquí se espera, sondeando la URL de estado
```

- `manager().serviceClient()` baja del cliente fluent al cliente generado a partir de la API, uno a uno
  con sus operaciones.
- `beginCreate` devuelve un `SyncPoller` en cuanto ARM acepta la petición (el `202` del paso 1);
  `getFinalResult()` sondea hasta el final. Entre medias, tu código puede hacer otra cosa: es el
  `--no-wait` del SDK.

**De dónde saca la credencial tu código.** Si el programa falla al empezar, casi siempre es
`DefaultAzureCredential` recorriendo su cadena sin encontrar nada: en el portátil necesita la sesión de
`az` **del perfil que tiene la variable `AZURE_CONFIG_DIR`** de esa terminal. Con otra terminal sin el
`export`, usa tu sesión de trabajo, o ninguna ([`09` §8](09-identidad-entra-id-y-managed-identities.md#8--defaultazurecredential-en-java)).
El mismo código, en Container Apps, encontraría la managed identity sin cambiar una línea.

**Control plane y data plane, en el código.** Dos clientes distintos, dos hosts distintos, dos
permisos distintos: `AzureResourceManager` necesita `Actions` y tu rol de Owner basta;
`BlobServiceClient` necesita `DataActions` y sin el role assignment falla con el `403` de [`L02`](l02-entra-id-rbac-y-managed-identities.md), aunque
el primer cliente acabe de crear la cuenta. Verlo en tu propio código fija el concepto de
[`10` §3](10-autorizacion-rbac-policy-y-gobierno.md#3--role-definitions-actions-y-dataactions) mejor que cualquier diagrama.

---

## 11. 🧭 El entregable no es el recurso

Al terminar la vuelta no queda nada en Azure, y es lo correcto. Lo que queda es:

- el `account.json` del paso 2, con las propiedades reales del recurso;
- la tabla de mutables e inmutables del paso 3;
- las URLs y la `api-version` del paso 1, que son las de la referencia de la API;
- `StorageRoutine.java`, que la próxima vez es una plantilla para otro servicio.

Con eso, la pregunta de entrevista *"¿cómo automatizarías la creación de X?"* tiene una respuesta con
tres niveles —CLI, API y SDK— y con la letra pequeña del borrado incluida.

---

## 📋 Checklist de salida

- [ ] Viste el `PUT`, el `202` y los sondeos de la creación con `--debug`, y anotaste la `api-version`.
- [ ] Leíste la misma cuenta con `az storage account show` y con `az rest`, y sabes por qué el `--query` cambia.
- [ ] Viste el contenedor ir a `management.azure.com` y el blob a `invlabrt472913.blob.core.windows.net`.
- [ ] Anotaste qué propiedades de una storage account son mutables y cuáles no, y viste fallar el cambio de región.
- [ ] Encontraste la cuenta borrada en `deletedAccounts`.
- [ ] El programa Java recorrió los cinco pasos y terminó con el grupo borrado.
- [ ] `az group exists --name inv-drill-rg` devuelve `false`.

## 🏁 La señal de que quedó bien

`inv-drill-rg` no existe, `az resource list --tag project=inv-lab` no muestra nada de la rutina, y
tienes un apunte con la URL, la `api-version`, las propiedades reales, la frontera inmutable y el
programa Java de la storage account.

---

## 🧠 Preguntas rápidas

1. ¿Cuáles son los seis pasos de la rutina y qué pregunta responde cada uno?
2. ¿Qué te enseña `--debug` sobre `az storage account create` que no diga la documentación del comando?
3. ¿Por qué `az storage account create` parece síncrono si ARM responde `202`?
4. ¿Por qué un `--query` que funciona con `az storage account show` puede no funcionar con `az rest`?
5. ¿Qué hosts usan la creación del contenedor y la subida del blob, y qué permiso necesita cada uno?
6. ¿Qué propiedades de una storage account puedes cambiar con `update` y cuáles obligan a recrearla?
7. ¿Qué queda de una storage account después de borrarla y cómo lo compruebas?
8. En el SDK, ¿qué cliente usas para el control plane y cuál para el data plane, y por qué el segundo puede fallar aunque el primero acabe de crear la cuenta?
9. ¿Qué hace `beginCreate` que no hace `create()`, y cuándo lo usarías?
10. El programa Java falla al autenticarse en tu portátil y `az` funciona en otra terminal. ¿Qué pasa?

---

## 📚 Referencias oficiales

- Referencia de `az storage account`: https://learn.microsoft.com/en-us/cli/azure/storage/account
- API REST de storage accounts (Storage Resource Provider): https://learn.microsoft.com/en-us/rest/api/storagerp/storage-accounts
- API de cuentas borradas: https://learn.microsoft.com/en-us/rest/api/storagerp/deleted-accounts/list
- Recuperar una storage account borrada: https://learn.microsoft.com/en-us/azure/storage/common/storage-account-recover
- Operaciones asíncronas de Resource Manager: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/async-operations
- Usar la API REST con `az rest`: https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-rest-command
- Troubleshooting de la CLI (`--debug`): https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-successfully-troubleshooting
- Azure SDK for Java, bibliotecas de gestión: https://learn.microsoft.com/en-us/azure/developer/java/sdk/overview
- Autenticación con Azure Identity para Java: https://learn.microsoft.com/en-us/java/api/overview/azure/identity-readme
- Biblioteca cliente de Blob Storage para Java: https://learn.microsoft.com/en-us/java/api/overview/azure/storage-blob-readme
- Operaciones de larga duración en el SDK de Java: https://learn.microsoft.com/en-us/azure/developer/java/sdk/lro
- Redundancia de Storage: https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy
