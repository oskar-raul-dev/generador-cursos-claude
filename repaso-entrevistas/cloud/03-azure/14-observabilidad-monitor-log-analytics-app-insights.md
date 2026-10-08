# 14 — Observabilidad: Azure Monitor, Log Analytics y Application Insights

> **Objetivo:** saber qué registra Azure por su cuenta y qué no, llevar los logs de cada recurso y de la
> aplicación a un mismo sitio, consultarlos con KQL, instrumentar una aplicación Spring Boot con
> Application Insights y alertar sin que la factura se dispare.
> **Se asume leído:** [`01`](01-infraestructura-global-y-resource-manager.md) (control plane frente a
> data plane) y [`04`](04-computo-y-contenedores.md) (Container Apps).
> **Se toca más con:** [`02`](02-redes-vnet-nsg-y-enrutamiento.md), donde vive Network Watcher,
> [`13`](13-mensajeria-y-eventos.md), cuya cola y DLQ se miden aquí, y el apéndice [`A05`](a05-kql-de-supervivencia.md), que amplía el
> KQL.
> **Se practica en:** [`L08`](l08-observabilidad-kql-y-auditoria.md) (un workspace, diagnostic settings de Service Bus y Key Vault, consultas KQL
> sobre el Activity Log y la aplicación, y una alerta). Ver
> [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [El problema](#1--el-problema-azure-no-registra-todo-por-defecto) ·
[Azure Monitor](#2--azure-monitor-métricas-y-logs) · [Tres fuentes](#3--tres-fuentes-de-logs-y-quién-registra-qué) ·
[Workspace](#4--el-log-analytics-workspace) · [Diagnostic settings](#5--diagnostic-settings) ·
[KQL](#6--kql-lo-justo-para-diagnosticar) · [Application Insights](#7--application-insights-para-spring-boot) ·
[Alertas](#8--alertas-y-action-groups) · [Resource Graph y salud](#9--resource-graph-service-health-y-resource-health) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El problema: Azure no registra todo por defecto

A las tres de la madrugada `inv-projector` deja de procesar y la DLQ crece. Quieres saber quién cambió
qué, qué errores dio Service Bus y qué hizo la aplicación con cada mensaje. Y descubres que:

- el **Activity Log** sí tiene quién tocó el namespace, porque Azure lo registra siempre;
- los **logs del propio Service Bus** no están en ningún sitio, porque nadie creó un **diagnostic
  setting** que los mandara a un workspace;
- la **telemetría de la aplicación** solo existe si la aplicación se instrumentó.

Esa es la idea que ordena el capítulo:

```text
Lo que Azure registra siempre:    métricas de plataforma + Activity Log (90 días)
Lo que hay que pedir:             resource logs (diagnostic settings) → Log Analytics
Lo que hay que instrumentar:      la aplicación (Application Insights / OpenTelemetry)
```

> Nunca respondas: "Azure registra todo por defecto". Mejor: "Azure guarda las métricas de plataforma y
> el Activity Log del control plane; los resource logs de cada servicio solo se recogen si configuro un
> diagnostic setting, y la telemetría de la aplicación solo existe si la instrumento".

---

## 2. 🧱 Azure Monitor: métricas y logs

**Azure Monitor** es la plataforma de observabilidad de Azure; todo lo demás del capítulo son partes de
ella, incluido Application Insights. Maneja dos tipos de dato:

| | Métricas | Logs |
|---|---|---|
| Qué son | Series numéricas con timestamp y dimensiones | Registros con estructura variable |
| Ejemplo | `ActiveMessages` de una subscription, CPU de una VM | Una operación de Service Bus, una petición HTTP con su traza |
| Latencia | Casi tiempo real | Minutos |
| Dónde viven | Base de métricas de Azure Monitor | Log Analytics workspace |
| Retención por defecto | 93 días | La del workspace y la tabla (§4) |
| Costo | Las de plataforma, gratis | Por GB ingerido y retenido |
| Para qué | Alertas rápidas, dashboards, autoescalado | Diagnóstico, correlación, auditoría |

Las **métricas de plataforma** existen para cada recurso sin configurar nada: es lo que usa Container
Apps para escalar por mensajes pendientes ([`04`](04-computo-y-contenedores.md)) y lo primero que se mira en un incidente.

---

## 3. 🧱 Tres fuentes de logs y quién registra qué

| Fuente | Qué registra | ¿Por defecto? |
|---|---|---|
| **Activity Log** | Operaciones de **control plane** sobre la suscripción: quién creó, cambió o borró qué recurso, asignaciones de roles, alertas de Service Health | ✅ 90 días, gratis |
| **Resource logs** | Lo que pasa **dentro** de cada recurso: operaciones de Service Bus, accesos a secretos de Key Vault, peticiones a Storage | ❌ requieren diagnostic setting |
| **Application Insights** | Telemetría de la **aplicación**: peticiones, dependencias, excepciones, trazas, métricas propias | ❌ requiere instrumentar |

Dos consecuencias que se preguntan:

- el Activity Log **no registra el data plane**: leer un blob, recibir un mensaje o leer un secreto no
  aparece en él. Para auditar quién leyó un secreto hacen falta los resource logs de Key Vault (categoría
  `AuditEvent`);
- el Activity Log se guarda **90 días** y después se borra. Para conservarlo más —auditoría bancaria—
  se exporta con un diagnostic setting de la suscripción al workspace, donde la tabla `AzureActivity`
  además **no cobra ingesta** y retiene 90 días gratis.

> Nunca respondas: "el Activity Log registra quién leyó el secreto". Mejor: "el Activity Log registra el
> control plane; quién leyó el secreto está en los resource logs de Key Vault, y solo si hay un
> diagnostic setting que los envíe al workspace".

---

## 4. 🧱 El Log Analytics workspace

El **Log Analytics workspace** (`inv-lab-law`) es el almacén de logs: cada fuente escribe en **tablas**
(`AzureActivity`, `AppRequests`, `AppDependencies`, las de cada servicio) que se consultan con KQL.

**Planes de tabla**, que deciden costo y capacidades:

| Plan | Para qué | Limitaciones |
|---|---|---|
| **Analytics** (por defecto) | Monitoreo continuo, alertas, consultas interactivas | Es el más caro |
| **Basic** | Diagnóstico y respuesta a incidentes | Consultas de 30 días que cobran por GB analizado |
| **Auxiliary** | Datos verbosos de alto volumen, retención larga barata | Sin alertas; consultas más lentas y de pago |

**Retención**, en dos fases:

- **analytics retention**: 30 días por defecto (90 para `AzureActivity`, `Usage` y las tablas de
  Application Insights), ampliable hasta **2 años**. La ingesta **incluye 31 días**: bajar la retención
  por debajo de eso no ahorra nada;
- **long-term retention**: después, los datos pasan a un estado barato hasta un total de **12 años**, y se
  recuperan con *search jobs*.

> 💰 **Costo.** En `eastus2`, la ingesta en tablas **Analytics** cuesta **$2.76 por GB**, con los
> primeros **5 GB al mes gratis**; en **Basic**, $0.50 por GB, y en **Auxiliary**, $0.05 por GB. La
> retención de Analytics más allá de lo incluido cuesta $0.12 por GB y mes. **El costo de la
> observabilidad es la ingesta**: un diagnostic setting con todas las categorías de un servicio muy
> hablador, o una aplicación que loguea en `DEBUG`, es la causa típica de una factura sorpresa. El
> laboratorio se queda por debajo de 5 GB.

Una regla de diseño: **un workspace por ambiente** (o por región y ambiente), no uno por aplicación. Las
consultas que cruzan la API, Service Bus y el Activity Log funcionan mejor cuando todo está junto, y el
acceso se controla por tabla o por recurso (*resource-context*).

---

## 5. 🧱 Diagnostic settings

Un **diagnostic setting** dice qué categorías de logs y métricas de un recurso se envían a qué destinos:
un Log Analytics workspace, una storage account (archivo barato) o un event hub (hacia un SIEM externo).
Cada recurso admite **hasta cinco**.

```bash
az monitor diagnostic-settings create \
  --name to-law \
  --resource "$(az servicebus namespace show --name inv-lab-sb-472913 --resource-group inv-lab-rg --query id --output tsv)" \
  --workspace "$(az monitor log-analytics workspace show --workspace-name inv-lab-law --resource-group inv-lab-rg --query id --output tsv)" \
  --logs '[{"categoryGroup": "allLogs", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]' \
  --export-to-resource-specific true
```

- `--resource` es el resource ID del recurso que emite los logs: aquí, el namespace de Service Bus.
- `--workspace` es el resource ID del workspace de destino. Puede estar en otra suscripción.
- `--logs '[{"categoryGroup": "allLogs", ...}]'` activa todas las categorías del recurso con un
  **grupo de categorías**. La alternativa es listarlas una a una, que es lo que se hace en producción
  para no ingerir lo que no se va a mirar. `audit` es el otro grupo habitual.
- `--metrics '[{"category": "AllMetrics", ...}]'` copia además las métricas de plataforma al workspace,
  para consultarlas con KQL junto a los logs.
- `--export-to-resource-specific true` escribe en **tablas propias del servicio** en vez de en la tabla
  genérica `AzureDiagnostics`, donde todos los recursos comparten columnas. Las tablas específicas son
  más fáciles de consultar y más baratas de filtrar.

> ⚠️ **Los diagnostic settings no se heredan.** Un recurso nuevo nace sin ellos. En una organización se
> garantizan con una **Azure Policy `deployIfNotExists`** ([`10` §10](10-autorizacion-rbac-policy-y-gobierno.md#10--azure-policy)) que crea el diagnostic
> setting en cada recurso de un tipo, o se incluyen en el Bicep de cada recurso ([`15`](15-bicep-iac.md)).

---

## 6. 🧱 KQL lo justo para diagnosticar

**KQL** (*Kusto Query Language*) es un lenguaje de tuberías: una tabla y una cadena de operadores
separados por `|`. Los seis que resuelven el 90 % de los diagnósticos:

```kusto
// ¿Quién borró o cambió algo en inv-lab-rg en las últimas 24 horas?
AzureActivity
| where TimeGenerated > ago(24h)
| where ResourceGroup =~ "inv-lab-rg"
| where OperationNameValue endswith "/delete" or OperationNameValue endswith "/write"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue, _ResourceId
| order by TimeGenerated desc
```

- `where` filtra filas; siempre primero por tiempo (`TimeGenerated > ago(24h)`), que es lo que más
  reduce lo que se lee y lo que se paga en planes que cobran por GB analizado.
- `=~` compara sin distinguir mayúsculas; `endswith` busca por sufijo de la operación.
- `project` elige y ordena columnas; `order by` ordena el resultado.

```kusto
// Tasa de error y latencia p95 de inv-api por operación, en ventanas de 5 minutos
AppRequests
| where TimeGenerated > ago(1h) and AppRoleName == "inv-api"
| summarize requests = count(),
            failed = countif(Success == false),
            p95_ms = percentile(DurationMs, 95)
          by bin(TimeGenerated, 5m), Name
| extend error_rate = round(100.0 * failed / requests, 2)
| render timechart
```

- `summarize ... by` agrega: `count()`, `countif()`, `percentile()`, agrupando por ventana de tiempo
  (`bin(TimeGenerated, 5m)`) y por operación.
- `extend` añade una columna calculada.
- `render timechart` dibuja el resultado en el portal.

```kusto
// Las peticiones fallidas con la dependencia que falló dentro de la misma operación
AppRequests
| where TimeGenerated > ago(1h) and Success == false
| join kind=inner (AppDependencies | where Success == false) on OperationId
| project TimeGenerated, Name, ResultCode, DependencyType, Target, DependencyResult = ResultCode1
```

- `join ... on OperationId` cruza la petición con sus dependencias por el **id de operación**, que es lo
  que Application Insights usa para la correlación distribuida (§7). `kind=inner` deja solo las que
  tienen pareja.
- Las columnas repetidas de la tabla derecha llevan sufijo (`ResultCode1`). `DependencyType` no se
  repite, porque `AppRequests` no la tiene; `Type`, en cambio, es en toda tabla de Log Analytics el
  nombre de la propia tabla, no el tipo de dependencia.

Desde la CLI, la misma consulta se ejecuta con `az monitor log-analytics query -w <customerId>
--analytics-query "..."`, donde `-w` es el **GUID del workspace** (su `customerId`), no su nombre ni su
resource ID. El apéndice [`A05`](a05-kql-de-supervivencia.md) amplía el KQL.

---

## 7. 🧱 Application Insights para Spring Boot

**Application Insights** es la parte de Azure Monitor para la **telemetría de aplicación**, y hoy es
siempre **basado en workspace**: sus datos viven en tablas del Log Analytics workspace (`AppRequests`,
`AppDependencies`, `AppExceptions`, `AppTraces`, `AppMetrics`). No es una herramienta aparte: es otra
fuente del mismo almacén.

Para Java, la vía recomendada es el **agente de Application Insights**, una distribución de
OpenTelemetry que instrumenta **sin cambiar el código**:

```dockerfile
# Dockerfile de inv-api: el agente se descarga en el build y se adjunta a la JVM
ADD https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.7.9/applicationinsights-agent-3.7.9.jar /opt/agent/applicationinsights-agent.jar
ENV JAVA_TOOL_OPTIONS="-javaagent:/opt/agent/applicationinsights-agent.jar"
ENTRYPOINT ["java", "-jar", "/app/inv-api.jar"]
```

- `ADD .../3.7.9/applicationinsights-agent-3.7.9.jar` fija la **versión exacta** del agente, la
  vigente en Learn a la fecha de vigencia. Nunca `latest`.
- `JAVA_TOOL_OPTIONS="-javaagent:..."` hace que la JVM cargue el agente al arrancar; la JVM lee esa
  variable sola, así que el `ENTRYPOINT` no cambia.
- El agente necesita la variable `APPLICATIONINSIGHTS_CONNECTION_STRING`, que se inyecta en Container
  Apps, no en la imagen. La **connection string** sustituyó a la antigua *instrumentation key*.

Lo que se obtiene sin escribir una línea:

- **requests**: cada petición HTTP entrante, con duración, código y resultado;
- **dependencies**: cada llamada saliente —JDBC, HTTP, Cosmos DB, Service Bus, Redis— con su duración y
  su resultado;
- **exceptions** y **traces** (los logs de Logback o Log4j);
- **correlación distribuida**: el agente propaga el contexto de **W3C Trace Context** (`traceparent`) en
  las llamadas HTTP y en los mensajes de Service Bus, así que una petición a `inv-api` y el
  procesamiento del mensaje en `inv-projector` comparten el mismo `OperationId`. El **Application Map**
  del portal dibuja ese grafo.

Dos ajustes que se preguntan:

- el **sampling** del agente Java está activado por defecto a **5 peticiones por segundo**: controla el
  costo, pero por encima de ese ritmo **no todas las peticiones quedan registradas**. Contar peticiones
  con `count()` en un servicio con mucho tráfico da menos de las reales; para conteos exactos, las
  métricas;
- con varios servicios en el mismo recurso de Application Insights, cada uno debe fijar su **cloud role
  name** (`inv-api`, `inv-projector`), que es el `AppRoleName` de las consultas y los nodos del mapa.

> 📝 **Contexto.** Application Insights **clásico**, con almacenamiento propio fuera de un workspace, ya
> no existe: Microsoft empezó a migrar los recursos clásicos a workspace-based en mayo de 2024. Material
> que habla de "la instrumentation key" o de consultar `requests` en vez de `AppRequests` describe el
> modelo anterior.

---

## 8. 🧱 Alertas y action groups

Una **alerta** evalúa una condición y, si se cumple, dispara un **action group**: la lista de a quién
avisar y qué ejecutar (correo, SMS, webhook, Function, Logic App, ITSM). El laboratorio tiene
`inv-lab-ag`.

| Tipo | Evalúa | Latencia | Caso |
|---|---|---|---|
| **Alerta de métrica** | Una métrica contra un umbral (estático o dinámico) | ~1 minuto | "`DeadletteredMessages` > 0 en `inv-projector`" |
| **Alerta de log** | Una consulta KQL con una frecuencia | La de la frecuencia, más la ingesta | "Más de 5 % de errores en `inv-api` durante 10 minutos" |
| **Alerta del Activity Log** | Un evento de control plane | Minutos | "Alguien borró un lock" o "Service Health anuncia un incidente" |

> 💰 **Costo.** En `eastus2`, las **alertas de métrica** tienen las primeras 10 series vigiladas gratis
> y después cuestan **$0.10 por serie y mes**; una **alerta de log** cuesta por regla según la
> frecuencia: **$1.50 al mes** cada 5 minutos, **$3** cada minuto. Diez alertas de log de un minuto que
> nadie mira son $30 al mes. Las alertas del Activity Log son gratuitas.

> 💡 **Tip.** Para lo urgente, alerta de métrica: es más rápida y más barata. La alerta de log es para
> condiciones que solo se expresan con una consulta, y su frecuencia se elige según cuánto importa
> enterarse un minuto antes.

---

## 9. 🧱 Resource Graph, Service Health y Resource Health

- **Azure Resource Graph** consulta el **inventario** de recursos de todas tus suscripciones con KQL, en
  segundos y gratis: "todas las storage accounts con acceso público", "todo lo que no tiene el tag
  `project`". No son logs: es el estado actual de los recursos. Se usa con `az graph query -q "..."`.
- **Service Health** avisa de incidentes y mantenimientos **de Azure** que afectan a tus servicios y
  regiones: responde "¿es Azure o soy yo?".
- **Resource Health** dice si **un recurso concreto** está disponible y, si no lo está, si la causa es de
  la plataforma o tuya.
- **Network Watcher** ([`02`](02-redes-vnet-nsg-y-enrutamiento.md)) cubre el diagnóstico de red: IP flow verify, next hop, connection
  troubleshoot y los flow logs.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Azure registra todo por defecto" | Métricas y Activity Log sí; resource logs y aplicación, no |
| "El Activity Log registra las lecturas de datos" | Solo el control plane; el data plane está en los resource logs |
| "Application Insights es otra herramienta aparte de Azure Monitor" | Es parte de Azure Monitor y guarda sus datos en el workspace |
| "El Activity Log se guarda para siempre" | 90 días; más allá, hay que exportarlo con un diagnostic setting |
| "Un recurso nuevo hereda los diagnostic settings" | Nace sin ellos; se garantizan con Policy o con Bicep |
| "Bajo la retención a 7 días para ahorrar" | La ingesta incluye 31 días; bajar de ahí no ahorra |
| "`count()` en `AppRequests` es el número real de peticiones" | Con sampling activo, no; para conteos exactos, métricas |
| "`az monitor log-analytics query -w inv-lab-law`" | `-w` es el GUID del workspace, no su nombre |

---

## 🧠 Preguntas rápidas

1. ¿Qué registra Azure sin que configures nada y qué no?
2. ¿Qué diferencia hay entre métricas y logs en Azure Monitor, y cuándo usarías cada uno para alertar?
3. Necesitas saber quién leyó un secreto de Key Vault ayer. ¿Dónde lo buscas y qué tuvo que estar configurado antes?
4. ¿Cuánto tiempo guarda Azure el Activity Log y cómo lo conservas más tiempo para una auditoría?
5. ¿Qué diferencia hay entre los planes de tabla Analytics, Basic y Auxiliary?
6. ¿Por qué bajar la retención del workspace a 7 días no reduce la factura?
7. ¿Qué hace un diagnostic setting y cómo garantizas que todos los recursos de un tipo lo tengan?
8. ¿Por qué conviene `--export-to-resource-specific true` en un diagnostic setting?
9. Escribe una consulta KQL que muestre la tasa de error por operación de `inv-api` en la última hora.
10. ¿Cómo correlaciona Application Insights una petición de `inv-api` con el procesamiento del mensaje en `inv-projector`?
11. ¿Cómo instrumentas una aplicación Spring Boot en Container Apps sin tocar el código, y qué versión del agente fijas?
12. Tu consulta cuenta 40.000 peticiones por hora y el balanceador dice 90.000. ¿Qué pasa?
13. ¿Qué diferencia hay entre una alerta de métrica y una alerta de log en latencia y costo?
14. ¿Para qué sirve Azure Resource Graph y en qué se diferencia de consultar Log Analytics?
15. ¿Qué diferencia hay entre Service Health y Resource Health?

---

## 📚 Referencias oficiales

- ¿Qué es Azure Monitor?: https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/overview
- Métricas de plataforma de Azure Monitor: https://learn.microsoft.com/en-us/azure/azure-monitor/metrics/data-platform-metrics
- Activity Log: https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log
- Diagnostic settings: https://learn.microsoft.com/en-us/azure/azure-monitor/data-collection/diagnostic-settings
- Planes de tabla de Log Analytics: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-table-plans
- Retención de datos del workspace: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-retention-configure
- Costos de Azure Monitor Logs: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/cost-logs
- Consultas de logs con KQL en Azure Monitor: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-query-overview
- Tutorial de consultas en Log Analytics: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/get-started-queries
- Application Insights: https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview
- OpenTelemetry con Application Insights (agente Java): https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable
- Configuración del agente Java (sampling y overrides): https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-standalone-config
- Application Insights con Spring Boot: https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-spring-boot
- Alertas de Azure Monitor: https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview
- Action groups: https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups
- ¿Qué es Azure Resource Graph?: https://learn.microsoft.com/en-us/azure/governance/resource-graph/overview
- Service Health: https://learn.microsoft.com/en-us/azure/service-health/overview
- Resource Health: https://learn.microsoft.com/en-us/azure/service-health/resource-health-overview
- `az monitor diagnostic-settings`: https://learn.microsoft.com/en-us/cli/azure/monitor/diagnostic-settings
- `az monitor log-analytics`: https://learn.microsoft.com/en-us/cli/azure/monitor/log-analytics
- Precios de Azure Monitor: https://azure.microsoft.com/en-us/pricing/details/monitor/
