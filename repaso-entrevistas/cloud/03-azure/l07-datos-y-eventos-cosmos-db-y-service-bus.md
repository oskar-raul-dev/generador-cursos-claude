# L07 — Datos y eventos: Cosmos DB y Service Bus

> **Objetivo:** completar el sistema de [`L00` §5](l00-idea-lab-practico.md#5--el-sistema-que-vas-a-construir):
> `inv-api` escribe cada movimiento en Cosmos DB de forma idempotente y lo publica en el topic
> `inv-events`; `inv-projector` lo consume de su subscription, recalcula el stock y escala de cero a N
> réplicas según los mensajes pendientes. Por el camino, un `429` visto en crudo contra la API REST de
> Cosmos DB, un duplicado que no duplica nada, y un mensaje envenenado que agota `MaxDeliveryCount` y
> acaba en la DLQ.
> **Se asume leído:** [`08`](08-cosmos-db.md) (partition key, RU, SDK de Java) y
> [`13`](13-mensajeria-y-eventos.md) (Service Bus, peek-lock, DLQ, idempotencia y outbox).
> **Costo:** **~$0.32 por cada día que exista el namespace de Service Bus** (Standard a $0.013441/h,
> exista tráfico o no), más el día del registry de [`L05`](l05-container-apps-revisiones-trafico-y-escala.md). Cosmos DB entra en el **free tier** (1.000
> RU/s y 25 GB) si la suscripción no lo usó ya; si no, los 400 RU/s del lab cuestan $0.032/h. Las dos
> apps y los jobs, dentro del free grant de Container Apps.
> **Duración:** 3–4 horas.
> **Prerrequisitos:** [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) terminado (`inv-api`
> validando tokens y `inv-projector-id` con el app role `Inventory.Write`), y los identificadores que
> anotaste allí (`API_APP_ID`).
> **Qué queda encendido al terminar:** el sistema completo de [`L00`](l00-idea-lab-practico.md) §5: la cuenta `inv-lab-cosmos-472913`
> con la base `inv` y los contenedores `events` y `stock`, el namespace `inv-lab-sb-472913` con el topic y
> la subscription, `inv-api` en `v6` e `inv-projector` a cero réplicas. **El namespace cobra por hora
> mientras exista**: haz [`L08`](l08-observabilidad-kql-y-auditoria.md) y [`L09`](l09-costos-y-destruccion-verificada.md) pronto, o lee la sección 13 antes de pausar.
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026. `spring-cloud-azure-dependencies` **7.4.0** (Azure SDK BOM
> 1.3.8: `azure-cosmos` 4.81.0, `azure-messaging-servicebus` 7.17.19, `azure-identity` 1.18.4).

**Salto rápido:** [Qué se practica](#1--qué-se-practica) · [Arranque](#2--arranque) ·
[Cuenta con free tier](#3--la-cuenta-de-cosmos-db-con-free-tier) ·
[Base y contenedores](#4--la-base-los-contenedores-y-la-partition-key) ·
[Roles de datos de Cosmos DB](#5--roles-de-datos-el-rbac-propio-de-cosmos-db) ·
[El 429 crudo](#6--un-429-en-crudo-contra-la-api-rest) · [Service Bus](#7--el-namespace-el-topic-y-la-subscription) ·
[inv-api escribe y publica](#8--inv-api-escribe-y-publica) · [inv-projector](#9--inv-projector-consume-y-escala) ·
[El recorrido completo](#10--un-movimiento-de-punta-a-punta) · [Duplicados](#11--el-duplicado-que-no-duplica-nada) ·
[Mensaje envenenado](#12--el-mensaje-envenenado-y-la-dlq) · [Teardown](#13--teardown-y-lo-que-queda-encendido) ·
[Checklist](#-checklist-de-salida) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Qué se practica

Es el lab más largo de la serie porque junta las dos piezas que más se preguntan en una entrevista de
backend en Azure: cómo se diseña la escritura en Cosmos DB y qué pasa cuando un mensaje llega dos veces
o no se puede procesar nunca.

```text
job (identidad inv-projector-id, app role Inventory.Write)
   │ POST /movements  {movementId, storeId, sku, delta}
   ▼
inv-api ──upsert id=movementId──► Cosmos DB  inv/events   (pk /storeId)
   │
   └──send MessageId=movementId──► Service Bus  topic inv-events
                                        │  subscription inv-projector
                                        │  (peek-lock, MaxDeliveryCount 5, duplicate detection)
                                        ▼
                                 inv-projector (0 → N réplicas por mensajes pendientes)
                                        │
                                        ├──► Cosmos DB  inv/stock   (pk /storeId, id = sku)
                                        └──► tras 5 entregas fallidas: DLQ de la subscription
```

La doctrina de reparto de [`L00` §2](l00-idea-lab-practico.md#2--la-doctrina-de-reparto-qué-se-paga-y-qué-se-practica-en-local)
explica por qué esto va en la nube: los emuladores de Cosmos DB y de Service Bus corren el mismo código,
pero **ninguno evalúa RBAC**, el de Cosmos DB no reproduce el throttling real por Request Units, y el de
Service Bus no integra Entra ID ([`L00` §8](l00-idea-lab-practico.md#8--emuladores-locales-qué-sirve-y-qué-miente)).

> ⚠️ **Una simplificación declarada.** `inv-api` escribe en Cosmos DB y **después** publica en Service
> Bus. Un fallo entre los dos pasos deja un movimiento sin evento: es el problema del *dual write* que
> resuelve el patrón outbox de [`13` §10](13-mensajeria-y-eventos.md#10--at-least-once-idempotencia-y-outbox).
> El lab no lo implementa para no mezclar el change feed con todo lo demás; la pregunta de entrevista
> sigue siendo "¿y si falla entre los dos pasos?", y la respuesta, el outbox.

---

## 2. 🧱 Arranque

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
SUB=$(az account show --query id --output tsv)
ME=$(az ad signed-in-user show --query id --output tsv)
API_PID=$(az identity show --name inv-api-id --resource-group inv-lab-rg --query principalId --output tsv)
PROJ_ID=$(az identity show --name inv-projector-id --resource-group inv-lab-rg --query id --output tsv)
PROJ_PID=$(az identity show --name inv-projector-id --resource-group inv-lab-rg --query principalId --output tsv)
PROJ_CLIENT_ID=$(az identity show --name inv-projector-id --resource-group inv-lab-rg --query clientId --output tsv)
FQDN=$(az containerapp show --name inv-api --resource-group inv-lab-rg --query properties.configuration.ingress.fqdn --output tsv)
API_APP_ID="00001111-aaaa-2222-bbbb-3333cccc4444"   # sustitúyelo por el appId que anotaste en L06
```

La extensión `containerapp`, que hace falta para la regla de escalado con managed identity de la
sección 9 ([`A01` §13](a01-az-de-supervivencia.md#13--extensiones)):

```bash
az extension add --name containerapp --version 1.3.0b4
```

- `--scale-rule-identity` no existe en el `az containerapp create` del núcleo de la CLI: solo en el de
  la extensión, que está en preview. `1.3.0b4` es la última versión del índice oficial de extensiones a
  la fecha.
- Con la extensión instalada, `az containerapp` usa sus comandos en lugar de los del núcleo; los que ya
  usaste en [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) y [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) siguen funcionando igual.

---

## 3. 🧱 La cuenta de Cosmos DB, con free tier

> 💰 **Costo.** El **free tier** da **1.000 RU/s y 25 GB gratis de por vida**, en **una sola cuenta
> por suscripción**, y **solo si se pide al crearla**: no se puede activar después
> ([`08` §6](08-cosmos-db.md#6--provisionado-autoscale-o-serverless)). Si tu suscripción ya tiene una
> cuenta con free tier, esta no lo tendrá, y los 400 RU/s del lab costarán **$0.032/h** (100 RU/s
> manuales, $0.008/h en `eastus2`). La sección comprueba cuál de los dos casos es el tuyo.

**Teardown antes que el despliegue:** la cuenta vive en `inv-lab-rg` y muere con él en [`L09`](l09-costos-y-destruccion-verificada.md). No queda
soft-deleted ni retiene el nombre.

```bash
az cosmosdb create \
  --name inv-lab-cosmos-472913 \
  --resource-group inv-lab-rg \
  --kind GlobalDocumentDB \
  --locations regionName=eastus2 failoverPriority=0 isZoneRedundant=False \
  --default-consistency-level Session \
  --enable-free-tier true \
  --disable-local-auth true \
  --tags project=inv-lab env=lab \
  --query "{endpoint:documentEndpoint, freeTier:enableFreeTier, localAuthDisabled:disableLocalAuth, consistency:consistencyPolicy.defaultConsistencyLevel}"
```

- `--name inv-lab-cosmos-472913` admite de 3 a 44 caracteres: minúsculas, dígitos y guiones. Es único
  en todo Azure porque forma el host `inv-lab-cosmos-472913.documents.azure.com`.
- `--kind GlobalDocumentDB` es la **API for NoSQL**. La API se fija al crear la cuenta y no se cambia
  ([`08` §3](08-cosmos-db.md#3--las-apis-se-eligen-al-crear-la-cuenta)).
- `--locations regionName=eastus2 failoverPriority=0 isZoneRedundant=False`: una sola región, sin
  redundancia de zona. Cada región añadida multiplica las RU facturadas.
- `--default-consistency-level Session`, el valor por defecto y el que usa el curso.
- `--enable-free-tier true` pide el free tier, que solo existe en este momento.
- `--disable-local-auth true` **deshabilita las claves de la cuenta**: solo se entra al data plane con un
  token de Entra ID y un rol de datos de Cosmos DB. Es el equivalente de
  `--allow-shared-key-access false` en Storage.

```text
[PENDIENTE DE CORRIDA] endpoint https://inv-lab-cosmos-472913.documents.azure.com:443/, freeTier
true (o false si la suscripción ya lo usó), localAuthDisabled true y consistency Session. Tarda
varios minutos.
```

> ⚠️ Si `freeTier` sale `false`, la cuenta cobra desde que tenga throughput. Puedes seguir, sabiendo el
> costo por hora de arriba, o borrarla ahora y usar la cuenta que ya tiene el free tier.

---

## 4. 🧱 La base, los contenedores y la partition key

La partition key se decide **desde los patrones de acceso** ([`08` §12](08-cosmos-db.md#12--modelar-desde-los-patrones-de-acceso)):

```text
Operación                                   ¿Qué valor tengo siempre?     Partition key
registrar un movimiento de una tienda       storeId, movementId           /storeId  (events)
leer el stock de las tiendas, por tienda    storeId                       /storeId  (stock, id = sku)
aplicar un movimiento al stock de un SKU    storeId, sku                  /storeId  (stock, id = sku)
```

`/storeId` tiene cardinalidad (cientos de tiendas en una cadena), reparte la carga, aparece en todas las
operaciones y no cambia. En `stock`, el `id` es el SKU: la pareja `id` + partition key identifica el
stock de un SKU en una tienda, y leerlo es una **point read**, la operación más barata.

```bash
az cosmosdb sql database create --account-name inv-lab-cosmos-472913 --resource-group inv-lab-rg \
  --name inv --throughput 400 --output none

for c in events stock; do
  az cosmosdb sql container create --account-name inv-lab-cosmos-472913 --resource-group inv-lab-rg \
    --database-name inv --name "$c" --partition-key-path /storeId --output none
done
```

- `--throughput 400` en la **base de datos** es throughput **compartido** entre sus contenedores: 400
  RU/s para los dos, el mínimo de una base con throughput manual. Cabe en el free tier con margen y, sin
  él, cuesta la mitad que 400 RU/s por contenedor.
- Los contenedores se crean **sin** `--throughput`: usan el de la base.
- `--partition-key-path /storeId` fija la partition key. **No se puede cambiar**: cambiarla es crear
  otro contenedor y migrar ([`08` §4](08-cosmos-db.md#4--partition-key-la-decisión-que-no-se-deshace)).

```bash
az cosmosdb sql container show --account-name inv-lab-cosmos-472913 --resource-group inv-lab-rg \
  --database-name inv --name events --query "resource.partitionKey"
```

```text
[PENDIENTE DE CORRIDA] {"kind": "Hash", "paths": ["/storeId"], "version": 2}
```

---

## 5. 🧱 Roles de datos: el RBAC propio de Cosmos DB

El data plane de Cosmos DB for NoSQL **no usa los role assignments de Azure RBAC**: tiene sus propias
role definitions y assignments, que se gestionan con `az cosmosdb sql role` ([`08` §11](08-cosmos-db.md#11--transacciones-reintentos-y-el-sdk-de-java)).
Dos son integradas:

| Rol | ID de la definición | Qué permite |
|---|---|---|
| Cosmos DB Built-in Data Reader | `00000000-0000-0000-0000-000000000001` | Leer items y consultar |
| Cosmos DB Built-in Data Contributor | `00000000-0000-0000-0000-000000000002` | Leer, crear, actualizar y borrar items |

Cada identidad, lo justo y **en el contenedor** que usa:

```bash
COSMOS="--account-name inv-lab-cosmos-472913 --resource-group inv-lab-rg"
az cosmosdb sql role assignment create $COSMOS --principal-id "$API_PID" \
  --role-definition-id 00000000-0000-0000-0000-000000000002 --scope "/dbs/inv/colls/events" --output none
az cosmosdb sql role assignment create $COSMOS --principal-id "$API_PID" \
  --role-definition-id 00000000-0000-0000-0000-000000000001 --scope "/dbs/inv/colls/stock" --output none
az cosmosdb sql role assignment create $COSMOS --principal-id "$PROJ_PID" \
  --role-definition-id 00000000-0000-0000-0000-000000000002 --scope "/dbs/inv/colls/stock" --output none
az cosmosdb sql role assignment create $COSMOS --principal-id "$ME" \
  --role-definition-id 00000000-0000-0000-0000-000000000002 --scope "/dbs/inv/colls/events" --output none
```

- `--principal-id` recibe el **object ID** del principal: el `principalId` de la managed identity o tu
  object ID. Mismo identificador que en Azure RBAC, otro sistema de roles.
- `--scope` es una ruta **dentro de la cuenta**: `/` para toda la cuenta, `/dbs/inv` para la base,
  `/dbs/inv/colls/events` para un contenedor. No es un resource ID de ARM.
- `inv-api` escribe en `events` y lee `stock`; `inv-projector` escribe en `stock`. Ninguno toca el
  contenedor del otro más allá de eso.
- **Tu usuario** recibe escritura en `events` solo para la sección 6. Owner de la suscripción no te da
  ni un byte del data plane de Cosmos DB.

```bash
az cosmosdb sql role assignment list $COSMOS --query "[].{principal:principalId, role:roleDefinitionId, scope:scope}" --output table
```

```text
[PENDIENTE DE CORRIDA] Cuatro filas, con los roleDefinitionId terminados en ...0001 y ...0002 y los
scopes de cada contenedor.
```

---

## 6. 🩺 Un `429` en crudo, contra la API REST

Con el SDK, un `429` casi nunca se ve: el cliente reintenta solo, respetando el tiempo que indica el
servicio ([`08` §11](08-cosmos-db.md#11--transacciones-reintentos-y-el-sdk-de-java)). Para verlo tal
cual lo devuelve Cosmos DB, el lab escribe con `curl` contra la
[API REST](https://learn.microsoft.com/en-us/rest/api/cosmos-db/create-a-document), autenticado con un
token de Entra ID.

```bash
COSMOS_TOKEN=$(az account get-access-token \
  --scope "https://inv-lab-cosmos-472913.documents.azure.com/.default" --query accessToken --output tsv)

cosmos_upsert() {
  curl -s -o /dev/null -w '%{http_code}\n' -X POST \
    "https://inv-lab-cosmos-472913.documents.azure.com/dbs/inv/colls/events/docs" \
    -H "Authorization: type%3Daad%26ver%3D1.0%26sig%3D$COSMOS_TOKEN" \
    -H "x-ms-date: $(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S GMT')" \
    -H "x-ms-version: 2018-12-31" \
    -H 'x-ms-documentdb-partitionkey: ["store-load"]' \
    -H "x-ms-documentdb-is-upsert: True" \
    -H "Content-Type: application/json" \
    -d "{\"id\": \"load-$1\", \"storeId\": \"store-load\", \"sku\": \"LOAD\", \"delta\": 1}"
}
cosmos_upsert 1
```

- El token se pide para la audiencia de **la cuenta**, `https://<cuenta>.documents.azure.com`: el data
  plane de Cosmos DB, no ARM.
- `Authorization: type=aad&ver=1.0&sig=<token>`, **codificado en URL**, es el formato que Cosmos DB
  espera cuando se usa su RBAC: `type=aad` en vez de `master` (clave de la cuenta, deshabilitada aquí).
- `x-ms-date` y `x-ms-version` son obligatorias en toda petición. `LC_ALL=C` fuerza los nombres de día y
  mes en inglés, que es lo que exige el formato.
- `x-ms-documentdb-partitionkey: ["store-load"]` dice en qué partición lógica cae el item; tiene que
  coincidir con el `storeId` del cuerpo.
- `x-ms-documentdb-is-upsert: True` convierte el `POST` en un upsert: crea el item o lo sustituye si el
  `id` ya existe en esa partición. Es la escritura idempotente más simple que existe.

```text
[PENDIENTE DE CORRIDA] 201
```

Ahora la carga: 1.500 escrituras con 32 en paralelo, **todas en la misma partición lógica**:

```bash
seq 1 1500 | xargs -P 32 -I{} bash -c "$(declare -f cosmos_upsert); COSMOS_TOKEN='$COSMOS_TOKEN' cosmos_upsert {}" \
  | sort | uniq -c
```

- `xargs -P 32` lanza 32 peticiones a la vez. `declare -f` pasa la función a cada `bash` hijo.
- `sort | uniq -c` cuenta cuántas veces salió cada código.

```text
[PENDIENTE DE CORRIDA] Una mezcla de 201 (o 200 en los upserts sobre un id ya existente) y un
número apreciable de 429.
```

Cada escritura de un item pequeño cuesta del orden de unas pocas RU; cientos por segundo superan los 400
RU/s de la base y Cosmos DB responde **`429 Too Many Requests`**, con la cabecera `x-ms-retry-after-ms`
diciendo cuánto esperar. Sin SDK, **nadie reintenta**: esos movimientos no se escribieron.

Míralo también desde el lado de la plataforma, que es lo que verías en producción aunque el SDK
reintentara:

```bash
COSMOS_ID=$(az cosmosdb show --name inv-lab-cosmos-472913 --resource-group inv-lab-rg --query id --output tsv)
az monitor metrics list --resource "$COSMOS_ID" --metric TotalRequests \
  --filter "StatusCode eq '429'" --interval PT1M --aggregation Count --offset 30m \
  --query "value[0].timeseries[0].data[?count > \`0\`].{time:timeStamp, throttled:count}" --output table
```

- `--metric TotalRequests --filter "StatusCode eq '429'"` cuenta solo las peticiones limitadas.
- `--interval PT1M --offset 30m`: puntos de un minuto en la última media hora. Las métricas llegan con
  un par de minutos de retraso.

```text
[PENDIENTE DE CORRIDA] Uno o dos minutos con un recuento de 429 igual o parecido al de la carga.
```

> 🩺 **Diagnóstico.** Ante `429`, antes de subir RU: ¿está todo en **una** partición lógica? Aquí sí, a
> propósito, y en producción es la *hot partition* de [`08`](08-cosmos-db.md), pregunta 4. Subir el
> throughput reparte más RU entre las particiones físicas, pero no arregla una partition key que
> concentra la carga.

Los items de la carga se quedan en la partición `store-load`: son unos cientos de documentos
diminutos, caben en el free tier y se van con la cuenta en [`L09`](l09-costos-y-destruccion-verificada.md). Lo que sí se retira ahora es tu rol
de escritura, que ya no necesitas:

```bash
MY_ASSIGNMENT=$(az cosmosdb sql role assignment list $COSMOS --query "[?principalId=='$ME'].name" --output tsv)
az cosmosdb sql role assignment delete $COSMOS --role-assignment-id "$MY_ASSIGNMENT" --yes
```

---

## 7. 🧱 El namespace, el topic y la subscription

> 💰 **Costo.** Un namespace **Standard** cobra **$0.013441/h** —unos $0.32 al día, $10 al mes—
> **exista tráfico o no**, con 13 millones de operaciones al mes incluidas ([`13` §3](13-mensajeria-y-eventos.md#3--service-bus-el-broker-empresarial)).
> Basic no tiene topics. Es el segundo cargo que corre solo por existir, junto al registry.

**Teardown antes que el despliegue:** el namespace, su topic y su subscription mueren con `inv-lab-rg`
en [`L09`](l09-costos-y-destruccion-verificada.md). No hay soft-delete.

Los tres comandos de [`13` §6](13-mensajeria-y-eventos.md#6--service-bus-en-el-laboratorio), sin
cambios:

```bash
az servicebus namespace create --name inv-lab-sb-472913 --resource-group inv-lab-rg --location eastus2 \
  --sku Standard --disable-local-auth true --tags project=inv-lab env=lab --output none

az servicebus topic create --name inv-events --namespace-name inv-lab-sb-472913 --resource-group inv-lab-rg \
  --enable-duplicate-detection true --output none

az servicebus topic subscription create --name inv-projector --topic-name inv-events \
  --namespace-name inv-lab-sb-472913 --resource-group inv-lab-rg \
  --max-delivery-count 5 --lock-duration PT1M --enable-dead-lettering-on-message-expiration true --output none
```

- El nombre del namespace admite de 6 a 50 caracteres, letras, dígitos y guiones, empezando por letra, y
  es único en todo Azure: forma `inv-lab-sb-472913.servicebus.windows.net`.
- `13` §6 explica cada flag; los tres que este lab pone a prueba son `--disable-local-auth true` (no
  hay connection string que filtrar), `--enable-duplicate-detection true` (sección 11) y
  `--max-delivery-count 5` (sección 12).

Los roles de datos, **en la entidad justa**:

```bash
SB_ID=$(az servicebus namespace show --name inv-lab-sb-472913 --resource-group inv-lab-rg --query id --output tsv)
az role assignment create --assignee-object-id "$API_PID" --assignee-principal-type ServicePrincipal \
  --role "Azure Service Bus Data Sender" --scope "$SB_ID/topics/inv-events" --output none
az role assignment create --assignee-object-id "$PROJ_PID" --assignee-principal-type ServicePrincipal \
  --role "Azure Service Bus Data Receiver" --scope "$SB_ID/topics/inv-events/subscriptions/inv-projector" --output none
```

- Aquí sí son role assignments de **Azure RBAC**: Service Bus autoriza su data plane con ellos, a
  diferencia de Cosmos DB.
- `Data Sender` **sobre el topic**: `inv-api` publica y no puede leer. `Data Receiver` **sobre la
  subscription**: `inv-projector` lee la suya y no puede publicar ni leer otras. El scope es el resource
  ID de la entidad, que cuelga del namespace.

---

## 8. 🧱 `inv-api` escribe y publica

La versión `0.4.0` de `inv-api` guarda cada movimiento en `events` y lo publica. En el `pom.xml`, el BOM
de Spring Cloud Azure fija las versiones del SDK:

```xml
  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>com.azure.spring</groupId>
        <artifactId>spring-cloud-azure-dependencies</artifactId>
        <version>7.4.0</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>
```

```xml
    <!-- sin versión: la fija el BOM (Azure SDK BOM 1.3.8) -->
    <dependency><groupId>com.azure</groupId><artifactId>azure-cosmos</artifactId></dependency>
    <dependency><groupId>com.azure</groupId><artifactId>azure-messaging-servicebus</artifactId></dependency>
    <dependency><groupId>com.azure</groupId><artifactId>azure-identity</artifactId></dependency>
```

- `spring-cloud-azure-dependencies` **7.4.0** es la versión para Spring Boot 4.0.x ([`11` §7](11-secretos-cifrado-y-key-vault.md#7--consumir-secretos-desde-la-aplicación)).
  Importa el Azure SDK BOM 1.3.8, que fija `azure-cosmos` 4.81.0, `azure-messaging-servicebus` 7.17.19 y
  `azure-identity` 1.18.4. Una versión de BOM, tres librerías coherentes.
- Se usan los SDK directamente, no los starters de Spring Cloud Azure: es el código de `08` y `13`, y deja
  ver cada llamada.

Los clientes, **uno por aplicación**, y el endpoint:

```java
// AzureClients.java — un CosmosClient y un sender por aplicación, con la managed identity
@Configuration
class AzureClients {

    @Bean
    TokenCredential credential() {
        // en Container Apps usa inv-api-id, elegida por AZURE_CLIENT_ID; en local, tu sesión de az
        return new DefaultAzureCredentialBuilder().build();
    }

    @Bean(destroyMethod = "close")
    CosmosClient cosmos(TokenCredential credential, @Value("${COSMOS_ENDPOINT}") String endpoint) {
        return new CosmosClientBuilder().endpoint(endpoint).credential(credential)
                .consistencyLevel(ConsistencyLevel.SESSION).buildClient();
    }

    @Bean(destroyMethod = "close")
    ServiceBusSenderClient sender(TokenCredential credential, @Value("${SB_NAMESPACE}") String namespace) {
        return new ServiceBusClientBuilder().fullyQualifiedNamespace(namespace).credential(credential)
                .sender().topicName("inv-events").buildClient();
    }
}
```

```java
// Sustituye el POST /movements de L06 en InventoryApiApplication
record Movement(String movementId, String storeId, String sku, Integer delta) {}

@PostMapping("/movements")
public ResponseEntity<Map<String, Object>> movement(@AuthenticationPrincipal Jwt jwt, @RequestBody Movement m)
        throws Exception {
    CosmosContainer events = cosmos.getDatabase("inv").getContainer("events");
    Map<String, Object> event = Map.of("id", m.movementId(), "storeId", m.storeId(),
            "sku", String.valueOf(m.sku()), "delta", m.delta() == null ? 0 : m.delta(),
            "caller", jwt.getClaimAsString("oid"));
    // idempotente: el id del item es el id del movimiento; repetirlo sustituye el mismo item
    double charge = events.upsertItem(event, new PartitionKey(m.storeId()), new CosmosItemRequestOptions())
            .getRequestCharge();

    ServiceBusMessage message = new ServiceBusMessage(json.writeValueAsString(m));
    message.setMessageId(m.movementId());   // duplicate detection deduplica por MessageId
    message.setContentType("application/json");
    sender.sendMessage(message);

    return ResponseEntity.accepted().body(Map.of("movementId", m.movementId(), "requestCharge", charge));
}
```

- `DefaultAzureCredentialBuilder().build()` encuentra la managed identity de la app gracias a
  `AZURE_CLIENT_ID`, que la app tiene desde [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) ([`09` §8](09-identidad-entra-id-y-managed-identities.md#8--defaultazurecredential-en-java)).
- `upsertItem(..., new PartitionKey(storeId), ...)` con `id = movementId` hace la escritura idempotente:
  el mismo movimiento dos veces deja un solo item.
- `getRequestCharge()` devuelve las RU de la operación. La API lo devuelve en la respuesta para que lo
  veas; en producción, se registra en los logs.
- `message.setMessageId(movementId)` es lo que permite a **duplicate detection** descartar un reenvío
  del mismo movimiento dentro de la ventana de 10 minutos.
- `cosmos`, `sender` y `json` (un `ObjectMapper`) se inyectan en la clase por constructor.
- `GET /items` pasa a leer `stock`: `SELECT * FROM c WHERE c.storeId = @storeId` con `new
  PartitionKey(storeId)` en las opciones, para que la consulta vaya a una sola partición.

Despliega `0.4.0` como `v6`, con las dos variables nuevas y todo el tráfico:

```bash
cd ~/inv-lab/inv-api
mvn -q package -DskipTests
docker build --platform linux/amd64 -t invlabacr472913.azurecr.io/inv-api:0.4.0 .
docker push invlabacr472913.azurecr.io/inv-api:0.4.0
az containerapp update --name inv-api --resource-group inv-lab-rg \
  --image invlabacr472913.azurecr.io/inv-api:0.4.0 --revision-suffix v6 \
  --set-env-vars COSMOS_ENDPOINT="https://inv-lab-cosmos-472913.documents.azure.com:443/" \
                 SB_NAMESPACE="inv-lab-sb-472913.servicebus.windows.net" --output none
az containerapp ingress traffic set --name inv-api --resource-group inv-lab-rg \
  --revision-weight inv-api--v5=0 inv-api--v6=100 --output none
az containerapp revision deactivate --name inv-api --resource-group inv-lab-rg --revision inv-api--v5
```

---

## 9. 🧱 `inv-projector` consume, y escala

`inv-projector` es la segunda app del sistema. Tiene el mismo `pom.xml` que `inv-api` sin la seguridad,
con `artifactId` `inv-projector`, en `~/inv-lab/inv-projector`. Su trabajo es el consumidor de
[`13` §6](13-mensajeria-y-eventos.md#6--service-bus-en-el-laboratorio) más una escritura idempotente
en `stock`:

```java
// Projector.java — aplica cada movimiento al stock una sola vez
@Component
class Projector {

    private final CosmosContainer stock;
    private final ObjectMapper json;
    private final ServiceBusProcessorClient processor;

    Projector(CosmosClient cosmos, ObjectMapper json, TokenCredential credential,
              @Value("${SB_NAMESPACE}") String namespace) {
        this.stock = cosmos.getDatabase("inv").getContainer("stock");
        this.json = json;
        this.processor = new ServiceBusClientBuilder().fullyQualifiedNamespace(namespace).credential(credential)
                .processor().topicName("inv-events").subscriptionName("inv-projector")
                .disableAutoComplete()
                .processMessage(context -> {
                    apply(context.getMessage());   // si lanza, no se completa: el lock expira y vuelve
                    context.complete();
                })
                .processError(error -> System.err.println("Service Bus: " + error.getException().getMessage()))
                .buildProcessorClient();
    }

    @PostConstruct void start() { processor.start(); }
    @PreDestroy void stop() { processor.close(); }

    void apply(ServiceBusReceivedMessage message) throws Exception {
        Map<String, Object> m = json.readValue(message.getBody().toString(), Map.class);
        String storeId = (String) m.get("storeId");
        String sku = (String) m.get("sku");
        if (sku == null || sku.isBlank()) {
            // un mensaje sin SKU nunca podrá aplicarse: el lab deja que agote los reintentos
            throw new IllegalArgumentException("movimiento sin sku: " + message.getMessageId());
        }
        Map<String, Object> doc;
        String etag = null;
        try {
            CosmosItemResponse<Map> current = stock.readItem(sku, new PartitionKey(storeId), Map.class);
            doc = new HashMap<>(current.getItem());
            etag = current.getETag();
        } catch (NotFoundException e) {
            doc = new HashMap<>(Map.of("id", sku, "storeId", storeId, "quantity", 0, "applied", List.of()));
        }
        List<String> applied = new ArrayList<>((List<String>) doc.get("applied"));
        if (applied.contains(message.getMessageId())) {
            return;   // ya aplicado: una redelivery no cambia nada
        }
        doc.put("quantity", ((Number) doc.get("quantity")).intValue() + ((Number) m.get("delta")).intValue());
        applied.add(message.getMessageId());
        doc.put("applied", applied.subList(Math.max(0, applied.size() - 100), applied.size()));
        CosmosItemRequestOptions options = new CosmosItemRequestOptions();
        if (etag != null) {
            options.setIfMatchETag(etag);   // si otro lo cambió, 412 y el mensaje se reintenta
        }
        stock.upsertItem(doc, new PartitionKey(storeId), options);
    }
}
```

- `readItem(sku, new PartitionKey(storeId), ...)` es una point read: el `id` y la partition key.
- **La idempotencia vive en el mismo documento que el efecto**: la lista `applied` guarda los últimos
  `MessageId` aplicados, y se escribe en la misma operación que la cantidad. Una redelivery encuentra su
  id y no suma dos veces ([`13` §10](13-mensajeria-y-eventos.md#10--at-least-once-idempotencia-y-outbox)).
- `setIfMatchETag(etag)` es concurrencia optimista: si otra réplica actualizó el mismo stock entre la
  lectura y la escritura, Cosmos DB responde `412` y el mensaje vuelve a la cola para reintentarse con el
  dato nuevo ([`08` §11](08-cosmos-db.md#11--transacciones-reintentos-y-el-sdk-de-java)).
- `disableAutoComplete()` y el `complete()` explícito: si `apply` lanza, el mensaje **no** se completa,
  el lock expira y Service Bus lo vuelve a entregar con el delivery count incrementado.
- El mensaje sin SKU **lanza** en vez de ir a `deadLetter()`. En producción, un mensaje que se sabe
  inválido se manda a la DLQ explícitamente, como en `13` §6; el lab deja que agote los cinco intentos
  para ver `MaxDeliveryCountExceeded`.

El `AzureClients` de `inv-projector` es el de `inv-api` sin el sender. Construye y sube la imagen
`inv-projector:0.1.0`, y dale a `inv-projector-id` el pull del registry:

```bash
cd ~/inv-lab/inv-projector
mvn -q package -DskipTests
docker build --platform linux/amd64 -t invlabacr472913.azurecr.io/inv-projector:0.1.0 .
docker push invlabacr472913.azurecr.io/inv-projector:0.1.0
ACR_ID=$(az acr show --name invlabacr472913 --query id --output tsv)
az role assignment create --assignee-object-id "$PROJ_PID" --assignee-principal-type ServicePrincipal \
  --role AcrPull --scope "$ACR_ID" --output none
```

La app, **sin ingress** y con una regla de escalado de KEDA por mensajes pendientes, autenticada con la
managed identity:

```bash
az containerapp create \
  --name inv-projector \
  --resource-group inv-lab-rg \
  --environment inv-lab-env \
  --image invlabacr472913.azurecr.io/inv-projector:0.1.0 \
  --user-assigned "$PROJ_ID" \
  --registry-server invlabacr472913.azurecr.io --registry-identity "$PROJ_ID" \
  --cpu 0.5 --memory 1.0Gi \
  --min-replicas 0 --max-replicas 3 \
  --scale-rule-name sb-backlog \
  --scale-rule-type azure-servicebus \
  --scale-rule-metadata "namespace=inv-lab-sb-472913" "topicName=inv-events" \
                        "subscriptionName=inv-projector" "messageCount=5" \
  --scale-rule-identity "$PROJ_ID" \
  --env-vars AZURE_CLIENT_ID="$PROJ_CLIENT_ID" \
             COSMOS_ENDPOINT="https://inv-lab-cosmos-472913.documents.azure.com:443/" \
             SB_NAMESPACE="inv-lab-sb-472913.servicebus.windows.net" \
  --tags project=inv-lab env=lab --output none
```

- **Sin `--ingress`**: `inv-projector` no recibe peticiones HTTP, así que la regla HTTP por defecto
  nunca la despertaría. Sin una regla propia, escalaría a cero y **no volvería a arrancar nunca**
  ([`04` §7](04-computo-y-contenedores.md#7--escalado-con-keda-y-escala-a-cero)).
- `--scale-rule-type azure-servicebus` es el scaler de KEDA para Service Bus. Sus metadatos dicen qué
  entidad mirar y `messageCount=5` fija el objetivo: una réplica por cada cinco mensajes pendientes, hasta
  `--max-replicas 3`.
- `--scale-rule-identity "$PROJ_ID"` autentica el scaler con la managed identity, sin una connection
  string guardada como secreto (el namespace no las admite).

> 📝 **A confirmar en la corrida: el rol que necesita el scaler.** El scaler consulta cuántos mensajes
> tiene la subscription, que es una lectura de **metadatos de la entidad**, no de mensajes. Ni la
> documentación de Container Apps ni la de KEDA fijan el rol mínimo para hacerlo con managed identity.
> Si con `Azure Service Bus Data Receiver` la app no escala (sección 10), los logs de sistema del scaler
> lo dirán con un error de autorización; la corrección probable es un rol con permisos de gestión de la
> entidad sobre el topic, como `Azure Service Bus Data Owner`, con el costo en privilegio que eso supone.
> La corrida del lab fija la respuesta y este aviso se sustituye por ella.

---

## 10. 🧱 Un movimiento, de punta a punta

El cliente máquina es el job de [`L06` §10](l06-identidad-de-aplicaciones-api-protegida.md#10--el-cliente-máquina-una-managed-identity),
ahora como generador de movimientos. El cuerpo llega por variable de entorno, así que cada ejecución
puede mandar uno distinto:

```bash
read -r -d '' SEND <<'EOF'
az login --identity --client-id "$CLIENT_ID" --allow-no-subscriptions --output none &&
for i in $(seq 1 "${COUNT:-1}"); do
  body=$(echo "$BODY" | sed "s/{i}/$i/g")
  az rest --method post --url "$API_URL/movements" --resource "api://$API_APP_ID" --body "$body" --output tsv --query movementId
done
EOF

az containerapp job create --name inv-movements --resource-group inv-lab-rg --environment inv-lab-env \
  --trigger-type Manual --replica-timeout 600 --replica-retry-limit 0 --parallelism 1 --replica-completion-count 1 \
  --image mcr.microsoft.com/azure-cli:2.90.0 --mi-user-assigned "$PROJ_ID" --cpu 0.25 --memory 0.5Gi \
  --env-vars CLIENT_ID="$PROJ_CLIENT_ID" API_APP_ID="$API_APP_ID" API_URL="https://$FQDN" \
  --command "/bin/bash" --args "-c" "$SEND" --tags project=inv-lab env=lab --output none
```

- `{i}` en el cuerpo se sustituye por el número de iteración: sirve para generar `movementId` distintos.
- `COUNT` dice cuántos movimientos mandar; por defecto, uno.

Un movimiento:

```bash
az containerapp job start --name inv-movements --resource-group inv-lab-rg \
  --env-vars CLIENT_ID="$PROJ_CLIENT_ID" API_APP_ID="$API_APP_ID" API_URL="https://$FQDN" \
             BODY='{"movementId":"mv-0001","storeId":"S-01","sku":"A-100","delta":5}' --query name --output tsv
```

- `job start --env-vars` sustituye las variables del contenedor **para esa ejecución**; por eso se
  repiten las tres fijas junto con `BODY`.

Espera un minuto y consulta el stock con un token de analista. El de [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) caducó (un access token
dura del orden de una hora): repite el device code de [`L06` §8](l06-identidad-de-aplicaciones-api-protegida.md#8--un-token-de-usuario-con-device-code-a-mano)
para tener `USER_TOKEN` otra vez.

```bash
curl -s -H "Authorization: Bearer $USER_TOKEN" "https://$FQDN/items?storeId=S-01"; echo
```

```text
[PENDIENTE DE CORRIDA] [{"id":"A-100","storeId":"S-01","quantity":5,"applied":["mv-0001"],...}]
```

El movimiento viajó entero: la API lo escribió en `events` y lo publicó; KEDA vio un mensaje pendiente
y despertó `inv-projector`; el projector lo aplicó a `stock` y lo completó. Ahora el escalado de verdad,
con cincuenta movimientos:

```bash
az containerapp job start --name inv-movements --resource-group inv-lab-rg \
  --env-vars CLIENT_ID="$PROJ_CLIENT_ID" API_APP_ID="$API_APP_ID" API_URL="https://$FQDN" COUNT=50 \
             BODY='{"movementId":"mv-bulk-{i}","storeId":"S-02","sku":"B-200","delta":1}' --output none

for t in 1 2 3 4 5 6; do
  echo "$(date +%H:%M:%S) replicas=$(az containerapp replica list --name inv-projector --resource-group inv-lab-rg --query 'length(@)')" \
       "active=$(az servicebus topic subscription show --name inv-projector --topic-name inv-events --namespace-name inv-lab-sb-472913 --resource-group inv-lab-rg --query countDetails.activeMessageCount)"
  sleep 30
done
```

- `countDetails.activeMessageCount` es el número de mensajes pendientes en la subscription: el mismo dato
  que mira el scaler.
- El scaler de KEDA consulta cada 30 segundos, así que el escalado va por pasos.

```text
[PENDIENTE DE CORRIDA] Réplicas subiendo de 0 a 1 y después hacia 3 mientras hay mensajes activos,
y activeMessageCount bajando hasta 0. Pasados unos cinco minutos sin mensajes, las réplicas vuelven
a 0.
```

---

## 11. 🩺 El duplicado que no duplica nada

Manda **el mismo** movimiento otra vez, como haría un cliente que reintenta porque no recibió respuesta:

```bash
az containerapp job start --name inv-movements --resource-group inv-lab-rg \
  --env-vars CLIENT_ID="$PROJ_CLIENT_ID" API_APP_ID="$API_APP_ID" API_URL="https://$FQDN" \
             BODY='{"movementId":"mv-0001","storeId":"S-01","sku":"A-100","delta":5}' --output none
sleep 60
curl -s -H "Authorization: Bearer $USER_TOKEN" "https://$FQDN/items?storeId=S-01"; echo
```

```text
[PENDIENTE DE CORRIDA] quantity sigue en 5 y applied sigue siendo ["mv-0001"].
```

Tres defensas, y conviene saber cuál actuó:

- **En Cosmos DB**, el upsert con `id = mv-0001` sustituyó el mismo item de `events`: sigue habiendo uno.
- **En Service Bus**, si el reenvío llegó dentro de la ventana de 10 minutos, **duplicate detection**
  descartó el mensaje por su `MessageId`: `inv-projector` ni lo vio.
- **En `inv-projector`**, si la ventana había pasado, el mensaje llegó y la lista `applied` lo delató.

Las tres son necesarias porque cada una cubre un caso distinto: duplicate detection protege del
**productor** que reenvía, dentro de una ventana; la idempotencia del consumidor protege de la
**redelivery** tras un lock expirado, que duplicate detection no ve nunca ([`13` §5](13-mensajeria-y-eventos.md#5--duplicados-sesiones-y-transacciones)).

---

## 12. 🩺 El mensaje envenenado, y la DLQ

Un movimiento sin SKU, que el projector nunca podrá aplicar:

```bash
az containerapp job start --name inv-movements --resource-group inv-lab-rg \
  --env-vars CLIENT_ID="$PROJ_CLIENT_ID" API_APP_ID="$API_APP_ID" API_URL="https://$FQDN" \
             BODY='{"movementId":"mv-poison-1","storeId":"S-01","delta":1}' --output none
```

Cada entrega falla, el lock de un minuto expira, el mensaje vuelve con el delivery count incrementado, y
al superar `MaxDeliveryCount` (5) el broker lo aparta. Obsérvalo durante unos minutos:

```bash
for t in $(seq 1 8); do
  az servicebus topic subscription show --name inv-projector --topic-name inv-events \
    --namespace-name inv-lab-sb-472913 --resource-group inv-lab-rg \
    --query "{time:updatedAt, active:countDetails.activeMessageCount, deadLetter:countDetails.deadLetterMessageCount}" \
    --output tsv
  sleep 60
done
az containerapp logs show --name inv-projector --resource-group inv-lab-rg --type console --tail 20 --format text
```

- `countDetails.deadLetterMessageCount` cuenta los mensajes en la **DLQ de la subscription**, la subcola
  `inv-projector/$deadletterqueue` que toda subscription trae incluida.
- Los logs de consola muestran la excepción del projector en cada intento.

```text
[PENDIENTE DE CORRIDA] active 1 y deadLetter 0 durante unos minutos (un intento por minuto, más el
tiempo de despertar al projector), y después active 0 y deadLetter 1. En los logs, cinco veces
"movimiento sin sku: mv-poison-1".
```

> 🩺 **Diagnóstico.** Para leer el motivo (`DeadLetterReason = MaxDeliveryCountExceeded`) hay que mirar
> el mensaje, que es una operación de data plane: el **Service Bus Explorer** del portal lo muestra con
> sus propiedades, siempre que tu usuario tenga un rol de datos de recepción sobre la subscription. La CLI
> solo da los contadores. Un mensaje en la DLQ **no se reintenta solo ni caduca por defecto**: alguien
> tiene que mirarlo, y [`L08`](l08-observabilidad-kql-y-auditoria.md) pone una alerta para que ese
> alguien se entere.

El sistema sigue funcionando: los mensajes buenos no esperaron al envenenado, porque la subscription no
tiene sesiones y cada mensaje se procesa por separado.

---

## 13. 🧪 Teardown, y lo que queda encendido

Borra el job de prueba; [`L08`](l08-observabilidad-kql-y-auditoria.md) lo recrea si lo necesita:

```bash
az containerapp job delete --name inv-movements --resource-group inv-lab-rg --yes
```

| Recurso | ¿Cobra? | Estado | Quién lo destruye |
|---|---|---|---|
| `inv-lab-sb-472913` (namespace, topic, subscription) | **$0.013441/h, ~$0.32/día** | Vivo; [`L08`](l08-observabilidad-kql-y-auditoria.md) lo usa | [`L09`](l09-costos-y-destruccion-verificada.md) |
| `inv-lab-cosmos-472913` | $0 en free tier; si no, $0.032/h | Viva; [`L08`](l08-observabilidad-kql-y-auditoria.md) la usa | [`L09`](l09-costos-y-destruccion-verificada.md) |
| `inv-projector` | Solo con réplicas, dentro del free grant | A cero | [`L09`](l09-costos-y-destruccion-verificada.md) |
| `inv-api` (`v6`) | Solo con réplicas | A cero | [`L09`](l09-costos-y-destruccion-verificada.md) |
| Roles de Cosmos DB y de Service Bus | No | Vivos | Con sus recursos |
| Items de carga en `store-load` | Dentro de los 25 GB del free tier | Vivos | Con la cuenta |

> 💰 **Si vas a pausar la serie más de un día**, Service Bus es lo que más cobra solo por existir. Puedes
> borrar el namespace (`az servicebus namespace delete --name inv-lab-sb-472913 --resource-group
> inv-lab-rg`) y recrearlo con los tres comandos de la sección 7 y sus dos role assignments antes de
> [`L08`](l08-observabilidad-kql-y-auditoria.md). Con Cosmos DB fuera del free tier, lo mismo aplica a la cuenta.

---

## 📋 Checklist de salida

- [ ] `az cosmosdb show --query "{free:enableFreeTier, local:disableLocalAuth}"` devuelve `true` y `true` (o sabes cuánto cuesta tu caso sin free tier).
- [ ] Los contenedores `events` y `stock` tienen partition key `/storeId` y comparten 400 RU/s de la base.
- [ ] Viste `429` en crudo con `curl` y lo encontraste en la métrica `TotalRequests` filtrada por `StatusCode`.
- [ ] Tu usuario ya no tiene rol de datos en Cosmos DB.
- [ ] Un movimiento llegó de `inv-api` a `stock` pasando por el topic, e `inv-projector` escaló desde cero.
- [ ] Reenviar `mv-0001` no cambió la cantidad.
- [ ] `deadLetterMessageCount` de la subscription es 1 tras el mensaje sin SKU.
- [ ] Anotaste qué rol necesitó de verdad el scaler de KEDA.

## 🏁 La señal de que quedó bien

`GET /items?storeId=S-01` devuelve `A-100` con `quantity` 5 aunque `mv-0001` se envió dos veces,
`GET /items?storeId=S-02` devuelve `B-200` con 50, la subscription tiene cero mensajes activos y uno en la
DLQ, e `inv-projector` está a cero réplicas.

---

## 🧠 Preguntas rápidas

1. ¿Qué pasa si creas la cuenta de Cosmos DB sin `--enable-free-tier` y por qué no se arregla después?
2. ¿Por qué `/storeId` es una buena partition key para `events` y `stock`, y por qué el `id` de `stock` es el SKU?
3. ¿Qué diferencia hay entre dar 400 RU/s a la base y darlos a cada contenedor?
4. ¿En qué se diferencian los roles de datos de Cosmos DB de los de Service Bus, y qué es el `--scope` de `az cosmosdb sql role assignment`?
5. ¿Qué cabeceras necesita una escritura REST en Cosmos DB con Entra ID y qué significa `type=aad`?
6. ¿Por qué el `429` se ve con `curl` y casi nunca con el SDK, y dónde lo ves en producción?
7. Todas las escrituras de la carga iban a `store-load`. ¿Qué te enseña eso sobre subir RU ante un `429`?
8. ¿Por qué `Data Sender` va sobre el topic y `Data Receiver` sobre la subscription?
9. ¿Qué hace idempotente la escritura de `inv-api` y qué hace idempotente la de `inv-projector`?
10. ¿Para qué sirve el `If-Match` con el ETag en `inv-projector` y qué pasa cuando falla?
11. ¿Por qué `inv-projector` necesita una regla de escalado propia y qué hace `messageCount=5`?
12. Reenviaste `mv-0001` y la cantidad no cambió. ¿Qué tres mecanismos pudieron evitarlo y cuál cubre la redelivery tras un lock expirado?
13. ¿Qué recorrido hace el mensaje sin SKU hasta la DLQ y cómo lo compruebas desde la CLI?
14. ¿Qué cobra por hora al terminar este lab y qué haces si vas a pausar la serie?

---

## 📚 Referencias oficiales

- Free tier de Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/free-tier
- Referencia de `az cosmosdb`: https://learn.microsoft.com/en-us/cli/azure/cosmosdb
- Partition keys: https://learn.microsoft.com/en-us/azure/cosmos-db/partitioning
- Throughput en base de datos y en contenedor: https://learn.microsoft.com/en-us/azure/cosmos-db/set-throughput
- RBAC del data plane de Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-connect-role-based-access-control
- Roles integrados del data plane de Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/reference-data-plane-security
- API REST de Cosmos DB, crear un documento: https://learn.microsoft.com/en-us/rest/api/cosmos-db/create-a-document
- Control de acceso de la API REST (`type=aad`): https://learn.microsoft.com/en-us/rest/api/cosmos-db/access-control-on-cosmosdb-resources
- Cabeceras comunes de la API REST de Cosmos DB: https://learn.microsoft.com/en-us/rest/api/cosmos-db/common-cosmosdb-rest-request-headers
- Códigos de estado de Cosmos DB: https://learn.microsoft.com/en-us/rest/api/cosmos-db/http-status-codes-for-cosmosdb
- Referencia de `az servicebus`: https://learn.microsoft.com/en-us/cli/azure/servicebus
- Autenticar Service Bus con Entra ID y sus roles: https://learn.microsoft.com/en-us/azure/service-bus-messaging/authenticate-application
- Duplicate detection: https://learn.microsoft.com/en-us/azure/service-bus-messaging/duplicate-detection
- Dead-letter queues de Service Bus: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues
- Service Bus Explorer: https://learn.microsoft.com/en-us/azure/service-bus-messaging/explorer
- Escalado de Container Apps (reglas y managed identity): https://learn.microsoft.com/en-us/azure/container-apps/scale-app
- Métricas soportadas de Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/monitor-reference
- Precios de Cosmos DB: https://azure.microsoft.com/en-us/pricing/details/cosmos-db/autoscale-provisioned/
- Precios de Service Bus: https://azure.microsoft.com/en-us/pricing/details/service-bus/

### Terceros (opcional)

- KEDA, scaler de Azure Service Bus: https://keda.sh/docs/2.17/scalers/azure-service-bus/
