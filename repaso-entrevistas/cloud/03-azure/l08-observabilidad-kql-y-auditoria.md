# L08 — Observabilidad: KQL y auditoría

> **Objetivo:** hacer observable el sistema de [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) sin tocar su código: Application Insights con el
> agente Java y **ingesta autenticada con la managed identity**, diagnostic settings de Service Bus y
> Key Vault hacia el workspace, el Activity Log de la suscripción en el mismo sitio, las consultas KQL
> que responden "qué falló", "quién leyó el secreto" y "quién borró qué", y una alerta de métrica sobre la
> DLQ que avisa al action group de [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md).
> **Se asume leído:** [`14`](14-observabilidad-monitor-log-analytics-app-insights.md) (Azure Monitor,
> Log Analytics, KQL, Application Insights y alertas). Complementa [`A05`](a05-kql-de-supervivencia.md).
> **Costo:** **~$0.00**. La ingesta del lab queda muy por debajo de los 5 GB gratuitos al mes del
> workspace, el Activity Log en `AzureActivity` no cobra ingesta, y la alerta de métrica vigila una sola
> serie, dentro de las diez gratuitas. Siguen corriendo los cargos de [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) y [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) (registry y Service
> Bus).
> **Duración:** 2–3 horas, buena parte esperando a que lleguen los datos.
> **Prerrequisitos:** [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) terminado, con un
> mensaje en la DLQ de `inv-projector`, y el workspace `inv-lab-law` de [`L05`](l05-container-apps-revisiones-trafico-y-escala.md).
> **Qué queda encendido al terminar:** lo mismo que dejó [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md), ahora observable: el recurso de
> Application Insights `inv-lab-appi`, tres diagnostic settings (Service Bus, Key Vault y **la
> suscripción**) y la alerta `inv-lab-dlq`. Nada cobra por hora.
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026. Agente Java de Application Insights **3.7.9**; extensión
> `application-insights` **1.2.3**.

**Salto rápido:** [Qué se practica](#1--qué-se-practica-y-el-orden-importa) · [Arranque](#2--arranque) ·
[Activity Log](#3--el-activity-log-al-workspace) · [Diagnostic settings](#4--diagnostic-settings-de-service-bus-y-key-vault) ·
[Application Insights](#5--application-insights-sin-credencial-de-ingesta) ·
[El agente](#6--el-agente-java-en-las-dos-apps) · [Telemetría que no llega](#7--la-telemetría-que-no-llega) ·
[Generar señal](#8--generar-señal) · [KQL de aplicación](#9--kql-lo-que-hizo-la-aplicación) ·
[KQL de auditoría](#10--kql-quién-leyó-el-secreto-y-quién-borró-qué) · [Alerta](#11--la-alerta-de-la-dlq) ·
[Teardown](#12--teardown-y-lo-que-sobrevive-al-resource-group) · [Checklist](#-checklist-de-salida) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Qué se practica, y el orden importa

La lección central de [`14` §1](14-observabilidad-monitor-log-analytics-app-insights.md#1--el-problema-azure-no-registra-todo-por-defecto)
cabe en una frase: **Azure no registra todo por defecto, y lo que no configuraste antes no se puede
consultar después.** Por eso este lab empieza configurando y termina consultando, y por eso las
consultas de la sección 10 solo encuentran lo que ocurrió **después** de las secciones 3 y 4.

```text
                          inv-lab-law  (Log Analytics workspace)
   ┌──────────────────────────┬───────────────────────┬──────────────────────────┐
   │ AppRequests, AppDeps…    │ AZKVAuditLogs         │ AzureActivity            │
   │ ▲ agente Java (MI)       │ AZMSOperationalLogs   │ ▲ diagnostic setting     │
   │ inv-api, inv-projector   │ ▲ diagnostic settings │   de la SUSCRIPCIÓN      │
   └──────────────────────────┴───────────────────────┴──────────────────────────┘
   Métrica DeadletteredMessages (sin configurar nada) ──► alerta inv-lab-dlq ──► inv-lab-ag ──► correo
```

La doctrina de reparto lo justifica: Prometheus y Grafana corren en local y enseñan observabilidad en
general, pero no el Activity Log, los diagnostic settings, las tablas de Log Analytics ni el agente de
Application Insights ([`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones)).

---

## 2. 🧱 Arranque

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
SUB=$(az account show --query id --output tsv)
LAW_ID=$(az monitor log-analytics workspace show --workspace-name inv-lab-law --resource-group inv-lab-rg --query id --output tsv)
LAW_CUSTOMER_ID=$(az monitor log-analytics workspace show --workspace-name inv-lab-law --resource-group inv-lab-rg --query customerId --output tsv)
API_CLIENT_ID=$(az identity show --name inv-api-id --resource-group inv-lab-rg --query clientId --output tsv)
API_PID=$(az identity show --name inv-api-id --resource-group inv-lab-rg --query principalId --output tsv)
PROJ_CLIENT_ID=$(az identity show --name inv-projector-id --resource-group inv-lab-rg --query clientId --output tsv)
PROJ_PID=$(az identity show --name inv-projector-id --resource-group inv-lab-rg --query principalId --output tsv)
az extension add --name application-insights --version 1.2.3
```

- `LAW_ID` es el resource ID del workspace, el destino de los diagnostic settings; `LAW_CUSTOMER_ID`, su
  GUID, el que pide `az monitor log-analytics query` ([`L05` §3](l05-container-apps-revisiones-trafico-y-escala.md#3--el-log-analytics-workspace-declarado)).
- `az monitor app-insights` vive en la extensión `application-insights`, no en el núcleo de la CLI.
  `1.2.3` es su última versión estable en el índice oficial a la fecha.

---

## 3. 🧱 El Activity Log, al workspace

El **Activity Log** registra las operaciones de control plane de la suscripción sin configurar nada,
pero solo lo guarda **90 días** y no se puede cruzar con los demás logs hasta que lo mandas a un
workspace ([`14` §3](14-observabilidad-monitor-log-analytics-app-insights.md#3--tres-fuentes-de-logs-y-quién-registra-qué)).
Eso se hace con un diagnostic setting **de la suscripción**, no de un recurso:

**Teardown antes que el despliegue:** este diagnostic setting vive en la **suscripción**, no en
`inv-lab-rg`. `az group delete` no lo borra, y tras borrar el workspace se queda apuntando a un destino
que no existe. [`L09`](l09-costos-y-destruccion-verificada.md) lo borra con `az monitor diagnostic-settings subscription delete`.

```bash
az monitor diagnostic-settings subscription create \
  --name inv-lab-activity \
  --location eastus2 \
  --workspace "$LAW_ID" \
  --logs '[{"category": "Administrative", "enabled": true},
           {"category": "Security", "enabled": true},
           {"category": "Policy", "enabled": true}]'
```

- `subscription create` crea el diagnostic setting en el scope de la suscripción activa.
- `--location` es donde se guarda el propio diagnostic setting; no filtra por región.
- `--logs` elige las categorías del Activity Log: `Administrative` son las operaciones de escritura y
  borrado sobre recursos, las que responden "quién borró qué"; `Security` y `Policy`, las alertas de
  Defender y las evaluaciones de Azure Policy. Hay otras (`ServiceHealth`, `Alert`, `Autoscale`…) que el
  lab no necesita.
- Los datos van a la tabla `AzureActivity`, que **no cobra ingesta** ([`14` §4](14-observabilidad-monitor-log-analytics-app-insights.md#4--el-log-analytics-workspace)).

```text
[PENDIENTE DE CORRIDA] JSON del diagnostic setting con workspaceId igual a LAW_ID y las tres
categorías habilitadas.
```

> ⚠️ **Solo se registra lo que ocurra desde ahora.** Lo que hiciste en [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md)–[`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) está en el Activity
> Log de la suscripción (90 días, consultable con `az monitor activity-log list`), pero **no** en el
> workspace: un diagnostic setting no rellena hacia atrás.

---

## 4. 🧱 Diagnostic settings de Service Bus y Key Vault

Los **resource logs** —las operaciones dentro de cada recurso— **no se guardan en ningún sitio** hasta
que un diagnostic setting los envía ([`14` §5](14-observabilidad-monitor-log-analytics-app-insights.md#5--diagnostic-settings)).
Primero, qué categorías ofrece cada recurso:

```bash
SB_ID=$(az servicebus namespace show --name inv-lab-sb-472913 --resource-group inv-lab-rg --query id --output tsv)
KV_ID=$(az keyvault show --name inv-lab-kv-472913 --query id --output tsv)
az monitor diagnostic-settings categories list --resource "$SB_ID" --query "value[?categoryType=='Logs'].name" --output tsv
az monitor diagnostic-settings categories list --resource "$KV_ID" --query "value[?categoryType=='Logs'].name" --output tsv
```

```text
[PENDIENTE DE CORRIDA] Service Bus: OperationalLogs, RuntimeAuditLogs, VNetAndIPFilteringLogs,
ApplicationMetricsLogs, DiagnosticErrorLogs (la lista exacta depende del tier). Key Vault:
AuditEvent y AzurePolicyEvaluationDetails.
```

Y los dos diagnostic settings, con tablas específicas del servicio:

```bash
az monitor diagnostic-settings create --name to-law --resource "$SB_ID" --workspace "$LAW_ID" \
  --logs '[{"category": "OperationalLogs", "enabled": true}]' \
  --export-to-resource-specific true --output none

az monitor diagnostic-settings create --name to-law --resource "$KV_ID" --workspace "$LAW_ID" \
  --logs '[{"category": "AuditEvent", "enabled": true}]' \
  --export-to-resource-specific true --output none
```

- Se elige **una categoría concreta** por recurso, en vez del grupo `allLogs` de `14` §5: en producción,
  lo que no se va a mirar no se ingiere.
- `OperationalLogs` de Service Bus registra las operaciones de gestión sobre el namespace y sus
  entidades; va a la tabla `AZMSOperationalLogs`. Las auditorías de acceso a mensajes
  (`RuntimeAuditLogs`) solo existen en el tier Premium.
- `AuditEvent` de Key Vault registra **cada** operación sobre el vault, incluidas las de data plane como
  leer un secreto; va a `AZKVAuditLogs`.
- `--export-to-resource-specific true` escribe en esas tablas propias en vez de en `AzureDiagnostics`.

**Teardown:** cada diagnostic setting cuelga de su recurso y se va con él. El de Key Vault, con el vault
soft-deleted, deja de enviar; el purge de [`L09`](l09-costos-y-destruccion-verificada.md) lo elimina del todo.

---

## 5. 🧱 Application Insights, sin credencial de ingesta

Application Insights basado en workspace escribe en tablas de `inv-lab-law` (`AppRequests`,
`AppDependencies`, `AppExceptions`, `AppTraces`) ([`14` §7](14-observabilidad-monitor-log-analytics-app-insights.md#7--application-insights-para-spring-boot)).

**Teardown:** el recurso vive en `inv-lab-rg` y muere con él; sus datos viven en el workspace y se van
con el workspace.

```bash
az monitor app-insights component create \
  --app inv-lab-appi \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --workspace "$LAW_ID" \
  --kind web --application-type web \
  --tags project=inv-lab env=lab --output none
APPI_ID=$(az monitor app-insights component show --app inv-lab-appi --resource-group inv-lab-rg --query id --output tsv)
APPI_CONN=$(az monitor app-insights component show --app inv-lab-appi --resource-group inv-lab-rg --query connectionString --output tsv)
```

- `--workspace "$LAW_ID"` lo hace **basado en workspace**, el único modelo que existe hoy.
- `--kind web --application-type web` es el tipo para aplicaciones web y APIs.
- La **connection string** identifica el recurso y su endpoint de ingesta. Por sí sola, con la
  autenticación local habilitada, **basta para enviar telemetría**: cualquiera que la tenga puede
  escribir en tu Application Insights.

Por eso el lab la deshabilita, y la ingesta pasa a exigir un token de Entra ID:

```bash
az resource update --ids "$APPI_ID" --set properties.DisableLocalAuth=true \
  --query properties.DisableLocalAuth
```

- No hay un flag dedicado en `az monitor app-insights component`: se usa `az resource update --set`,
  que hace un `PATCH` genérico sobre cualquier propiedad del recurso ([`A01` §1](a01-az-de-supervivencia.md#1--qué-es-az-y-qué-no-es)).
- Con `DisableLocalAuth=true`, solo acepta telemetría autenticada con Entra ID de una identidad con el
  rol **Monitoring Metrics Publisher** sobre el recurso. A pesar del nombre, ese rol publica **toda** la
  telemetría, no solo métricas.

```text
[PENDIENTE DE CORRIDA] true
```

> 🧠 **Modelo mental.** Es el mismo movimiento que `--allow-shared-key-access false` en Storage,
> `--disable-local-auth` en Service Bus y en Cosmos DB: quitar la credencial compartida del recurso para
> que la única puerta sea una identidad con un rol. La connection string se queda, pero ya no es una
> credencial.

---

## 6. 🧱 El agente Java, en las dos apps

El agente se añade a la imagen, sin tocar el código. En el `Dockerfile` de las dos apps:

```dockerfile
# Dockerfile de inv-api (e inv-projector): el agente se descarga en el build y se adjunta a la JVM
FROM mcr.microsoft.com/openjdk/jdk:21-distroless@sha256:ea7cd567f254e745a9663e8bb8ed2d49f3728a76f9f48f22a0a88d86b1dd12bf
ADD https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.7.9/applicationinsights-agent-3.7.9.jar /opt/agent/applicationinsights-agent.jar
COPY target/inv-api.jar /app/inv-api.jar
USER app
ENV JAVA_TOOL_OPTIONS="-javaagent:/opt/agent/applicationinsights-agent.jar"
CMD ["-jar", "/app/inv-api.jar"]
```

- `ADD <url>` descarga el agente **3.7.9**, la versión fija de [`14` §7](14-observabilidad-monitor-log-analytics-app-insights.md#7--application-insights-para-spring-boot).
  En una imagen distroless no hay `curl` ni shell: `ADD` es la forma de traerlo.
- `JAVA_TOOL_OPTIONS` hace que la JVM cargue el agente al arrancar; la JVM lee esa variable sola, así que
  el `CMD` de [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) no cambia. Es la diferencia con el `Dockerfile` de `14` §7, escrito para una imagen
  con `java` en el `ENTRYPOINT` propio.
- En `inv-projector` cambia solo el nombre del JAR.

Construye `inv-api:0.4.1` e `inv-projector:0.1.1` (mismo código, imagen con agente) y súbelas como en
[`L05`](l05-container-apps-revisiones-trafico-y-escala.md). **Todavía no** asignes el rol de publicación: la sección 7 lo necesita sin él.

Las variables del agente, en cada app, con una revisión nueva:

```bash
az containerapp update --name inv-api --resource-group inv-lab-rg \
  --image invlabacr472913.azurecr.io/inv-api:0.4.1 --revision-suffix v7 \
  --set-env-vars APPLICATIONINSIGHTS_CONNECTION_STRING="$APPI_CONN" \
                 APPLICATIONINSIGHTS_AUTHENTICATION_STRING="Authorization=AAD;ClientId=$API_CLIENT_ID" \
                 APPLICATIONINSIGHTS_CONFIGURATION_CONTENT='{"role":{"name":"inv-api"}}' --output none
az containerapp ingress traffic set --name inv-api --resource-group inv-lab-rg \
  --revision-weight inv-api--v6=0 inv-api--v7=100 --output none

az containerapp update --name inv-projector --resource-group inv-lab-rg \
  --image invlabacr472913.azurecr.io/inv-projector:0.1.1 \
  --set-env-vars APPLICATIONINSIGHTS_CONNECTION_STRING="$APPI_CONN" \
                 APPLICATIONINSIGHTS_AUTHENTICATION_STRING="Authorization=AAD;ClientId=$PROJ_CLIENT_ID" \
                 APPLICATIONINSIGHTS_CONFIGURATION_CONTENT='{"role":{"name":"inv-projector"}}' --output none
```

- `APPLICATIONINSIGHTS_CONNECTION_STRING` dice **a dónde** enviar. Va como variable normal y no como
  secreto porque, con la autenticación local deshabilitada, no permite enviar nada por sí sola.
- `APPLICATIONINSIGHTS_AUTHENTICATION_STRING="Authorization=AAD;ClientId=<clientId>"` dice **con qué
  identidad** autenticarse: la user-assigned de cada app, elegida por su `clientId`.
- `APPLICATIONINSIGHTS_CONFIGURATION_CONTENT` pasa configuración del agente en JSON sin archivo; aquí,
  el **cloud role name**, que es el `AppRoleName` de las consultas y el nombre del nodo en el
  Application Map. Sin él, las dos apps saldrían con un nombre derivado del entorno.
- `inv-projector` está en modo single: la revisión nueva sustituye a la anterior sola.

---

## 7. 🩺 La telemetría que no llega

Genera algo de tráfico contra `inv-api` y espera unos minutos:

```bash
FQDN=$(az containerapp show --name inv-api --resource-group inv-lab-rg --query properties.configuration.ingress.fqdn --output tsv)
for i in $(seq 1 20); do curl -s -o /dev/null "https://$FQDN/api/info"; done

az monitor log-analytics query --workspace "$LAW_CUSTOMER_ID" \
  --analytics-query "AppRequests | where TimeGenerated > ago(30m) | summarize count() by AppRoleName" \
  --output table
```

- `--workspace` recibe el **GUID** del workspace (`customerId`), no su nombre ni su resource ID.
- `--analytics-query` es la consulta KQL.

```text
[PENDIENTE DE CORRIDA] Vacío: ninguna petición registrada.
```

Nada. La app funciona, el agente está cargado, y no llega ni una fila. El diagnóstico, en los logs de
consola de la app, donde el agente escribe sus propios problemas:

```bash
az containerapp logs show --name inv-api --resource-group inv-lab-rg --revision inv-api--v7 \
  --type console --tail 50 --format text | grep -i -E "applicationinsights|403|forbidden|unauthorized"
```

```text
[PENDIENTE DE CORRIDA] Mensajes del agente de Application Insights avisando de que la ingesta
rechaza la telemetría por falta de autorización (403).
```

El agente obtiene un token con la managed identity sin problema, pero la identidad **no tiene
permiso** para publicar en `inv-lab-appi`. Es el mismo patrón de [`L02`](l02-entra-id-rbac-y-managed-identities.md) en otro servicio: un token válido
sin el rol de datos. La corrección:

```bash
for pid in "$API_PID" "$PROJ_PID"; do
  az role assignment create --assignee-object-id "$pid" --assignee-principal-type ServicePrincipal \
    --role "Monitoring Metrics Publisher" --scope "$APPI_ID" --output none
done
```

- El rol se da **sobre el recurso de Application Insights**, no sobre el workspace ni el grupo.

Espera la propagación (hasta 10 minutos), repite el tráfico y la consulta:

```text
[PENDIENTE DE CORRIDA] Una fila: inv-api con unas 20 peticiones. La ingesta tarda unos minutos
en aparecer en el workspace.
```

> 🩺 **Diagnóstico.** "La telemetría no llega" tiene tres sospechosos, en este orden: la ingesta tarda
> minutos (espera antes de dudar); el agente no se cargó (busca su banner de arranque en los logs de
> consola); o la ingesta se rechaza (connection string equivocada, o autenticación de Entra ID sin el
> rol). Los logs de consola de la app responden los tres.

---

## 8. 🧱 Generar señal

Para que las consultas tengan algo que encontrar, cuatro acciones, cada una con su huella:

```bash
# 1. peticiones buenas y malas a inv-api: AppRequests
for i in $(seq 1 30); do curl -s -o /dev/null "https://$FQDN/api/info"; done
for i in $(seq 1 10); do curl -s -o /dev/null "https://$FQDN/items"; done     # 401: sin token

# 2. un secreto leído por ti: AZKVAuditLogs
az keyvault secret show --vault-name inv-lab-kv-472913 --name partner-api-key --query name --output tsv

# 3. un recurso creado y borrado: AzureActivity
az identity create --name inv-audit-demo-id --resource-group inv-lab-rg --location eastus2 \
  --tags project=inv-lab env=lab --output none
az identity delete --name inv-audit-demo-id --resource-group inv-lab-rg
```

- Las diez peticiones a `/items` sin token producen `401`: fallos que la consulta de error de la sección
  9 tiene que encontrar.
- Leer el secreto con tu usuario (tienes `Key Vault Secrets Officer` desde [`L02`](l02-entra-id-rbac-y-managed-identities.md)) deja una fila con tu
  identidad en `AZKVAuditLogs`. El `--query name` evita imprimir el valor.
- Crear y borrar una identidad deja dos operaciones de control plane en el Activity Log.

Y un movimiento de punta a punta, para la correlación: arranca una ejecución del job de
[`L07` §10](l07-datos-y-eventos-cosmos-db-y-service-bus.md#10--un-movimiento-de-punta-a-punta) si lo
conservas, o recréalo con el mismo comando. Espera cinco minutos antes de consultar: es lo que tardan en
llegar los datos.

---

## 9. 🧱 KQL: lo que hizo la aplicación

Las consultas se escriben igual en el portal (Logs del workspace) que en la CLI. La primera, la tasa de
error por operación de [`14` §6](14-observabilidad-monitor-log-analytics-app-insights.md#6--kql-lo-justo-para-diagnosticar):

```bash
az monitor log-analytics query --workspace "$LAW_CUSTOMER_ID" --output table --analytics-query '
AppRequests
| where TimeGenerated > ago(1h) and AppRoleName == "inv-api"
| summarize requests = count(), failed = countif(Success == false) by Name, ResultCode
| order by requests desc'
```

- `summarize ... by Name, ResultCode` agrupa por operación y código: separa el `401` de `/items` del
  `200` de `/api/info`.

```text
[PENDIENTE DE CORRIDA] Filas como "GET /api/info 200" con ~50 peticiones y "GET /items 401" con 10
fallidas.
```

La segunda, la correlación de un movimiento entre las dos apps por `OperationId`
([`14`](14-observabilidad-monitor-log-analytics-app-insights.md), pregunta 10):

```bash
az monitor log-analytics query --workspace "$LAW_CUSTOMER_ID" --output table --analytics-query '
let op = toscalar(AppRequests
    | where TimeGenerated > ago(1h) and AppRoleName == "inv-api" and Name has "movements"
    | top 1 by TimeGenerated desc | project OperationId);
union AppRequests, AppDependencies
| where OperationId == op
| project TimeGenerated, AppRoleName, Table = Type, Name, DependencyType, Target, DurationMs, Success
| order by TimeGenerated asc'
```

- `let op = toscalar(...)` guarda en una variable el `OperationId` del último `POST /movements`.
- `union AppRequests, AppDependencies` junta las dos tablas y `where OperationId == op` se queda con
  todo lo que pertenece a esa operación, venga de la app que venga.
- `Type` es la columna que **toda** tabla de Log Analytics tiene con su propio nombre: aquí distingue
  las filas de `AppRequests` de las de `AppDependencies`. El tipo de dependencia (HTTP, Azure Service
  Bus, Azure Cosmos DB…) está en `DependencyType`.

```text
[PENDIENTE DE CORRIDA] La petición POST /movements de inv-api, sus dependencias (la escritura en
Cosmos DB y el envío a Service Bus) y, con el mismo OperationId, la dependencia o la petición de
procesamiento registrada por inv-projector al consumir el mensaje, con sus propias dependencias de
Cosmos DB.
```

Ese `OperationId` compartido es la **correlación distribuida**: el agente propaga el contexto W3C Trace
Context como propiedad del mensaje de Service Bus, y el agente de `inv-projector` continúa la misma
traza. Es lo que el Application Map del portal dibuja como un grafo.

---

## 10. 🧱 KQL: quién leyó el secreto, y quién borró qué

La pregunta de auditoría de [`14`](14-observabilidad-monitor-log-analytics-app-insights.md) (pregunta
3), respondida:

```bash
az monitor log-analytics query --workspace "$LAW_CUSTOMER_ID" --output table --analytics-query '
AZKVAuditLogs
| where TimeGenerated > ago(1h) and OperationName == "SecretGet"
| project TimeGenerated, CallerObjectId = tostring(Identity.claim.oid), CallerIpAddress, ResultType, Id
| order by TimeGenerated desc'
```

- `OperationName == "SecretGet"` son las lecturas de secretos. Existen otras (`SecretSet`,
  `SecretList`, `VaultGet`…).
- `Identity` es un campo dinámico con los claims del token del llamante; `tostring(Identity.claim.oid)`
  extrae el object ID. Si el esquema de tu tabla lo expone en otra columna, la vista de la tabla en el
  portal lo muestra.

```text
[PENDIENTE DE CORRIDA] Una fila con tu object ID, tu IP pública, ResultType Success y la URI del
secreto. Si inv-api reinició una revisión desde la sección 4, también las lecturas de la Key Vault
reference con el object ID de inv-api-id.
```

Y "quién borró qué", sobre el Activity Log que ahora llega al workspace:

```bash
az monitor log-analytics query --workspace "$LAW_CUSTOMER_ID" --output table --analytics-query '
AzureActivity
| where TimeGenerated > ago(2h) and ResourceGroup =~ "inv-lab-rg"
| where OperationNameValue endswith "/delete" or OperationNameValue endswith "/write"
| where ActivityStatusValue == "Success"
| project TimeGenerated, Caller, OperationNameValue, Resource = tostring(split(_ResourceId, "/")[-1])'
```

- `Caller` es quién hizo la operación: un correo para un usuario, un GUID para un service principal.
- `ActivityStatusValue == "Success"` descarta las filas intermedias (`Start`, `Accept`) que registra
  cada operación de larga duración.
- `split(_ResourceId, "/")[-1]` se queda con el último segmento del resource ID: el nombre del recurso.

```text
[PENDIENTE DE CORRIDA] La creación y el borrado de inv-audit-demo-id
(MICROSOFT.MANAGEDIDENTITY/USERASSIGNEDIDENTITIES/WRITE y /DELETE), con tu usuario como Caller,
además de los role assignments de la sección 7 y las revisiones de Container Apps.
```

> 📝 **La lectura del secreto no está en el Activity Log.** Leer un secreto es una operación de **data
> plane**, y el Activity Log solo registra el control plane. Sin el diagnostic setting de la sección 4,
> esa lectura no habría quedado en ningún sitio consultable. Es la respuesta completa a "¿quién leyó el
> secreto ayer?": solo lo sabes si lo configuraste antes de ayer.

---

## 11. 🧱 La alerta de la DLQ

La DLQ de la subscription tiene un mensaje desde [`L07` §12](l07-datos-y-eventos-cosmos-db-y-service-bus.md#12--el-mensaje-envenenado-y-la-dlq).
Nadie se enteró. Una **alerta de métrica** lo resuelve sin desplegar nada: Service Bus publica la
métrica `DeadletteredMessages` sin configurar nada, con la dimensión `EntityName`.

> 💰 **Costo.** Las alertas de métrica tienen las **primeras 10 series vigiladas gratis**; después,
> $0.10 por serie y mes ([`14` §8](14-observabilidad-monitor-log-analytics-app-insights.md#8--alertas-y-action-groups)).
> Esta vigila una.

**Teardown:** la regla vive en `inv-lab-rg` y muere con él.

```bash
AG_ID=$(az monitor action-group show --name inv-lab-ag --resource-group inv-lab-rg --query id --output tsv)
az monitor metrics alert create \
  --name inv-lab-dlq \
  --resource-group inv-lab-rg \
  --scopes "$SB_ID" \
  --condition "max DeadletteredMessages > 0 where EntityName includes inv-events" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action "$AG_ID" \
  --description "Hay mensajes en la DLQ de inv-events: alguien tiene que mirarlos" \
  --tags project=inv-lab env=lab --output none
```

- `--scopes "$SB_ID"`: la métrica es del namespace.
- `--condition "max DeadletteredMessages > 0 where EntityName includes inv-events"`: la agregación
  (`max`), la métrica, el operador y el umbral, y un filtro de dimensión que la limita al topic. La
  métrica cuenta los mensajes en dead-letter de la entidad, incluidas las DLQ de sus subscriptions.
- `--window-size 5m --evaluation-frequency 1m`: cada minuto mira los últimos cinco.
- `--severity 2` es advertencia (0 crítica, 4 informativa).
- `--action "$AG_ID"` dispara el action group de [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md), que manda el correo.

Como la DLQ ya tiene un mensaje, la alerta se dispara en su primera evaluación:

```bash
sleep 300
az monitor metrics alert show --name inv-lab-dlq --resource-group inv-lab-rg \
  --query "{enabled:enabled, condition:criteria.allOf[0].metricName, threshold:criteria.allOf[0].threshold}"
```

```text
[PENDIENTE DE CORRIDA] enabled true, DeadletteredMessages y threshold 0. En unos minutos, un correo
del action group inv-lab-ag con la alerta inv-lab-dlq en estado Fired.
```

> 🧠 **Modelo mental.** Una DLQ que nadie vigila es un cementerio de pedidos. La alerta no arregla el
> mensaje: garantiza que una persona lo mire. Y es de **métrica** a propósito: llega en un minuto y es
> casi gratis, frente a una alerta de log que tardaría la ingesta más su frecuencia y cobraría por regla.

---

## 12. 🧪 Teardown, y lo que sobrevive al resource group

| Objeto | Scope | ¿Cobra? | Quién lo destruye |
|---|---|---|---|
| `inv-lab-appi` | `inv-lab-rg` | Por ingesta, dentro de los 5 GB gratis | [`L09`](l09-costos-y-destruccion-verificada.md), con el grupo |
| Diagnostic settings de Service Bus y Key Vault | Cada recurso | No (la ingesta, sí) | Con sus recursos |
| **`inv-lab-activity`** | **La suscripción** | No | **[`L09`](l09-costos-y-destruccion-verificada.md), aparte: `az group delete` no lo toca** |
| `inv-lab-dlq` | `inv-lab-rg` | No (1 serie de 10 gratis) | [`L09`](l09-costos-y-destruccion-verificada.md), con el grupo |
| Role assignments `Monitoring Metrics Publisher` | `inv-lab-appi` | No | Con el recurso |
| Datos en `inv-lab-law` | El workspace | Retención incluida | Con el workspace, en [`L09`](l09-costos-y-destruccion-verificada.md) |

Comprobación de lo que quedó en el scope de la suscripción, que es lo que más se olvida:

```bash
az monitor diagnostic-settings subscription list --query "value[].{name:name, workspace:workspaceId}" --output table
```

```text
[PENDIENTE DE CORRIDA] Una fila: inv-lab-activity apuntando a inv-lab-law.
```

---

## 📋 Checklist de salida

- [ ] `az monitor diagnostic-settings subscription list` muestra `inv-lab-activity`, y sabes que [`L09`](l09-costos-y-destruccion-verificada.md) tiene que borrarlo aparte.
- [ ] Service Bus y Key Vault tienen un diagnostic setting `to-law` con tablas específicas del servicio.
- [ ] `inv-lab-appi` tiene `DisableLocalAuth` en `true` y las dos identidades tienen `Monitoring Metrics Publisher` sobre él.
- [ ] Viste la telemetría rechazada sin el rol y llegando con él.
- [ ] La consulta de error por operación separa los `401` de `/items`.
- [ ] Seguiste un `POST /movements` hasta `inv-projector` por su `OperationId`.
- [ ] Encontraste tu lectura del secreto en `AZKVAuditLogs` y el borrado de `inv-audit-demo-id` en `AzureActivity`.
- [ ] Recibiste el correo de la alerta `inv-lab-dlq`.

## 🏁 La señal de que quedó bien

Una sola consulta KQL por pregunta responde qué peticiones fallaron, quién leyó el secreto y quién
borró qué; el Application Map muestra `inv-api` → Service Bus → `inv-projector` → Cosmos DB con los
nombres de rol correctos; y el correo de la DLQ llegó sin que desplegaras nada que vigile.

---

## 🧠 Preguntas rápidas

1. ¿Por qué las consultas de este lab solo encuentran lo que ocurrió después de las secciones 3 y 4?
2. ¿Dónde vive el diagnostic setting del Activity Log y por qué importa para el teardown?
3. ¿Qué categorías del Activity Log responden "quién borró qué" y a qué tabla van?
4. ¿Por qué el lab elige `OperationalLogs` y `AuditEvent` en vez del grupo `allLogs`?
5. ¿Por qué una connection string de Application Insights puede ser una credencial y qué la deja de hacer serlo?
6. ¿Qué dicen `APPLICATIONINSIGHTS_AUTHENTICATION_STRING` y `APPLICATIONINSIGHTS_CONFIGURATION_CONTENT` al agente?
7. La app funciona y no llega telemetría. ¿Qué tres causas revisas y dónde las ves?
8. ¿Qué rol necesita una identidad para enviar telemetría con Entra ID y sobre qué scope?
9. ¿Qué parámetro espera `az monitor log-analytics query --workspace`?
10. ¿Cómo sigues un movimiento de `inv-api` a `inv-projector` en KQL y qué hace posible esa correlación?
11. ¿Por qué la lectura del secreto aparece en `AZKVAuditLogs` y no en `AzureActivity`?
12. ¿Qué significa la condición `max DeadletteredMessages > 0 where EntityName includes inv-events` y por qué es una alerta de métrica y no de log?

---

## 📚 Referencias oficiales

- Activity Log y su envío a Log Analytics: https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log
- Diagnostic settings: https://learn.microsoft.com/en-us/azure/azure-monitor/data-collection/diagnostic-settings
- Referencia de `az monitor diagnostic-settings`: https://learn.microsoft.com/en-us/cli/azure/monitor/diagnostic-settings
- Referencia de `az monitor diagnostic-settings subscription`: https://learn.microsoft.com/en-us/cli/azure/monitor/diagnostic-settings/subscription
- Logs y métricas de Service Bus: https://learn.microsoft.com/en-us/azure/service-bus-messaging/monitor-service-bus-reference
- Logs de Key Vault: https://learn.microsoft.com/en-us/azure/key-vault/general/monitor-key-vault-reference
- Application Insights basado en workspace: https://learn.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource
- Referencia de `az monitor app-insights component`: https://learn.microsoft.com/en-us/cli/azure/monitor/app-insights/component
- Autenticación de Entra ID para Application Insights: https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-ad-authentication
- Configuración del agente Java: https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-standalone-config
- Referencia de `az monitor log-analytics query`: https://learn.microsoft.com/en-us/cli/azure/monitor/log-analytics
- Alertas de métrica: https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-types
- Referencia de `az monitor metrics alert`: https://learn.microsoft.com/en-us/cli/azure/monitor/metrics/alert
- Precios de Azure Monitor: https://azure.microsoft.com/en-us/pricing/details/monitor/
