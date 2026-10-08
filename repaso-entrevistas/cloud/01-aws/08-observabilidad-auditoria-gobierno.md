# 08 — Observabilidad, auditoría y gobierno

> **Objetivo:** saber qué herramienta contesta cada pregunta —qué está pasando, quién
> lo hizo, cómo está configurado— y no responder "CloudWatch" a las tres.
> **Se asume leído:** [`02`](02-computo-contenedores-y-balanceo.md) y
> [`05`](05-seguridad-iam-kms-secretos.md).
> **Se conecta con:** [`11`](11-resiliencia-y-well-architected.md) (Operational
> Excellence) y [`L04`](l04-observabilidad-y-destruccion-verificada.md), donde se practica todo esto.
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Tres preguntas diferentes](#1--tres-preguntas-diferentes) · [CloudWatch](#2--cloudwatch) · [Metrics](#3--metrics) · [Alarms](#4--alarms) · [CloudWatch Logs](#5--cloudwatch-logs) · [Logs Insights](#6--logs-insights) · [Dashboard](#7--dashboard) · [CloudTrail](#8--cloudtrail) · [Event history, Trails y CloudTrail Lake](#9--event-history-trails-y-cloudtrail-lake) · [AWS Config](#10--aws-config) · [AWS Config Rules](#11--aws-config-rules) · [CloudTrail vs Config](#12--cloudtrail-vs-config) · [VPC Flow Logs](#13--vpc-flow-logs) · [Reachability Analyzer](#14--reachability-analyzer) · [Tags](#15--tags) · [CloudWatch + autoscaling](#16--cloudwatch--autoscaling) · [X-Ray — distributed tracing](#17--x-ray--distributed-tracing) · [Logs, metrics, traces](#18--logs-metrics-traces) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

## 1. 🧭 Tres preguntas diferentes

No confundas:

```text
CloudWatch → ¿cómo está funcionando mi sistema?
CloudTrail → ¿quién hizo qué llamada/actividad en AWS?
AWS Config → ¿cómo están/configuraron mis recursos y cumplen reglas?
```

---

## 2. 🧱 CloudWatch

Servicio de monitoring/observability AWS.

Piezas esenciales:

- Metrics;
- Logs;
- Alarms;
- Dashboards;
- Logs Insights;
- agent/integrations;
- Events históricos migrados conceptualmente a EventBridge para muchos casos.

---

## 3. 🧱 Metrics

Serie temporal numérica.

Ejemplos:

```text
EC2 CPUUtilization
ALB RequestCount
ALB TargetResponseTime
SQS ApproximateNumberOfMessagesVisible
DynamoDB throttling metrics
custom application metric
```

Dimensiones identifican variantes/recursos de la métrica.

---

## 4. 🧱 Alarms

Evalúan una métrica o expresión respecto a condiciones.

Estados conceptuales:

```text
OK
ALARM
INSUFFICIENT_DATA
```

Pueden ejecutar acciones/notificaciones compatibles.

Ejemplo:

```text
queue oldest message age > threshold
→ Alarm
→ SNS notification
```

El estado que hay que entender de los tres es `INSUFFICIENT_DATA`, porque no es ni bueno
ni malo: significa que no llegaron datos suficientes para evaluar. Y ahí está la trampa
que hace que muchas alarmas nunca suenen: varias métricas de AWS **no se publican cuando
valen cero**. Una cola sin tráfico no emite `ApproximateNumberOfMessagesVisible`, así que
la alarma que vigila su DLQ se queda para siempre en `INSUFFICIENT_DATA` —que no dispara
acción alguna— y su dueño concluye que todo va bien porque nunca recibió un correo.

Se corrige declarando qué hacer con los huecos: `--treat-missing-data notBreaching` para
que un silencio cuente como normalidad, o `breaching` cuando la ausencia de datos ya es
el síntoma —una función que debería invocarse cada hora y dejó de hacerlo—. Es la
decisión que
[`L04` §5](l04-observabilidad-y-destruccion-verificada.md#5--las-alarmas-que-importan)
practica sobre la DLQ del lab.

> ⚠️ Una alarma sin `--alarm-actions` cambia de color en la consola y no se lo cuenta a
> nadie. Alarma sin destino es decoración.

La documentación actual también incluye Log Alarms que pueden evaluar resultados
programados de Logs Insights directamente.

---

## 5. 🧱 CloudWatch Logs

Recibe logs de aplicaciones y servicios.

Jerarquía mental:

```text
Log Group
└── Log Stream
    └── Log Events
```

ECS/Fargate normalmente puede enviar stdout/stderr a CloudWatch Logs mediante logging configuration.

> 💰 **Costo.** Un log group sin retención configurada guarda los eventos indefinidamente y factura por GB almacenado todos los meses. Es el cargo invisible más común de una cuenta de práctica; se corrige y se verifica en [`L04` §2](l04-observabilidad-y-destruccion-verificada.md#2--retención-de-logs-el-ajuste-que-sí-cuesta-dinero).

---

## 6. 🩺 Logs Insights

Lenguaje de consulta interactivo sobre CloudWatch Logs.

Casos:

- buscar exception;
- agrupar por endpoint;
- encontrar request IDs;
- calcular estadísticas de logs;
- incident response.

No sustituye métricas preagregadas para todo; logs y metrics se complementan.

---

## 7. 🧱 Dashboard

Visualiza métricas/alarmas relevantes.

Un dashboard útil de backend podría mostrar:

```text
requests/sec
p50/p95/p99 latency
5xx rate
CPU/memory
DB connections
SQS backlog/age
Dynamo throttling
business KPI
```

Evita un dashboard con 100 gráficas sin preguntas operativas claras.

---

## 8. 🧱 CloudTrail

Registra actividad de cuenta y API.

Un CloudTrail event puede representar acción realizada mediante:

- AWS Console;
- AWS CLI;
- SDK;
- servicio AWS;
- API.

Pregunta que responde:

> ¿Quién cambió/eliminó/creó este recurso y cuándo?

Ejemplo:

```text
DeleteBucket
AuthorizeSecurityGroupIngress
PutBucketPolicy
AssumeRole
```

---

## 9. 🧱 Event history, Trails y CloudTrail Lake

### Event history

Vista de eventos recientes de management activity con alcance/retención definidos por CloudTrail.

### Trail

Configuración persistente para entregar eventos a destinos como S3/CloudWatch Logs según configuración.

### CloudTrail Lake

Almacenamiento y consulta orientada a eventos CloudTrail/audit data según capabilities actuales.

Para entrevista básica basta distinguir **monitoring** (CloudWatch) de **audit API history** (CloudTrail).

---

## 10. 🧱 AWS Config

Evalúa, audita y registra configuración de recursos AWS.

Preguntas:

```text
¿Cómo estaba configurado este SG ayer?
¿Este bucket cumple la regla requerida?
¿Qué recursos cambiaron?
```

Conceptos:

- configuration recorder;
- configuration history;
- Config Rules;
- compliance;
- aggregators.

---

## 11. 🧱 AWS Config Rules

Evaluación de configuración contra reglas deseadas.

Ejemplos conceptuales:

```text
S3 bucket must block public access
EBS volumes must be encrypted
Security Groups must not expose SSH to 0.0.0.0/0
```

Resultado:

```text
COMPLIANT
NON_COMPLIANT
```

según regla/recurso.

---

## 12. ⚖ CloudTrail vs Config

Ejemplo: alguien abre TCP 22 al mundo.

### CloudTrail

```text
WHO executed AuthorizeSecurityGroupIngress?
WHEN?
from what principal/session?
```

### Config

```text
SG configuration changed
current rule = 0.0.0.0/0:22
NON_COMPLIANT with organization rule
```

Complementarios.

---

## 13. 🧱 VPC Flow Logs

Registra metadata sobre tráfico IP de interfaces/VPC/subnet según nivel configurado.

Campos permiten analizar, entre otros:

- source/destination;
- ports;
- protocol;
- action ACCEPT/REJECT;
- bytes/packets según formato.

Útil para red, seguridad y troubleshooting.

No captura payload de aplicación.

---

## 14. 🩺 Reachability Analyzer

Analiza estáticamente configuración de red para determinar si existe un path entre origen y destino y dónde se bloquea.

```text
EC2 A
 ↓
SG
 ↓
route
 ↓
TGW
 ↓
SG
 ↓
EC2 B
```

No es un packet capture ni un ping real.

---

## 15. 🧱 Tags

Key-value metadata aplicada a recursos compatibles.

Ejemplo:

```text
Environment=prod
Application=payments
Owner=team-payments
CostCenter=1234
DataClassification=confidential
```

Usos:

- cost allocation;
- automation;
- ownership;
- ABAC;
- inventory;
- operations.

El tagging funciona mucho mejor con convención organizacional consistente, y la razón es
que **un tag mal escrito no falla, se pierde**: `Environment=prod`, `environment=Prod` y
`Env=prod` son tres dimensiones distintas en la factura, ninguna da error, y el costo
queda repartido entre las tres sin que nadie lo note hasta que hay que explicar por qué
el informe no cuadra. Las claves distinguen mayúsculas, así que la convención se escribe
antes de crear recursos y se hace cumplir por template, no por buena voluntad.

Hay además dos cosas que sorprenden y conviene tener presentes. La primera es que un tag
existe en el recurso desde que lo creas, pero **no aparece como dimensión de costo hasta
que lo activas** como cost allocation tag en facturación, y esa activación no es
retroactiva: solo etiqueta el gasto posterior. La segunda es que no todos los recursos
admiten tags, y algunos que crea AWS por su cuenta —el log group que nace con la primera
invocación de una Lambda— nacen sin ninguno. De ahí que un barrido serio combine el
rastreo por tag con la enumeración explícita por servicio, como hace
[`L04` §11](l04-observabilidad-y-destruccion-verificada.md#11--barrido-explícito-por-servicio).

---

## 16. 🧱 CloudWatch + autoscaling

Ejemplo:

```text
SQS queue depth ↑
        │
        ▼
CloudWatch metric/alarm
        │
        ▼
Application Auto Scaling
        │
        ▼
ECS desired tasks ↑
```

Diseña scaling con una métrica correlacionada con trabajo real, no solo CPU por
costumbre. La CPU es la métrica por defecto por razones históricas —era lo único que
había— y describe mal a la mayoría de los workloads modernos: un worker que espera
respuestas de una API externa puede estar completamente saturado con la CPU al 10 %, y
escalar por CPU no añadirá una sola instancia mientras el backlog crece.

La pregunta correcta es cuál es la unidad de trabajo pendiente de **este** servicio: la
antigüedad del mensaje más viejo para un consumidor de cola, las peticiones por target
para una API detrás de un ALB, la profundidad de la cola de conexiones para algo que
habla con una base. Escalar por esa métrica reacciona antes y en la dirección correcta.

Para emitir métricas propias desde una Lambda sin llamar a `PutMetricData`, el mecanismo
es **Embedded Metric Format (EMF)**: un JSON con forma concreta escrito en el log, del que
CloudWatch extrae la métrica. Se practica en
[`L04` §4](l04-observabilidad-y-destruccion-verificada.md#4--emf-métricas-sin-llamar-a-la-api).

Para emitir métricas propias desde una Lambda sin llamar a `PutMetricData`, el mecanismo es **Embedded Metric Format (EMF)**: un JSON con forma concreta escrito en el log, del que CloudWatch extrae la métrica. Se practica en [`L04` §4](l04-observabilidad-y-destruccion-verificada.md#4--emf-métricas-sin-llamar-a-la-api).

---

## 17. 🧱 X-Ray — distributed tracing

Metrics y logs no responden bien "¿por dónde pasó esta request y en qué segmento se fue el tiempo?" cuando atraviesa varios servicios. Ese es el problema que resuelve el tracing distribuido.

### Modelo trace/segment/subsegment

```text
Trace (una request end-to-end, identificada por trace ID)
├── Segment: API Gateway
├── Segment: Lambda A
│   ├── Subsegment: llamada a DynamoDB
│   └── Subsegment: llamada a servicio externo
└── Segment: Lambda B
```

- **Trace**: el recorrido completo de una request a través del sistema, identificado por un trace ID propagado entre servicios.
- **Segment**: el trabajo realizado por un servicio/componente dentro del trace.
- **Subsegment**: detalle dentro de un segment, por ejemplo una llamada downstream específica.

### Integración con ALB, API Gateway y Lambda

```text
Client
  │ X-Ray trace header
  ▼
ALB (puede insertar/propagar el trace header)
  │
  ▼
API Gateway (integración X-Ray activable)
  │
  ▼
Lambda (X-Ray SDK / Active Tracing)
  │
  ▼
DynamoDB / servicio downstream
```

Para que el trace se vea completo, cada salto necesita propagar el trace header y reportar sus propios segments; un servicio "silencioso" en el medio rompe la visibilidad de esa porción del trace.

Regla mental:

```text
Metrics → cuánto
Logs    → qué pasó exactamente en un punto
Traces  → por dónde pasó y dónde se fue la latencia
```

No digas "con CloudWatch Logs ya tengo trazabilidad distribuida". Mejor:

> Los logs por servicio muestran eventos aislados; un trace correlaciona esos eventos a través de todos los servicios que participaron en una misma request, con la latencia de cada segmento.

X-Ray no es el único camino: tooling compatible con OpenTelemetry puede alimentar tracing distribuido de forma similar; el modelo trace/segment/subsegment es el que hay que reconocer en entrevista.

---

## 18. 🧭 Logs, metrics, traces

Modelo de observabilidad:

```text
Metrics → ¿qué está pasando cuantitativamente?
Logs    → ¿qué detalles/eventos ocurrieron?
Traces  → ¿por dónde pasó una request distribuida?
```

Los tres pilares se complementan: una alarma de latencia (metric) indica que algo empeoró, los logs dan contexto de un caso puntual, y un trace muestra en qué segmento del recorrido se concentró la latencia.

---

## 🧠 Preguntas rápidas

1. ¿CloudWatch vs CloudTrail?
2. ¿CloudTrail vs Config?
3. ¿Qué es una metric dimension?
4. ¿Qué estados puede tener una alarm?
5. ¿Para qué sirve Logs Insights?
6. ¿Flow Logs contienen payload HTTP?
7. ¿Reachability Analyzer manda tráfico real?
8. ¿Qué métrica usarías para autoscaling de workers SQS?
9. ¿Por qué tags son importantes?
10. ¿Cómo investigarías quién abrió un SG al mundo?
11. ¿Qué es un segment dentro de un trace de X-Ray?
12. ¿Qué pasa con la visibilidad del trace si un servicio en el medio no reporta sus segments?
13. ¿Por qué un log por servicio no es lo mismo que un trace distribuido?

---

## 📚 Referencias oficiales

- CloudWatch: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html
- CloudWatch Logs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html
- CloudTrail concepts: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html
- AWS Config: https://docs.aws.amazon.com/config/latest/developerguide/aws-config-landing-page.html
- VPC Flow Logs: https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html
- Reachability Analyzer: https://docs.aws.amazon.com/vpc/latest/reachability/what-is-reachability-analyzer.html
- Tagging: https://docs.aws.amazon.com/tag-editor/latest/userguide/tagging.html
- AWS X-Ray: https://docs.aws.amazon.com/xray/latest/devguide/aws-xray.html
- X-Ray concepts: https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html
- Trabajar con métricas de CloudWatch: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/working_with_metrics.html
- Alarmas de CloudWatch: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Alarms.html
- Logs Insights: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html
- Dashboards de CloudWatch: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html
- Embedded Metric Format (EMF): https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html
- CloudTrail Lake: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-lake.html
- Evaluación de reglas de AWS Config: https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html
