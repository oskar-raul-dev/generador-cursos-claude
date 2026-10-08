# L04 — Observabilidad y destrucción verificada

> **Objetivo:** instrumentar el backend de [`L03`](l03-backend-serverless-lambda-api-y-eventos.md) con lo nativo de AWS y después
> destruirlo **demostrando** que no queda nada cobrando. La segunda mitad es la que importa.
> **Costo esperado:** centavos. Las alarmas por encima de las 10 gratuitas cuestan $0.10
> al mes cada una; con retención de 3 días y 10 métricas, el lab no las supera.
> **Duración:** 2–3 horas.
> **Prerrequisito:** [`L03`](l03-backend-serverless-lambda-api-y-eventos.md) desplegado y
> funcionando.
> **Deja encendido:** nada, y esa es exactamente la comprobación con la que cierra el lab.
> **Teoría de apoyo:** [`08`](08-observabilidad-auditoria-gobierno.md) y el catálogo de
> [`A02`](a02-costos-trampas-y-recursos-huerfanos.md).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Qué practica este lab](#1--qué-practica-este-lab) · [Retención de logs: el ajuste que sí cuesta dinero](#2--retención-de-logs-el-ajuste-que-sí-cuesta-dinero) · [Logs Insights desde la CLI](#3--logs-insights-desde-la-cli) · [EMF: métricas sin llamar a la API](#4--emf-métricas-sin-llamar-a-la-api) · [Las alarmas que importan](#5--las-alarmas-que-importan) · [X-Ray](#6--x-ray) · [CloudTrail para diagnosticar un `AccessDenied`](#7--cloudtrail-para-diagnosticar-un-accessdenied) · [El orden importa](#8--el-orden-importa) · [Lo que sobrevive al `delete-stack`](#9--lo-que-sobrevive-al-delete-stack) · [Barrido por tag](#10--barrido-por-tag) · [Barrido explícito por servicio](#11--barrido-explícito-por-servicio) · [Confirmación económica](#12--confirmación-económica) · [El checklist de certeza](#13--el-checklist-de-certeza) · [Preguntas rápidas](#-preguntas-rápidas) · [Ejercicios](#-ejercicios-14) · [La señal de que quedó bien](#-la-señal-de-que-quedó-bien) · [Referencias oficiales](#-referencias-oficiales)

Cuarto y último lab de la serie. Primera mitad: instrumentar el backend de
[`L03`](l03-backend-serverless-lambda-api-y-eventos.md) con lo nativo de AWS. Segunda mitad: destruirlo y **demostrar** que no queda nada cobrando.

---

## 1. 🧭 Qué practica este lab

| Tema | Por qué no se aprende con Prometheus local |
|---|---|
| EMF | Es un formato propio de CloudWatch Logs, sin equivalente fuera |
| Logs Insights | Lenguaje de consulta propio, y es lo que vas a usar en el trabajo |
| CloudTrail | Es la única fuente para "¿quién hizo esto y por qué lo denegaron?" |
| Barrido de recursos | El problema de los huérfanos solo existe cuando alguien te cobra |

---

# Parte I — Observabilidad

## 2. 💰 Retención de logs: el ajuste que sí cuesta dinero

Un log group sin `RetentionInDays` guarda para siempre y se factura por GB almacenado
todos los meses. Es un cargo pequeño, permanente y completamente invisible.

```bash
# auditar toda la cuenta
aws logs describe-log-groups \
  --query 'logGroups[?retentionInDays==null].[logGroupName,storedBytes]' \
  --output table

# corregir uno
aws logs put-retention-policy --log-group-name /aws/lambda/inv-lab-api --retention-in-days 3
```

- `logGroups[?retentionInDays==null]` es un filtro JMESPath: el `?` abre una expresión
  de filtro y `==null` selecciona los grupos **sin** política de retención, es decir, los
  que guardan para siempre. Son justo los que cuestan dinero en silencio.
- `--retention-in-days` solo admite un conjunto cerrado de valores (1, 3, 5, 7, 14, 30,
  60, 90… hasta 3653). Un número fuera de esa lista devuelve `InvalidParameterException`.
- Este comando **no borra** lo ya almacenado: fija la política de aquí en adelante. Los
  eventos viejos se van purgando cuando superan la ventana.

> ⚠️ El log group de una Lambda **lo crea CloudWatch, no tu stack**. Por eso sobrevive al
> `delete-stack` y por eso nace con retención indefinida. Declararlo explícitamente en el
> template como `AWS::Logs::LogGroup` es lo que hace
> [`L03` §12](l03-backend-serverless-lambda-api-y-eventos.md#12--los-log-groups-se-declaran-no-se-heredan),
> y es la única forma de que el teardown se lo lleve.

> Regla: en un lab, ningún log group sin retención. Tres días sobran.

---

## 3. 🩺 Logs Insights desde la CLI

La consulta es asíncrona: se lanza, se obtiene un `queryId` y se consulta el
resultado.

```bash
START=$(($(date +%s) - 3600))
END=$(date +%s)

QID=$(aws logs start-query \
  --log-group-names /aws/lambda/inv-lab-api /aws/lambda/inv-lab-projector \
  --start-time "$START" --end-time "$END" \
  --query-string 'fields @timestamp, @message
                  | filter @message like /ERROR/
                  | sort @timestamp desc
                  | limit 20' \
  --query queryId --output text)

aws logs get-query-results --query-id "$QID"
```

Aquí conviven dos cosas que se llaman casi igual y no tienen nada que ver:

- **`--query-string`** es la consulta de Logs Insights, que corre en el servicio. Su
  lenguaje es propio: `fields`, `filter`, `stats`, `sort`, `limit`, encadenados con `|`.
- **`--query queryId`** es el JMESPath de la CLI, que corre en tu máquina sobre la
  respuesta. Confundirlos es el tropiezo clásico de este comando.
- `--start-time` y `--end-time` van en **segundos de época Unix**, no en ISO 8601 — de ahí
  el `date +%s` de las dos líneas anteriores. Otras APIs de AWS piden milisegundos o ISO;
  no hay una convención única y hay que mirarla servicio por servicio.
- `--log-group-names` acepta varios separados por espacios, y **la consulta corre sobre
  todos a la vez**, que es lo que permite seguir una petición de una función a otra.
- `get-query-results` sobre una consulta que aún no terminó devuelve `status: Running` y
  cero resultados. No es un error: hay que volver a llamarlo.

Consultas que conviene tener memorizadas:

```text
# duración e inicialización de cada invocación
filter @type = "REPORT"
| stats avg(@duration), max(@duration), max(@initDuration) by bin(5m)

# invocaciones que agotaron el timeout
filter @message like /Task timed out/
| stats count() by bin(1h)

# consumo real de memoria contra la asignada
filter @type = "REPORT"
| stats max(@maxMemoryUsed / 1000 / 1000) as MB_usados, max(@memorySize / 1000 / 1000) as MB_asignados
```

⚠️ `@initDuration` solo aparece en invocaciones con cold start. Es la forma correcta
de medir cuánto cold start tienes de verdad, en vez de suponerlo.

---

## 4. 🧱 EMF: métricas sin llamar a la API

Embedded Metric Format permite emitir métricas escribiendo un JSON con estructura
concreta en stdout. CloudWatch lo extrae del log y crea la métrica. No hay llamada a
`PutMetricData`, no hay latencia añadida y no hay permisos extra.

```python
import json, time

def emit(store, qty):
    print(json.dumps({
        "_aws": {
            "Timestamp": int(time.time() * 1000),
            "CloudWatchMetrics": [{
                "Namespace": "InvLab",
                "Dimensions": [["StoreId"]],
                "Metrics": [{"Name": "UnitsSold", "Unit": "Count"}]
            }]
        },
        "StoreId": store,
        "UnitsSold": qty
    }))
```

```bash
aws cloudwatch list-metrics --namespace InvLab --output table
```

> Punto importante: `PutMetricData` es una llamada de red sincrónica dentro de tu
> función, se factura por métrica y puede fallar. EMF es una línea de log. Para
> métricas de negocio dentro de Lambda, EMF es la respuesta correcta.

---

## 5. 🧱 Las alarmas que importan

No "alarmas de CPU". Las cuatro que corresponden a esta arquitectura:

| Alarma | Métrica | Qué significa |
|---|---|---|
| Errores de función | `AWS/Lambda Errors` | Código o permisos rotos |
| Throttling | `AWS/Lambda Throttles` | Límite de concurrencia alcanzado |
| Antigüedad del mensaje más viejo | `AWS/SQS ApproximateAgeOfOldestMessage` | El consumidor no da abasto |
| DLQ con mensajes | `AWS/SQS ApproximateNumberOfMessagesVisible` en la DLQ | Algo se rindió tras los reintentos |

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name inv-lab-dlq-no-vacia \
  --namespace AWS/SQS --metric-name ApproximateNumberOfMessagesVisible \
  --dimensions Name=QueueName,Value=inv-lab-alerts-dlq \
  --statistic Maximum --period 300 --evaluation-periods 1 \
  --threshold 0 --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions arn:aws:sns:us-east-1:111122223333:inv-lab-ops
```

Nueve flags, y ninguno es relleno:

- `--namespace` y `--metric-name` identifican **qué** se mide. Los namespaces de AWS
  empiezan siempre por `AWS/`; los tuyos, como el `InvLab` de la sección anterior, no.
- `--dimensions Name=QueueName,Value=...` es la parte que más se olvida: sin dimensiones,
  la alarma vigila una métrica agregada que probablemente no existe y se queda en
  `INSUFFICIENT_DATA` para siempre. Las dimensiones tienen que coincidir **exactamente**
  con las que emite el servicio.
- `--statistic Maximum` frente a `Average` importa aquí: en cinco minutos, un solo
  mensaje en la DLQ da un promedio cercano a cero y un máximo de 1. Con `Average` la
  alarma no salta.
- `--period 300` es la ventana de agregación en segundos; `--evaluation-periods 1`, cuántas
  ventanas consecutivas tienen que incumplir para disparar. Multiplicadas, dan cuánto
  tarda la alarma en reaccionar: aquí, cinco minutos.
- `--threshold 0` con `--comparison-operator GreaterThanThreshold` significa "cualquier
  mensaje". En una DLQ, uno ya es demasiado.
- `--alarm-actions` recibe ARNs, casi siempre de un topic SNS. Si lo omites, la alarma
  cambia de estado y no se lo cuenta a nadie: se convierte en un color bonito en la consola.

⚠️ `--treat-missing-data` decide qué pasa cuando no hay datos. Con el valor por
defecto (`missing`), una cola sin tráfico deja la alarma en `INSUFFICIENT_DATA`, que
no es ni OK ni ALARM. Es la causa habitual de "la alarma nunca sonó".

---

## 6. 🧱 X-Ray

```yaml
  ApiFunction:
    Properties:
      TracingConfig:
        Mode: Active
```

El rol necesita `xray:PutTraceSegments` y `xray:PutTelemetryRecords`.

```bash
aws xray get-service-graph \
  --start-time "$(date -u -v-1H +%FT%TZ)" --end-time "$(date -u +%FT%TZ)" \
  --query 'Services[].{Name:Name,Type:Type,Errors:SummaryStatistics.ErrorStatistics.TotalCount}' \
  --output table
```

- `TracingConfig: Mode: Active` en el template hace que **Lambda** decida el muestreo y
  cree el segmento raíz. La alternativa, `PassThrough`, solo traza si quien la invocó ya
  venía trazando.
- `date -u -v-1H +%FT%TZ` es sintaxis de **BSD/macOS**. En Linux el equivalente es
  `date -u -d '1 hour ago' +%FT%TZ`. Si copias el comando en la máquina equivocada, el
  error que sale (`illegal option -- v`) no menciona la fecha por ningún lado.
- `get-service-graph` devuelve el mapa: nodos, aristas y estadísticas agregadas. Para ver
  una invocación concreta necesitas `get-trace-summaries` y luego `batch-get-traces`.

X-Ray da lo que Logs no da: el mapa de servicios y dónde se fue el tiempo dentro de
una invocación. Las primeras 100.000 trazas registradas al mes no tienen cargo.

---

## 7. 🩺 CloudTrail para diagnosticar un `AccessDenied`

Cuando algo devuelve `AccessDeniedException`, el log de la aplicación dice *qué* falló;
CloudTrail dice *quién* lo intentó y con qué identidad.

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=PutItem \
  --max-results 5 \
  --query 'Events[].{T:EventTime,U:Username,E:EventName}' --output table
```

- `lookup-events` consulta el **Event history**, que existe sin configurar nada y guarda
  90 días. No hace falta crear un Trail para esto, y no tiene cargo.
- `--lookup-attributes` admite **un solo atributo por llamada**: no puedes filtrar a la
  vez por `EventName` y por `Username`. Si necesitas cruzar dos criterios, filtras por uno
  y afinas con `--query` en local.
- ⚠️ El Event history registra **management events**, no data events. `PutItem` de
  DynamoDB y `GetObject` de S3 son data events: no aparecen aquí a menos que hayas creado
  un Trail que los capture explícitamente, y esos sí cobran. Es una de las confusiones más
  frecuentes sobre CloudTrail en entrevista.

Complemento sin costo y en frío: el simulador de políticas.

```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::111122223333:role/inv-lab-api-role \
  --action-names dynamodb:PutItem \
  --resource-arns arn:aws:dynamodb:us-east-1:111122223333:table/inv-lab-events \
  --query 'EvaluationResults[].{Accion:EvalActionName,Decision:EvalDecision}' --output table
```

⚠️ CloudTrail entrega los eventos de gestión con un retraso típico de hasta 15
minutos. Para depurar en caliente sirve el simulador, no CloudTrail.

---

# Parte II — Destrucción verificada

## 8. 🧭 El orden importa

```text
1. Borrar los stacks en orden inverso al de creación
   (app → datos), porque el de arriba depende del de abajo.
2. Esperar la confirmación de cada uno antes del siguiente.
3. Barrer huérfanos por tag.
4. Barrer por servicio lo que no lleva tag.
5. Confirmar económicamente a las 48 horas.
```

```bash
for STACK in inv-lab-app inv-lab-data; do
  aws cloudformation delete-stack --stack-name "$STACK"
  aws cloudformation wait stack-delete-complete --stack-name "$STACK" \
    && echo "OK  $STACK" \
    || echo "FALLO $STACK — revisar describe-stack-events"
done
```

Si un borrado falla, el motivo está en los eventos:

```bash
aws cloudformation describe-stack-events --stack-name inv-lab-app \
  --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table
```

---

## 9. 🩺 Lo que sobrevive al `delete-stack`

Esta tabla es el corazón del lab.

| Qué sobrevive | Por qué | Cómo detectarlo |
|---|---|---|
| Log groups creados por Lambda | Los crea CloudWatch, no el stack | `aws logs describe-log-groups --log-group-name-prefix /aws/lambda/inv-lab` |
| Objetos en S3 | CloudFormation no vacía buckets; el borrado falla o el bucket se retiene | `aws s3 ls` |
| Snapshots de RDS | `DeletionPolicy` por defecto `Snapshot` en instancias y clusters | `aws rds describe-db-snapshots --snapshot-type manual` |
| Volúmenes EBS `available` | Quedan sueltos si se retuvo la instancia | `aws ec2 describe-volumes --filters Name=status,Values=available` |
| Elastic IPs sin asociar | Cobran igual, estén en uso o no | `aws ec2 describe-addresses` |
| ENIs de Lambda en VPC | Se liberan con retraso y bloquean el borrado de subnets | `aws ec2 describe-network-interfaces` |
| Imágenes en ECR | El repositorio se borra, las imágenes cuestan mientras exista | `aws ecr describe-repositories` |
| Recursos con `--retain-resources` | Los abandonaste a propósito | Tu propia bitácora |
| Recursos creados a mano en consola | Nunca estuvieron en el stack | Barrido por tag y por servicio |

---

## 10. 🧪 Barrido por tag

Es el primer filtro y el más rápido, porque [`L01`](l01-preparacion-cli-y-blindaje-de-costos.md)
impuso el contrato de tagging.

```bash
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=inv-lab \
  --query 'ResourceTagMappingList[].ResourceARN' --output table
```

- `--tag-filters Key=...,Values=...` — fíjate en que `Values` va en plural y admite
  varios separados por comas. Con `Values` vacío, el filtro busca el recurso que tenga esa
  clave con **cualquier** valor, que a veces es justo lo que quieres para un barrido.
- La salida son ARNs, que es la forma correcta de listar recursos heterogéneos: el ARN te
  dice servicio, Region, cuenta y recurso de un vistazo.

Salida esperada tras un teardown correcto: vacía.

⚠️ La API de tagging es **regional** y solo cubre tipos de recurso que soportan tags.
Un log group creado por Lambda no aparece ahí. Por eso hace falta el paso siguiente.

Barrido en todas las regiones donde pudiste haber tocado algo:

```bash
for R in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  N=$(aws resourcegroupstaggingapi get-resources --region "$R" \
        --tag-filters Key=Project,Values=inv-lab \
        --query 'length(ResourceTagMappingList)' --output text 2>/dev/null)
  [ "$N" != "0" ] && [ -n "$N" ] && echo "$R: $N recursos"
done
```

- `describe-regions` lista solo las regiones **habilitadas** en tu cuenta. Las que están
  deshabilitadas no pueden tener recursos, así que la lista es exactamente la superficie
  que hay que barrer.
- `--region "$R"` sobrescribe, comando a comando, la Region de `AWS_REGION`. Es la única
  forma de recorrer todas sin cambiar la configuración de la shell.
- `length(...)` es una función de JMESPath que cuenta elementos, así evitas traerte y
  parsear la lista completa solo para saber si está vacía.
- `2>/dev/null` silencia los errores de las regiones donde el servicio no responde o no
  tienes permiso — sin eso, el bucle imprime ruido en cada iteración.

> ⚠️ Este barrido cuesta unos segundos por región y se hace **una vez al final de la
> serie**, no en cada sesión. Su valor es descubrir el recurso que creaste hace tres
> semanas en la Region equivocada y llevas pagando desde entonces.

---

## 11. 🧪 Barrido explícito por servicio

`verify-teardown.sh` — el entregable del lab.

```bash
#!/usr/bin/env bash
set -u
P=inv-lab
FAIL=0

check () {  # nombre, comando
  local out
  out=$(eval "$2" 2>/dev/null)
  if [ -n "$out" ] && [ "$out" != "None" ]; then
    echo "PENDIENTE  $1"; echo "$out" | sed 's/^/           /'; FAIL=1
  else
    echo "limpio     $1"
  fi
}

check "CloudFormation stacks" \
  "aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE DELETE_FAILED --query 'StackSummaries[?starts_with(StackName, \`$P\`)].StackName' --output text"
check "Lambda functions" \
  "aws lambda list-functions --query 'Functions[?starts_with(FunctionName, \`$P\`)].FunctionName' --output text"
check "Log groups" \
  "aws logs describe-log-groups --log-group-name-prefix /aws/lambda/$P --query 'logGroups[].logGroupName' --output text"
check "DynamoDB tables" \
  "aws dynamodb list-tables --query 'TableNames[?starts_with(@, \`$P\`)]' --output text"
check "SQS queues" \
  "aws sqs list-queues --queue-name-prefix $P --query 'QueueUrls' --output text"
check "SNS topics" \
  "aws sns list-topics --query 'Topics[?contains(TopicArn, \`$P\`)].TopicArn' --output text"
check "HTTP APIs" \
  "aws apigatewayv2 get-apis --query 'Items[?starts_with(Name, \`$P\`)].ApiId' --output text"
check "EventBridge rules" \
  "aws events list-rules --name-prefix $P --query 'Rules[].Name' --output text"
check "IAM roles" \
  "aws iam list-roles --query 'Roles[?starts_with(RoleName, \`$P\`)].RoleName' --output text"
check "Buckets S3" \
  "aws s3api list-buckets --query 'Buckets[?starts_with(Name, \`$P\`)].Name' --output text"
check "Parametros SSM" \
  "aws ssm describe-parameters --query 'Parameters[?starts_with(Name, \`/$P\`)].Name' --output text"
check "Alarmas CloudWatch" \
  "aws cloudwatch describe-alarms --alarm-name-prefix $P --query 'MetricAlarms[].AlarmName' --output text"
check "Volumenes EBS sueltos" \
  "aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[].VolumeId' --output text"
check "Elastic IPs sin asociar" \
  "aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].PublicIp' --output text"
check "NAT Gateways" \
  "aws ec2 describe-nat-gateways --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId' --output text"
check "Snapshots RDS manuales" \
  "aws rds describe-db-snapshots --snapshot-type manual --query 'DBSnapshots[].DBSnapshotIdentifier' --output text"
check "Repositorios ECR" \
  "aws ecr describe-repositories --query 'repositories[?starts_with(repositoryName, \`$P\`)].repositoryName' --output text"

echo
[ "$FAIL" -eq 0 ] && echo "TEARDOWN VERIFICADO: no quedan recursos del lab." \
                  || echo "TEARDOWN INCOMPLETO: revisa las lineas PENDIENTE."
exit "$FAIL"
```

Los cuatro últimos chequeos no crean nada en esta serie de labs, pero se dejan a
propósito: son los recursos que cobran por hora y el día que hagas un lab con EC2,
RDS o EKS, el script ya los cubre.

⚠️ Existen herramientas de terceros que borran cuentas enteras por criterios amplios.
No se usan aquí: en una cuenta personal donde también vive algo que sí quieres
conservar, el riesgo de una limpieza automática supera a la comodidad.

---

## 12. 💰 Confirmación económica

El barrido demuestra que no hay recursos. La factura demuestra que no hay cargos, y
llega más tarde.

```bash
# gasto del proyecto, ultimos 7 dias
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -v-7d +%F),End=$(date -u +%F) \
  --granularity DAILY --metrics UnblendedCost \
  --filter '{"Tags":{"Key":"Project","Values":["inv-lab"]}}' \
  --query 'ResultsByTime[].{Fecha:TimePeriod.Start,USD:Total.UnblendedCost.Amount}' --output table

# gasto por servicio, para descubrir lo que el tag no capturo
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -v-7d +%F),End=$(date -u +%F) \
  --granularity DAILY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[-1].Groups[?Metrics.UnblendedCost.Amount!=`0`].{Servicio:Keys[0],USD:Metrics.UnblendedCost.Amount}' \
  --output table
```

```text
Secuencia de certeza:

  hoy      → verify-teardown.sh en verde   (no hay recursos)
  +24 h    → Cost Explorer sin gasto nuevo (no hubo cargos ayer)
  +48 h    → segunda lectura, ya estable   (confirmado)
  fin mes  → Billing > Bills por servicio  (cierre definitivo)
```

La red de seguridad de fondo es el budget de gasto cero de
[`L01`](l01-preparacion-cli-y-blindaje-de-costos.md): si algo sobrevivió,
te avisa por correo sin que tengas que acordarte de mirar.

---

## 13. 📋 El checklist de certeza

- [ ] Todos los stacks del lab devuelven `does not exist`.
- [ ] `verify-teardown.sh` termina con código de salida 0.
- [ ] El barrido por tag está vacío en todas las regiones consultadas.
- [ ] No queda ningún log group `/aws/lambda/inv-lab*`.
- [ ] No hay volúmenes EBS `available`, Elastic IPs sueltas ni NAT Gateways.
- [ ] Cost Explorer muestra gasto en descenso a cero a las 48 horas.
- [ ] El budget de gasto cero no ha disparado ninguna alerta.
- [ ] Anotaste en la bitácora cualquier recurso retenido a propósito.

---

## 🧠 Preguntas rápidas

1. ¿Qué le pasa a un log group sin `RetentionInDays` y por qué importa económicamente?
2. ¿Qué ventaja tiene EMF frente a `PutMetricData` dentro de una Lambda?
3. ¿Qué campo del log `REPORT` mide el cold start?
4. ¿Por qué una alarma sobre una cola sin tráfico se queda en `INSUFFICIENT_DATA`?
5. ¿Qué responde CloudTrail que el log de la aplicación no responde?
6. ¿Qué retraso típico tiene CloudTrail y qué herramienta usarías para depurar en caliente?
7. ¿Por qué la API de Resource Groups Tagging no basta para verificar un teardown?
8. Nombra cuatro recursos que sobreviven a un `delete-stack` exitoso.
9. ¿Por qué hay que barrer varias regiones y no solo la del lab?
10. ¿Cuánto tarda Cost Explorer en reflejar el gasto y qué implica para el orden de verificación?
11. ¿Qué hace `aws cloudformation wait stack-delete-complete` y por qué conviene encadenarlo?
12. ¿Cuál es la red de seguridad si el barrido se te olvida por completo?

---

## 🧪 Ejercicios (14)

Los obligatorios cuestan **centavos o $0.00**. Ojo con uno solo: las alarmas por encima de
las diez gratuitas de la cuenta cuestan $0.10 al mes cada una, así que los ejercicios que
crean alarmas terminan borrándolas.

### 🟢 Fácil — mirar bien (1–4)

#### 🟢 Ejercicio 1 — Auditar la retención de toda la cuenta

Lista **todos** los log groups sin `RetentionInDays`, con sus bytes almacenados, y
ordénalos de mayor a menor.

**Pregunta:** ¿cuántos hay que no creó ningún stack tuyo, y de dónde salieron?

#### 🟢 Ejercicio 2 — La consulta que no terminó

Lanza una consulta de Logs Insights y llama a `get-query-results` inmediatamente, antes de
que termine. Lee la respuesta completa.

**Objetivo:** reconocer `status: Running` como una respuesta válida y no como un error, que
es el tropiezo número uno al automatizar Logs Insights.

#### 🟢 Ejercicio 3 — Cold starts reales, no supuestos

Con la consulta de `@initDuration` de la §3, mide cuántas de tus últimas cincuenta
invocaciones tuvieron cold start y cuánto costó cada una.

**Pregunta:** ¿qué porcentaje resultó ser? ¿Coincide con lo que habrías dicho de memoria
antes de medirlo?

#### 🟢 Ejercicio 4 — Memoria asignada contra memoria usada

Corre la tercera consulta de la §3 y compara `MB_usados` con `MB_asignados` en las tres
funciones.

**Objetivo:** descubrir si estás pagando memoria que nadie usa, que es la optimización de
costo más fácil de todo el lab.

### 🟡 Intermedio — instrumentar (5–9)

#### 🟡 Ejercicio 5 — Una métrica de negocio con EMF

Añade a `inv-lab-alert` una métrica EMF propia —unidades por tienda, o alertas emitidas—
y verifícala con `list-metrics`. No añadas ningún permiso al rol.

**Pregunta:** ¿por qué funcionó sin tocar el execution role, y qué habrías tenido que
añadir si hubieras usado `PutMetricData`?

#### 🟡 Ejercicio 6 — La alarma que no suena

Crea la alarma de la DLQ **sin** `--treat-missing-data`, comprueba su estado, y después
recréala con `notBreaching`. Bórralas al terminar.

**Objetivo:** ver `INSUFFICIENT_DATA` con tus ojos y entender por qué no es ni OK ni ALARM
— y por qué una alarma en ese estado no le cuenta nada a nadie.

#### 🟡 Ejercicio 7 — Dispararla de verdad

Manda un mensaje directamente a la DLQ con `send-message` y comprueba que la alarma pasa a
`ALARM` y que llega la notificación. Vacía la DLQ y borra la alarma después.

**Pregunta:** ¿cuánto tardó en dispararse, y de qué dos parámetros salió ese tiempo?

#### 🟡 Ejercicio 8 — Un trace completo

Activa `TracingConfig: Mode: Active` en las tres funciones, añade los permisos de X-Ray,
manda un movimiento y busca el trace resultante.

**Pregunta:** ¿aparece el recorrido entero o hay un salto que no reporta? ¿Por qué el
tramo por SQS se ve distinto al de API Gateway?

#### 🟡 Ejercicio 9 — Quién borró qué

Borra a mano el parámetro SSM y localiza en CloudTrail quién lo hizo, con qué identidad y
desde qué IP. Vuelve a crearlo desplegando el stack de
[`L02`](l02-cloudformation-desde-la-cli.md).

**Objetivo:** practicar `lookup-events` sobre un evento de gestión antes de necesitarlo en
un incidente real.

### 🟠 Difícil — el hueco entre lo que ves y lo que hay (10–12)

#### 🟠 Ejercicio 10 — El `AccessDenied` que CloudTrail no ve

Provoca un `AccessDenied` al escribir en DynamoDB y búscalo en el Event history de
CloudTrail.

**Pregunta:** ¿aparece? Si no, ¿por qué, y qué herramienta usarías en su lugar para
resolverlo hoy sin activar nada que cobre?

#### 🟠 Ejercicio 11 — Lo que el tag no encuentra

Con el sistema desplegado, corre el barrido por tag y en paralelo enumera los log groups
del proyecto. Compara las dos listas.

**Pregunta:** ¿qué recursos aparecen en una y no en la otra, y cuál es la razón de cada
ausencia?

#### 🟠 Ejercicio 12 — El huérfano en otra región

Crea a propósito un recurso barato y etiquetado en una región que no sea la del lab —una
tabla DynamoDB on-demand vacía sirve y no cuesta—, y después encuéntralo **solo** con el
barrido multi-región. Bórralo.

**Objetivo:** comprobar que un recurso invisible en tus listados habituales sigue
existiendo, que es el caso que el paso 3 de
[`A02` §7](a02-costos-trampas-y-recursos-huerfanos.md#7--si-aparece-un-cargo-inesperado)
resuelve.

### 🔴 Muy difícil — certeza (13–14)

#### 🔴 Ejercicio 13 — Ampliar `verify-teardown.sh`

Añade al script tres comprobaciones que hoy no tiene y que harían falta el día que hagas
un drill con EC2 o EKS: interfaces de red sueltas, nodegroups y clusters. Que el script
siga saliendo con código 0 en una cuenta limpia.

**Objetivo:** que el verificador sirva más allá de esta serie, que es lo que lo convierte
en una herramienta y no en un anexo del lab.

#### 🔴 Ejercicio 14 — Predecir la factura

Antes de mirar Cost Explorer, escribe cuánto crees que costó la serie completa, desglosado
por servicio. Espera a las 48 horas y compara contra el desglose real por `SERVICE` y por
`USAGE_TYPE`.

**Pregunta:** ¿qué línea de costo no habías previsto? Casi siempre hay una, y ese hueco es
justamente el que te faltaba entender.

### 🔥 Opcionales y ampliaciones

- **Dashboard con las cuatro alarmas.** Crea un dashboard de CloudWatch con las métricas
  de la §5. Los tres primeros dashboards de la cuenta no tienen cargo.
- **Log Alarm sobre Logs Insights.** Programa una consulta de Logs Insights y alarma sobre
  su resultado, en vez de sobre una métrica.
- **Comparar regiones.** Repite [`L03`](l03-backend-serverless-lambda-api-y-eventos.md) completo en `sa-east-1` y compara el desglose de
  costo con el de `us-east-1`. 💰 Sigue siendo centavos, pero deja de ser $0.00: es el
  ejercicio de FinOps que
  [`L00` §11](l00-idea-lab-practico.md#11--decisiones-abiertas-y-ampliaciones-naturales) anota como pendiente.
- **X-Ray con OpenTelemetry.** Sustituye el SDK de X-Ray por el ADOT y comprueba que el
  mapa de servicios sale igual.

### 💀 Boss fight — el proyecto final de la serie

Este es el boss de todo el recorrido, no solo de este lab, y solo se puede intentar
después de `L01`–`L04`. El encargo es este:

> **Levanta el sistema completo desde una cuenta vacía, demuéstralo funcionando,
> destrúyelo con certeza y demuestra que no queda nada — con un único comando por fase y
> sin abrir la consola en ningún momento.**

Entregables, los cuatro:

1. **`up.sh`** — despliega los dos stacks en orden, espera a cada uno, y termina
   imprimiendo el endpoint del API. Idempotente: correrlo dos veces no rompe nada.
2. **`smoke.sh`** — manda un movimiento, comprueba que llega a la tabla, que el projector
   lo procesó y que la alerta se publicó. Sale con código distinto de cero si cualquiera
   de los tres pasos falla.
3. **`down.sh`** — destruye todo en orden inverso, incluidos los recursos que **no**
   pertenecen a ningún stack: los log groups, y lo que hayas retenido.
4. **`verify.sh`** — el `verify-teardown.sh` de la §11, ampliado con el ejercicio 13, más
   la comprobación económica a las 48 horas.

**Criterio de terminado, y no admite matices:** un ciclo completo
`up.sh && smoke.sh && down.sh && verify.sh` termina en verde, tarda menos de quince
minutos de reloj, el barrido por tag devuelve vacío en todas las regiones habilitadas, y
Cost Explorer confirma el gasto esperado —centavos— a las 48 horas.

**Objetivo:** es la respuesta ejecutable a la pregunta con la que abre [`L00`](l00-idea-lab-practico.md): *"el
laboratorio no se mide por lo que despliegas, sino por lo que destruyes y vuelves a
levantar sin intervención manual"*. Cuando esos cuatro scripts existen y funcionan, la
serie está terminada de verdad.

---

## 🏁 La señal de que quedó bien

> `aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=inv-lab`
> devuelve una lista vacía, el barrido explícito por servicio no encuentra nada, y a las
> 48 horas Cost Explorer confirma $0.00 para el proyecto. Levantar todo otra vez desde
> cero me cuesta un `deploy` y quince minutos, sin tocar la consola ni una vez.

---

## 📚 Referencias oficiales

- CloudWatch Logs, retención: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html
- CloudWatch Logs Insights, sintaxis de consultas: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html
- Embedded Metric Format: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html
- Alarmas de CloudWatch y datos faltantes: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Alarms.html#alarms-and-missing-data
- Métricas de Lambda: https://docs.aws.amazon.com/lambda/latest/dg/monitoring-metrics.html
- AWS X-Ray: https://docs.aws.amazon.com/xray/latest/devguide/aws-xray.html
- CloudTrail `lookup-events`: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events-cli.html
- IAM Policy Simulator: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_testing-policies.html
- Resource Groups Tagging API: https://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html
- Borrado de stacks y solución de problemas: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/troubleshooting.html#troubleshooting-errors-delete-stack-does-not-delete-resources
- Cost Explorer API `get-cost-and-usage`: https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetCostAndUsage.html
- Waiters de la AWS CLI: https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/
