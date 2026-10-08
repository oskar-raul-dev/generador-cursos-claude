# A05 — KQL de supervivencia

> **Objetivo:** tener a mano las consultas KQL que se usan de verdad en un diagnóstico y en una
> entrevista: los operadores que resuelven el 90 % de los casos, recetas para la aplicación, Container
> Apps, la auditoría, el costo de la ingesta y el inventario con Resource Graph, y las trampas que dan
> resultados equivocados sin dar error.
> **Se asume leído:** [`14` §6](14-observabilidad-monitor-log-analytics-app-insights.md#6--kql-lo-justo-para-diagnosticar)
> (KQL lo justo). Las tablas son las que llenó [`L08`](l08-observabilidad-kql-y-auditoria.md).
> **Vigencia:** 29 de septiembre de 2026. Los nombres de tabla y de columna son los de la referencia de
> tablas de Azure Monitor a esa fecha.

**Salto rápido:** [Dónde se ejecuta](#1--dónde-se-ejecuta-kql) · [La forma](#2--la-forma-de-una-consulta) ·
[Operadores](#3--los-operadores-que-resuelven-el-90-) · [Aplicación](#4--recetas-la-aplicación) ·
[Container Apps](#5--recetas-container-apps) · [Auditoría](#6--recetas-auditoría) ·
[Costo](#7--recetas-el-costo-de-la-ingesta) · [Resource Graph](#8--recetas-inventario-con-resource-graph) ·
[Trampas](#9-️-las-trampas-que-no-dan-error) · [Chuleta](#10--chuleta) · [Preguntas](#-preguntas-rápidas)

Este apéndice no tiene orden: se entra por la receta que necesitas. Todas se escriben igual en el
editor de Logs del portal que en la CLI.

---

## 1. 🧭 Dónde se ejecuta KQL

El mismo lenguaje, tres sitios, y no son intercambiables:

| Dónde | Qué consulta | Cómo desde la CLI |
|---|---|---|
| **Log Analytics** | Logs: lo que **pasó** y alguien envió al workspace | `az monitor log-analytics query --workspace <customerId> --analytics-query "…"` |
| **Resource Graph** | Inventario: cómo **están** los recursos ahora | `az graph query --graph-query "…"` (extensión `resource-graph`) |
| **Application Insights** | Las mismas tablas `App*` de su workspace | Igual que Log Analytics, sobre el workspace |

```bash
az monitor log-analytics query --workspace "$LAW_CUSTOMER_ID" --timespan P1D --output table \
  --analytics-query 'AppRequests | summarize count() by AppRoleName'
```

- `--workspace` recibe el **GUID** del workspace (`customerId`), no su nombre ni su resource ID
  ([`L05` §3](l05-container-apps-revisiones-trafico-y-escala.md#3--el-log-analytics-workspace-declarado)).
- `--timespan P1D` acota el tiempo en duración ISO 8601 además de lo que diga la consulta. Un `where
  TimeGenerated > ago(…)` dentro de la consulta es lo que lo hace explícito para quien la lea.
- Las comillas simples alrededor de la consulta dejan usar comillas dobles dentro, que es lo habitual en
  KQL.

> 🧠 **Modelo mental.** Log Analytics responde "¿qué pasó?"; Resource Graph, "¿cómo está?". Buscar en
> Log Analytics si una storage account tiene acceso público es buscar en el diario lo que se ve mirando
> por la ventana.

---

## 2. 🧱 La forma de una consulta

Una tabla y una cadena de operadores separados por `|`. Cada operador recibe la tabla que produce el
anterior:

```kusto
AppRequests                                   // 1. la tabla
| where TimeGenerated > ago(1h)               // 2. el tiempo, SIEMPRE primero
| where AppRoleName == "inv-api"              // 3. el resto de filtros
| summarize requests = count() by Name        // 4. agregar
| order by requests desc                      // 5. ordenar
| take 10                                     // 6. limitar
```

- **Filtrar por tiempo primero** es lo que más reduce lo que se lee: las tablas están particionadas por
  tiempo, y en los planes que cobran por GB analizado, también lo que se paga.
- `//` comenta hasta el final de la línea.
- Una consulta sin `where` de tiempo en una tabla grande es la forma más rápida de esperar un minuto para
  nada.

---

## 3. 🧱 Los operadores que resuelven el 90 %

| Operador | Qué hace | Ejemplo |
|---|---|---|
| `where` | Filtra filas | `where Success == false` |
| `project` | Elige, renombra y ordena columnas | `project TimeGenerated, Name, Code = ResultCode` |
| `extend` | Añade una columna calculada | `extend secs = DurationMs / 1000.0` |
| `summarize … by` | Agrega por grupos | `summarize count(), avg(DurationMs) by Name` |
| `bin()` | Agrupa el tiempo en ventanas | `by bin(TimeGenerated, 5m)` |
| `order by` / `top` / `take` | Ordena, los N primeros, N cualesquiera | `top 5 by DurationMs desc` |
| `join kind=…` | Une dos tablas por una clave | `join kind=inner (AppDependencies) on OperationId` |
| `union` | Junta filas de varias tablas | `union AppRequests, AppDependencies` |
| `let` | Nombra un valor o una subconsulta | `let op = toscalar(...);` |
| `tostring()`, `toint()` | Convierte tipos, sobre todo de columnas `dynamic` | `tostring(Identity.claim.oid)` |
| `mv-expand` | Una fila por cada elemento de un array | `mv-expand roles` |
| `render` | Dibuja el resultado en el portal | `render timechart` |

Las funciones de agregación que más se usan dentro de `summarize`: `count()`, `countif(cond)`,
`dcount(col)` (distintos, aproximado), `sum()`, `avg()`, `max()`, `percentile(col, 95)`, `make_set(col)`
(los valores distintos en un array).

Y los comparadores de texto, que tienen trampa (§9): `==` distingue mayúsculas y `=~` no; `has` busca
un **término** completo usando el índice; `contains`, cualquier subcadena, sin índice; `startswith` y
`endswith`, por los extremos.

---

## 4. 🩺 Recetas: la aplicación

**Tasa de error por operación**, la pregunta 9 de [`14`](14-observabilidad-monitor-log-analytics-app-insights.md):

```kusto
AppRequests
| where TimeGenerated > ago(1h) and AppRoleName == "inv-api"
| summarize requests = count(), failed = countif(Success == false) by Name
| extend error_rate = round(100.0 * failed / requests, 2)
| order by error_rate desc
```

**Latencia p50/p95/p99 por operación, en ventanas de 5 minutos:**

```kusto
AppRequests
| where TimeGenerated > ago(6h) and AppRoleName == "inv-api"
| summarize p50 = percentile(DurationMs, 50), p95 = percentile(DurationMs, 95), p99 = percentile(DurationMs, 99)
          by bin(TimeGenerated, 5m), Name
| render timechart
```

- La media esconde la cola: una API con p50 de 20 ms y p99 de 4 s tiene un problema que `avg()` no
  enseña.

**Dependencias que fallan, por destino:**

```kusto
AppDependencies
| where TimeGenerated > ago(1h) and Success == false
| summarize failures = count(), codes = make_set(ResultCode) by AppRoleName, DependencyType, Target
| order by failures desc
```

- `DependencyType` dice qué es (HTTP, Azure Service Bus, Azure Cosmos DB…); `Target`, a dónde.
  `make_set(ResultCode)` junta los códigos distintos en un array.

**Las excepciones más frecuentes:**

```kusto
AppExceptions
| where TimeGenerated > ago(24h)
| summarize count() by AppRoleName, ExceptionType, OuterMessage
| top 10 by count_
```

- `count_` es el nombre que KQL da a la columna de `count()` cuando no le pones nombre.

**Una operación entera, de punta a punta**, la correlación de [`L08` §9](l08-observabilidad-kql-y-auditoria.md#9--kql-lo-que-hizo-la-aplicación):

```kusto
let op = toscalar(AppRequests
    | where TimeGenerated > ago(1h) and Success == false
    | top 1 by TimeGenerated desc
    | project OperationId);
union AppRequests, AppDependencies, AppExceptions, AppTraces
| where OperationId == op
| project TimeGenerated, Table = Type, AppRoleName, Name, DependencyType, Target, ResultCode, Message, OuterMessage
| order by TimeGenerated asc
```

- `Type` es, en toda tabla de Log Analytics, el **nombre de la propia tabla**: aquí dice de dónde viene
  cada fila. El tipo de dependencia está en `DependencyType`.

---

## 5. 🩺 Recetas: Container Apps

Con el environment enviando sus logs a Log Analytics, como en [`L05` §4](l05-container-apps-revisiones-trafico-y-escala.md#4--el-environment),
la salida de los contenedores y los eventos de la plataforma están en dos tablas con columnas de
sufijo `_s`:

```kusto
// la salida de consola de una app, por revisión
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(1h) and ContainerAppName_s == "inv-projector"
| project TimeGenerated, Revision = RevisionName_s, Log_s
| order by TimeGenerated desc
```

```kusto
// los eventos de la plataforma: tirar la imagen, probes, reinicios, escalado
ContainerAppSystemLogs_CL
| where TimeGenerated > ago(1h) and ContainerAppName_s == "inv-api"
| project TimeGenerated, Revision = RevisionName_s, Log_s
| order by TimeGenerated desc
```

- `_CL` significa *custom log*: son las tablas que crea el destino `log-analytics` del environment. Con el
  destino `azure-monitor`, las mismas categorías llegan por diagnostic settings con otros nombres.
- Un fallo que impide arrancar el contenedor solo está en `ContainerAppSystemLogs_CL`; una excepción de
  Spring Boot, en `ContainerAppConsoleLogs_CL` ([`L05` §8](l05-container-apps-revisiones-trafico-y-escala.md#8--una-revisión-que-no-arranca-la-imagen-arm64)).

---

## 6. 🩺 Recetas: auditoría

**Quién borró o cambió qué**, sobre el Activity Log enviado al workspace ([`L08` §3](l08-observabilidad-kql-y-auditoria.md#3--el-activity-log-al-workspace)):

```kusto
AzureActivity
| where TimeGenerated > ago(7d)
| where OperationNameValue endswith "/delete" and ActivityStatusValue == "Success"
| project TimeGenerated, Caller, OperationNameValue, ResourceGroup, Resource = tostring(split(_ResourceId, "/")[-1])
| order by TimeGenerated desc
```

**Quién dio permisos a quién:**

```kusto
AzureActivity
| where TimeGenerated > ago(30d)
| where OperationNameValue =~ "Microsoft.Authorization/roleAssignments/write" and ActivityStatusValue == "Success"
| project TimeGenerated, Caller, Scope = _ResourceId
```

**Operaciones que fallaron**, que suelen ser el primer rastro de un permiso que falta o de una policy:

```kusto
AzureActivity
| where TimeGenerated > ago(24h) and ActivityStatusValue == "Failure"
| summarize count() by Caller, OperationNameValue
| order by count_ desc
```

**Quién leyó los secretos**, sobre los resource logs de Key Vault ([`L08` §10](l08-observabilidad-kql-y-auditoria.md#10--kql-quién-leyó-el-secreto-y-quién-borró-qué)):

```kusto
AZKVAuditLogs
| where TimeGenerated > ago(7d) and OperationName == "SecretGet"
| summarize reads = count(), last = max(TimeGenerated) by Caller = tostring(Identity.claim.oid), CallerIpAddress
| order by reads desc
```

- Un identificador que lee secretos desde una IP que no es la tuya ni la de tus apps es exactamente lo
  que esta consulta existe para encontrar.
- La lectura de un secreto **no** está en `AzureActivity`: es data plane, y solo queda aquí si había
  diagnostic setting.

---

## 7. 💰 Recetas: el costo de la ingesta

La tabla `Usage` registra cuánto ingiere cada tabla. `Quantity` va en **MB**:

```kusto
Usage
| where TimeGenerated > ago(32d)
| where StartTime >= startofday(ago(31d)) and EndTime < startofday(now())
| where IsBillable == true
| summarize BillableGB = round(sum(Quantity) / 1000., 3) by DataType
| order by BillableGB desc
```

- La forma es la de la [documentación de análisis de uso](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/analyze-usage):
  días completos del último mes, solo lo facturable, agrupado por tabla (`DataType`).
- La tabla que encabeza la lista es por donde se empieza a recortar: una categoría de diagnostic
  setting de más, un agente sin sampling, logs de depuración en producción ([`14`](14-observabilidad-monitor-log-analytics-app-insights.md),
  pregunta 6).

Y la tendencia diaria, para ver si algo empezó a crecer un día concreto:

```kusto
Usage
| where TimeGenerated > ago(32d) and IsBillable == true
| summarize BillableGB = sum(Quantity) / 1000. by bin(StartTime, 1d)
| render columnchart
```

---

## 8. 🩺 Recetas: inventario con Resource Graph

Resource Graph consulta el estado actual de los recursos de **todas** tus suscripciones, en segundos y
gratis ([`14` §9](14-observabilidad-monitor-log-analytics-app-insights.md#9--resource-graph-service-health-y-resource-health)).
La tabla principal es `Resources`; los resource groups y las suscripciones están en `ResourceContainers`.

```kusto
// recursos sin el tag de rastreo
Resources
| where isnull(tags.project) or tostring(tags.project) == ""
| project name, type, resourceGroup, location
```

```kusto
// storage accounts con claves o acceso público habilitados
Resources
| where type =~ "microsoft.storage/storageaccounts"
| where properties.allowSharedKeyAccess != false or properties.allowBlobPublicAccess == true
| project name, resourceGroup, sharedKey = properties.allowSharedKeyAccess, publicBlob = properties.allowBlobPublicAccess
```

```kusto
// cuántos recursos hay de cada tipo
Resources
| summarize count() by type
| order by count_ desc
```

```kusto
// resource groups sin tags
ResourceContainers
| where type =~ "microsoft.resources/subscriptions/resourcegroups" and isnull(tags.project)
| project name, location, subscriptionId
```

- Los tipos van en minúsculas en Resource Graph; `=~` evita depender del casing.
- `properties` es un objeto `dynamic` con el mismo esquema que devuelve la API del recurso: lo que ves
  en `az rest --method get` ([`A04` §5](a04-rutina-de-recurso-cli-api-y-destruccion.md#5--paso-2-inspeccionar)).
- `allowSharedKeyAccess != false` atrapa también las cuentas donde la propiedad es nula, que por defecto
  **admiten** claves.
- Resource Graph admite un subconjunto de KQL: no todos los operadores de Log Analytics funcionan aquí.

---

## 9. ⚠️ Las trampas que no dan error

Estas consultas corren sin quejarse y devuelven un resultado equivocado:

| Trampa | Qué pasa | Cómo se evita |
|---|---|---|
| `join` sin `kind` | El valor por defecto es **`innerunique`**: deduplica la tabla izquierda por la clave antes de unir, y pierdes filas | Escribir siempre `kind=inner`, `kind=leftouter`… |
| `==` con texto | Distingue mayúsculas: `"Inv-API" == "inv-api"` es falso | `=~` para comparar sin distinguir |
| `has` con parte de una palabra | `has` busca términos completos: `"KustoExplorerQueryRun" has "Explorer"` es falso | `contains` si buscas una subcadena, sabiendo que es más lento |
| Columnas `dynamic` sin convertir | `Identity.claim.oid` no se compara ni agrupa bien sin tipo | `tostring()`, `toint()`… |
| `summarize` por tiempo sin `bin()` | Un grupo por cada instante distinto: miles de filas de una | `by bin(TimeGenerated, 5m)` |
| Contar peticiones con `count()` | El sampling del agente Java deja fuera parte de ellas | Métricas para conteos exactos |
| Consultar lo de hace un minuto | La ingesta tarda minutos | Esperar antes de concluir que no pasó |
| Buscar lo que nadie envió | Sin diagnostic setting previo, la tabla no existe o está vacía | Comprobar el diagnostic setting antes de la consulta |

---

## 10. 🧭 Chuleta

```text
Forma            Tabla | where TimeGenerated > ago(1h) | where … | summarize … by … | order by … | take N
Agregar          count() countif() dcount() sum() avg() max() percentile(x, 95) make_set(x)
Tiempo           ago(1h)  bin(TimeGenerated, 5m)  startofday(now())
Texto            ==  =~  has  contains  startswith  endswith
Unir             join kind=inner (…) on Clave      union T1, T2      let x = toscalar(…);
Tipos            tostring()  toint()  todouble()  mv-expand array
CLI              az monitor log-analytics query --workspace <customerId> --analytics-query '…'
                 az graph query --graph-query '…'

Tablas del curso AppRequests AppDependencies AppExceptions AppTraces     (Application Insights)
                 ContainerAppConsoleLogs_CL ContainerAppSystemLogs_CL     (Container Apps)
                 AzureActivity                                            (Activity Log)
                 AZKVAuditLogs  AZMSOperationalLogs                       (resource logs)
                 Usage                                                    (costo de la ingesta)
                 Resources  ResourceContainers                            (Resource Graph)
```

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia hay entre consultar con KQL en Log Analytics y en Resource Graph?
2. ¿Por qué el filtro de tiempo va primero y qué ahorra?
3. ¿Qué hace `join` si no le pones `kind` y por qué es peligroso?
4. ¿Qué diferencia hay entre `==` y `=~`, y entre `has` y `contains`?
5. ¿Por qué la media de latencia engaña y qué usas en su lugar?
6. ¿En qué tablas buscas la salida de un contenedor y los eventos de la plataforma en Container Apps?
7. ¿Cómo encuentras quién asignó un rol la semana pasada, y qué tuvo que estar configurado antes?
8. ¿Cómo averiguas qué tabla está encareciendo la ingesta del workspace?
9. ¿Cómo listas las storage accounts que siguen aceptando claves, y por qué la condición es `!= false`?
10. Una consulta de peticiones devuelve menos de las reales y no da error. ¿Qué dos causas sospechas?

---

## 📚 Referencias oficiales

- Tutorial de Log Analytics: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-tutorial
- Buenas prácticas de KQL: https://learn.microsoft.com/en-us/kusto/query/best-practices
- Operador `summarize`: https://learn.microsoft.com/en-us/kusto/query/summarize-operator
- Función `bin()`: https://learn.microsoft.com/en-us/kusto/query/bin-function
- Percentiles: https://learn.microsoft.com/en-us/kusto/query/percentiles-aggregation-function
- Operador `join` y sus tipos: https://learn.microsoft.com/en-us/kusto/query/join-operator
- Operador `union`: https://learn.microsoft.com/en-us/kusto/query/union-operator
- Operador `top`: https://learn.microsoft.com/en-us/kusto/query/top-operator
- Sentencia `let`: https://learn.microsoft.com/en-us/kusto/query/let-statement
- Operador `mv-expand`: https://learn.microsoft.com/en-us/kusto/query/mv-expand-operator
- Función `tostring()`: https://learn.microsoft.com/en-us/kusto/query/tostring-function
- Operadores de texto (`has`, `contains`, `=~`): https://learn.microsoft.com/en-us/kusto/query/datatypes-string-operators
- Operador `render`: https://learn.microsoft.com/en-us/kusto/query/render-operator
- Tabla `AppRequests`: https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/apprequests
- Tabla `AppDependencies`: https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/appdependencies
- Tabla `AzureActivity`: https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/azureactivity
- Tabla `AZKVAuditLogs`: https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/azkvauditlogs
- Tabla `Usage`: https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/usage
- Analizar el uso de un workspace: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/analyze-usage
- Logs de Container Apps en Log Analytics: https://learn.microsoft.com/en-us/azure/container-apps/log-monitoring
- Lenguaje de consultas de Resource Graph: https://learn.microsoft.com/en-us/azure/governance/resource-graph/concepts/query-language
- Referencia de `az monitor log-analytics query`: https://learn.microsoft.com/en-us/cli/azure/monitor/log-analytics
- Referencia de `az graph query`: https://learn.microsoft.com/en-us/cli/azure/graph
