# L03 — Backend serverless: Lambda, HTTP API y eventos

> **Objetivo:** construir el backend completo sin un solo componente que cobre por hora,
> y entender la costura entre tu código y AWS: quién invoca a quién y con qué permiso.
> **Costo esperado:** centavos, y en muchos casos $0.00 por las cuotas *always free*.
> **Duración:** 3–4 horas.
> **Prerrequisito:** [`L02`](l02-cloudformation-desde-la-cli.md) cerrado (la tabla
> `inv-lab-events` y el parámetro SSM existen).
> **Deja encendido:** el sistema completo —HTTP API, tres funciones, cola, DLQ y topic—.
> Nada cobra por hora, pero los log groups sí retienen;
> [`L04`](l04-observabilidad-y-destruccion-verificada.md) los ajusta y lo destruye todo.
> **Teoría de apoyo:** [`05`](05-seguridad-iam-kms-secretos.md),
> [`04`](04-dynamodb-nosql.md) y [`07`](07-mensajeria-eventos-integracion.md).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Qué practica este lab](#1--qué-practica-este-lab) · [Cuotas always free relevantes](#2--cuotas-always-free-relevantes) · [Arquitectura](#3--arquitectura) · [Decisión: este lab no usa VPC](#4--decisión-este-lab-no-usa-vpc) · [Un execution role por función](#5--un-execution-role-por-función) · [La función de API](#6--la-función-de-api) · [HTTP API y el permiso que sí hace falta](#7--http-api-y-el-permiso-que-sí-hace-falta) · [Event source mapping: DynamoDB Streams](#8--event-source-mapping-dynamodb-streams) · [SQS, DLQ y el timeout de visibilidad](#9--sqs-dlq-y-el-timeout-de-visibilidad) · [Idempotencia](#10--idempotencia) · [Concurrencia](#11--concurrencia) · [Los log groups se declaran, no se heredan](#12--los-log-groups-se-declaran-no-se-heredan) · [Probar y observar desde la CLI](#13--probar-y-observar-desde-la-cli) · [Fallos que hay que provocar a propósito](#14--fallos-que-hay-que-provocar-a-propósito) · [Checklist de salida](#15--checklist-de-salida) · [Preguntas rápidas](#-preguntas-rápidas) · [Ejercicios](#-ejercicios-16) · [La señal de que quedó bien](#-la-señal-de-que-quedó-bien) · [Referencias oficiales](#-referencias-oficiales)

Tercer lab. Construye el backend completo del sistema de inventario sin ningún
componente que cobre por hora: sin ALB, sin Fargate, sin RDS, sin NAT Gateway, sin
frontend. Todo el stack se despliega y se destruye desde la CLI con CloudFormation.

---

## 1. 🧭 Qué practica este lab

| Tema | Por qué es específico de AWS |
|---|---|
| Modelo de ejecución de Lambda | Cold start, límites, concurrencia y facturación por GB-segundo no existen fuera de AWS |
| Execution role frente a resource policy | Es la distinción push/pull que separa a quien entendió IAM de quien no |
| Event source mapping | El servicio hace el polling; tu función no |
| Fallos parciales de lote | Es la causa número uno de reprocesamiento masivo en producción |
| Cuotas y throttling | Los límites de cuenta son el mecanismo real de contención |

---

## 2. 💰 Cuotas always free relevantes

Estas cuotas se renuevan cada mes y no vencen con la antigüedad de la cuenta. Conviene
verificarlas en la página oficial antes del lab, porque AWS las ajusta.

| Servicio | Cuota mensual gratuita | Consumo esperado del lab |
|---|---|---|
| Lambda | 1 M invocaciones + 400.000 GB-segundo | Cientos de invocaciones |
| DynamoDB | 25 GB de almacenamiento | Kilobytes |
| SQS | 1 M solicitudes | Cientos |
| SNS | 1 M publicaciones | Decenas |
| CloudWatch Logs | 5 GB de ingesta | Megabytes |
| X-Ray | 100.000 trazas registradas | Decenas |
| API Gateway HTTP API | Sin cuota always free; $1.00 por millón de solicitudes | Fracción de centavo |
| EventBridge | Eventos de servicios AWS sin cargo; eventos propios $1.00 por millón | Fracción de centavo |

> Regla: este lab no es "barato". Es **de centavos**, y la diferencia importa: lo que
> te va a costar dinero algún día es olvidar apagado algo que cobra por hora, no
> invocar una Lambda diez mil veces.

---

## 3. 🧭 Arquitectura

```text
  curl / aws lambda invoke
        │
        ▼
  API Gateway (HTTP API, payload 2.0)
        │  push  ─── requiere AWS::Lambda::Permission
        ▼
  inv-lab-api  (Lambda)
        │  put_item con ConditionExpression
        ▼
  DynamoDB inv-lab-events  ──► Stream (NEW_AND_OLD_IMAGES)
                                     │  pull ─── usa el execution role
                                     ▼
                              inv-lab-projector (Lambda)
                                     │  agrega stock, detecta umbral
                                     ▼
                              SQS inv-lab-alerts ──► DLQ inv-lab-alerts-dlq
                                     │  pull
                                     ▼
                              inv-lab-alert (Lambda) ──► métrica EMF + SNS
```

---

## 4. 🧭 Decisión: este lab no usa VPC

Poner las Lambdas en una VPC obligaría a un NAT Gateway o a varios Interface
endpoints para que alcancen DynamoDB y SQS, y ambos cobran por hora. Sin VPC, las
funciones salen por la red administrada de Lambda y hablan con los endpoints públicos
de los servicios, autenticadas por IAM.

> Punto importante: no poner una Lambda en la VPC es la opción correcta **salvo que
> necesite alcanzar algo que solo vive dentro de la VPC** (una RDS privada, un
> ElastiCache, un servicio on-premises por VPN). No es una decisión de seguridad: el
> control de acceso a DynamoDB y SQS lo hace IAM, no la red.

⚠️ Una Lambda en VPC crea ENIs. Esas ENIs pueden sobrevivir un rato al borrado del
stack y bloquear el borrado de las subnets. Es un caso clásico de `DELETE_FAILED`.

---

## 5. 🧱 Un execution role por función

El atajo de un rol compartido con `Resource: "*"` es el error más común y el más
fácil de detectar en una entrevista.

```yaml
  ApiFunctionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal: { Service: lambda.amazonaws.com }
            Action: sts:AssumeRole
      Policies:
        - PolicyName: api-min
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action: [dynamodb:PutItem, dynamodb:Query]
                Resource: !GetAtt EventsTable.Arn
              - Effect: Allow
                Action: [logs:CreateLogStream, logs:PutLogEvents]
                Resource: !Sub 'arn:${AWS::Partition}:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/lambda/${ProjectName}-api:*'
```

Propiedad por propiedad, porque cada línea de ese bloque decide algo:

- **`Principal: { Service: lambda.amazonaws.com }`** — el servicio de Lambda es quien
  asume el rol, no tú. Si escribes ahí `ec2.amazonaws.com` por copiar de otro template,
  el rol se crea sin error y la función falla al arrancar con un mensaje que no menciona
  la trust policy por ningún lado.
- **`Action: sts:AssumeRole`** — la única acción que va en una trust policy. No es
  `iam:PassRole` ni `lambda:InvokeFunction`; es la operación de STS que convierte la
  identidad del servicio en credenciales temporales.
- **`Resource: !GetAtt EventsTable.Arn`** — el ARN exacto de la tabla, no `"*"`. Ojo con
  una trampa: este ARN **no** cubre los índices de la tabla. Para consultar un GSI hace
  falta añadir `!Sub '${EventsTable.Arn}/index/*'`, y el `AccessDenied` que sale si lo
  olvidas menciona la tabla, no el índice.
- **`arn:${AWS::Partition}:logs:...`** — `AWS::Partition` vale `aws` en las regiones
  comerciales, `aws-cn` en China y `aws-us-gov` en GovCloud. Escribir `arn:aws:` a mano
  funciona hasta el día que el template se despliega en otra partición.
- **El `:*` final del ARN del log group** no es un descuido: los permisos de
  `PutLogEvents` se conceden sobre los *log streams* que cuelgan del grupo, y ese comodín
  es el que los cubre.

Y dos matices que valen en entrevista:

- La **trust policy** (`AssumeRolePolicyDocument`) dice *quién puede asumir el rol*;
  la **permissions policy** dice *qué puede hacer una vez asumido*. Son documentos
  distintos y confundirlos es un error frecuente.
- La política administrada `AWSLambdaBasicExecutionRole` resuelve los permisos de
  logs, pero concede `logs:CreateLogGroup` sobre toda la cuenta. En un lab que
  practica menor privilegio, se escribe a mano.

---

## 6. 🧱 La función de API

`Code.ZipFile` permite código inline en el template: sin build, sin bucket de
artefactos, sin SAM. El límite es 4096 caracteres y no admite dependencias externas
—`boto3` viene incluido en el runtime de Python—, así que sirve para un lab y no
para producción.

```yaml
  ApiFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub '${ProjectName}-api'
      Runtime: python3.13
      Handler: index.handler
      Role: !GetAtt ApiFunctionRole.Arn
      Timeout: 10
      MemorySize: 256
      Environment:
        Variables:
          TABLE: !Ref EventsTable
      Code:
        ZipFile: |
          import json, os, time, uuid, boto3
          from boto3.dynamodb.conditions import Key
          T = boto3.resource('dynamodb').Table(os.environ['TABLE'])

          def handler(event, ctx):
              route = event.get('routeKey', '')
              store = (event.get('pathParameters') or {}).get('storeId')
              if route.startswith('POST'):
                  body = json.loads(event.get('body') or '{}')
                  key = (event.get('headers') or {}).get('idempotency-key') or str(uuid.uuid4())
                  now = int(time.time())
                  try:
                      T.put_item(
                          Item={'PK': f'STORE#{store}', 'SK': f'MOV#{key}',
                                'productId': body['productId'],
                                'quantity': int(body['quantity']),
                                'ts': now, 'expiresAt': now + 86400},
                          ConditionExpression='attribute_not_exists(SK)')
                  except T.meta.client.exceptions.ConditionalCheckFailedException:
                      return {'statusCode': 200,
                              'body': json.dumps({'status': 'duplicate', 'movementId': key})}
                  return {'statusCode': 201, 'body': json.dumps({'movementId': key})}
              r = T.query(KeyConditionExpression=Key('PK').eq(f'STORE#{store}')
                          & Key('SK').begins_with('STOCK#'))
              return {'statusCode': 200, 'body': json.dumps(r['Items'], default=str)}
```

---

## 7. 🧱 HTTP API y el permiso que sí hace falta

```yaml
  HttpApi:
    Type: AWS::ApiGatewayV2::Api
    Properties:
      Name: !Sub '${ProjectName}-api'
      ProtocolType: HTTP

  ApiIntegration:
    Type: AWS::ApiGatewayV2::Integration
    Properties:
      ApiId: !Ref HttpApi
      IntegrationType: AWS_PROXY
      IntegrationUri: !GetAtt ApiFunction.Arn
      PayloadFormatVersion: '2.0'

  SalesRoute:
    Type: AWS::ApiGatewayV2::Route
    Properties:
      ApiId: !Ref HttpApi
      RouteKey: 'POST /stores/{storeId}/sales'
      Target: !Sub 'integrations/${ApiIntegration}'

  DefaultStage:
    Type: AWS::ApiGatewayV2::Stage
    Properties:
      ApiId: !Ref HttpApi
      StageName: $default
      AutoDeploy: true

  ApiInvokePermission:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref ApiFunction
      Action: lambda:InvokeFunction
      Principal: apigateway.amazonaws.com
      SourceArn: !Sub 'arn:${AWS::Partition}:execute-api:${AWS::Region}:${AWS::AccountId}:${HttpApi}/*/*'
```

Aquí está la distinción central del lab:

```text
PUSH  → API Gateway, EventBridge, SNS, S3 invocan a Lambda
        Necesitan AWS::Lambda::Permission (resource-based policy en la función).
        El execution role de la función NO interviene en la autorización de entrada.

PULL  → DynamoDB Streams, Kinesis, SQS, MSK
        Lambda hace polling con SU PROPIO execution role.
        No hay resource policy; el rol necesita permiso de lectura sobre la fuente.
```

> Regla de entrevista: si te preguntan "¿por qué mi Lambda no se dispara desde S3?",
> la respuesta casi siempre es que falta la resource-based policy, no un permiso en
> el execution role.

⚠️ `PayloadFormatVersion: '2.0'` cambia la forma del `event`: no hay `httpMethod` ni
`path`, hay `routeKey` y `rawPath`. Un handler escrito para REST API v1 falla en
silencio con un `KeyError`.

---

## 8. 🧱 Event source mapping: DynamoDB Streams

```yaml
  ProjectorMapping:
    Type: AWS::Lambda::EventSourceMapping
    Properties:
      EventSourceArn: !GetAtt EventsTable.StreamArn
      FunctionName: !Ref ProjectorFunction
      StartingPosition: LATEST
      BatchSize: 10
      MaximumBatchingWindowInSeconds: 5
      MaximumRetryAttempts: 3
      MaximumRecordAgeInSeconds: 3600
      BisectBatchOnFunctionError: true
      FunctionResponseTypes: [ReportBatchItemFailures]
      DestinationConfig:
        OnFailure:
          Destination: !GetAtt StreamFailuresQueue.Arn
```

Nueve propiedades, y conviene leerlas en dos grupos. Primero, las que definen **cómo se
lee** el stream:

- **`StartingPosition: LATEST`** empieza por los registros nuevos e ignora lo que ya
  había en el stream. La alternativa, `TRIM_HORIZON`, arranca por el registro más viejo
  disponible — que en un lab donde ya escribiste datos significa procesar de golpe todo
  el histórico. Para Kinesis existe además `AT_TIMESTAMP`.
- **`BatchSize: 10`** es el **máximo** de registros por invocación, no una garantía:
  si solo hay tres, la función recibe tres.
- **`MaximumBatchingWindowInSeconds: 5`** es cuánto espera Lambda a llenar el lote antes
  de invocar de todos modos. Sin él, con poco tráfico tendrías una invocación por
  registro; con él, cambias hasta 5 segundos de latencia por muchas menos invocaciones.

Y después, las que definen **qué pasa cuando falla**. Cada una corresponde a un fallo
real:

| Parámetro | Qué evita |
|---|---|
| `MaximumRetryAttempts` | Que un registro venenoso reintente hasta que expire el stream |
| `MaximumRecordAgeInSeconds` | Que se procesen eventos ya irrelevantes tras una caída larga |
| `BisectBatchOnFunctionError` | Que un solo registro malo invalide un lote de cien |
| `DestinationConfig.OnFailure` | Que el registro fallido se pierda sin dejar rastro |
| `ReportBatchItemFailures` | Que se reprocese el lote completo por un elemento |

⚠️ Sin `ReportBatchItemFailures`, si un solo registro del lote falla, Lambda reintenta
**todo el lote**. Los registros que ya se habían procesado se procesan otra vez: si
la función no es idempotente, duplicas datos.

Con la opción activa, la función devuelve los identificadores que fallaron:

```python
def handler(event, ctx):
    failures = []
    for rec in event['Records']:
        try:
            procesar(rec)
        except Exception:
            failures.append({'itemIdentifier': rec['eventID']})
    return {'batchItemFailures': failures}
```

---

## 9. 🧱 SQS, DLQ y el timeout de visibilidad

```yaml
  AlertsDLQ:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub '${ProjectName}-alerts-dlq'
      MessageRetentionPeriod: 1209600      # 14 días, el máximo

  AlertsQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub '${ProjectName}-alerts'
      VisibilityTimeout: 180                # 6x el timeout de la función
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt AlertsDLQ.Arn
        maxReceiveCount: 3
```

```text
Regla: VisibilityTimeout de la cola ≥ 6 × Timeout de la función.
Si es menor, el mensaje reaparece mientras aún se está procesando
y se procesa dos veces.
```

Reenviar mensajes desde la DLQ a la cola original, sin escribir código:

```bash
aws sqs start-message-move-task \
  --source-arn arn:aws:sqs:us-east-1:111122223333:inv-lab-alerts-dlq
```

- `--source-arn` es la **DLQ**, no la cola original. Sin `--destination-arn`, SQS devuelve
  los mensajes a la cola desde la que llegaron, que es lo que quieres en el 90 % de los
  casos y por eso el flag se omite aquí.
- Es una tarea asíncrona: el comando devuelve un `TaskHandle` y el movimiento ocurre en
  segundo plano. Se sigue con `aws sqs list-message-move-tasks --source-arn ...`.

> ⚠️ Reenviar desde la DLQ **sin haber arreglado la causa** devuelve los mensajes al
> mismo camino que los mató, y vuelven a la DLQ tras consumir otro ciclo de reintentos.
> El redrive es el último paso de un arreglo, nunca el primero.

---

## 10. 🧱 Idempotencia

La clave del lab está en el `ConditionExpression` de la función de API:

```python
ConditionExpression='attribute_not_exists(SK)'
```

Con la misma cabecera `Idempotency-Key`, el segundo intento lanza
`ConditionalCheckFailedException` y la función responde 200 con `status: duplicate`
en vez de duplicar el movimiento. Esa es la respuesta correcta a "un cliente
reintentó por timeout y me cobró dos veces".

Prueba:

```bash
API=$(aws cloudformation describe-stacks --stack-name inv-lab-app \
      --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text)

for i in 1 2 3; do
  curl -s -X POST "$API/stores/S1/sales" \
    -H 'idempotency-key: fixed-123' \
    -H 'content-type: application/json' \
    -d '{"productId":"P1","quantity":2}'
  echo
done
```

```text
{"movementId": "fixed-123"}
{"status": "duplicate", "movementId": "fixed-123"}
{"status": "duplicate", "movementId": "fixed-123"}
```

El `--query` de la primera línea merece una lectura despacio, porque combina tres cosas
de JMESPath que aparecen todo el rato: `Stacks[0]` toma el único stack de la lista,
`Outputs[?OutputKey=='ApiEndpoint']` filtra la lista de outputs por el valor de un campo
(y las comillas simples de `'ApiEndpoint'` son obligatorias: es un literal de texto), y
`.OutputValue` proyecta solo ese campo. Con `--output text` el resultado sale sin comillas
y listo para interpolarlo en la URL.

---

## 11. 🧱 Concurrencia

| Tipo | Qué hace | Costo |
|---|---|---|
| Concurrencia sin reservar | Comparte el límite de la cuenta (por defecto 1.000 por región) | Sin cargo adicional |
| Reserved concurrency | Aparta un tope máximo para la función; también actúa como límite | Sin cargo adicional |
| Provisioned concurrency | Mantiene entornos inicializados para eliminar el cold start | **Cobra por hora**, aunque no haya tráfico |

⚠️ Provisioned concurrency es de los pocos elementos serverless que cobran por hora.
En este lab no se usa; si lo pruebas, apágalo en la misma sesión.

Reserved concurrency en `0` es, además, el interruptor de emergencia: deja de invocar
la función sin borrarla.

```bash
aws lambda put-function-concurrency \
  --function-name inv-lab-projector --reserved-concurrent-executions 0
```

- `--reserved-concurrent-executions` hace **dos cosas a la vez**, y esa doble naturaleza
  es pregunta de entrevista: garantiza esa concurrencia a la función (nadie más de la
  cuenta se la puede quitar) y a la vez se la limita a ese techo.
- El valor `0` es el caso extremo: reserva cero, luego la función no puede ejecutarse. Las
  invocaciones se rechazan con `Throttles`, y la función queda intacta para inspeccionarla.
- Se revierte con `aws lambda delete-function-concurrency --function-name inv-lab-projector`,
  que devuelve la función al pool compartido de la cuenta. **No** se revierte poniendo un
  número alto.

---

## 12. 🧱 Los log groups se declaran, no se heredan

Cuando una Lambda escribe su primer log, CloudWatch crea `/aws/lambda/<nombre>` con
retención **"Never expire"**. Ese log group **no pertenece al stack** y sobrevive al
`delete-stack`. Es la fuga más común de un lab serverless.

```yaml
  ApiLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub '/aws/lambda/${ProjectName}-api'
      RetentionInDays: 3
```

⚠️ Si la función ya escribió logs antes de que el stack declarara el log group, la
creación falla con `already exists`. En ese caso se borra el log group a mano y se
vuelve a desplegar. Declararlo desde el primer despliegue evita el problema.

---

## 13. 🧪 Probar y observar desde la CLI

```bash
# invocar directamente, saltándose API Gateway
aws lambda invoke --function-name inv-lab-api \
  --cli-binary-format raw-in-base64-out \
  --payload '{"routeKey":"POST /stores/{storeId}/sales","pathParameters":{"storeId":"S1"},"headers":{},"body":"{\"productId\":\"P1\",\"quantity\":1}"}' \
  /dev/stdout

# seguir logs en vivo
aws logs tail /aws/lambda/inv-lab-projector --follow --format short

# estado del event source mapping
aws lambda list-event-source-mappings --function-name inv-lab-projector \
  --query 'EventSourceMappings[].{UUID:UUID,State:State,LastResult:LastProcessingResult}' \
  --output table

# profundidad de la DLQ
aws sqs get-queue-attributes --queue-url "$DLQ_URL" \
  --attribute-names ApproximateNumberOfMessages
```

Los cuatro, uno por uno:

- **`lambda invoke`** — `--cli-binary-format raw-in-base64-out` es obligatorio en la CLI
  v2: sin él, la CLI interpreta el `--payload` como base64 y falla con un error de
  codificación inválida que no menciona el flag. El `/dev/stdout` del final es el archivo
  de salida, y usarlo así imprime la respuesta en pantalla en vez de crear un fichero.
  Este comando invoca la función **saltándose API Gateway**, así que si funciona aquí y
  falla por HTTP, el problema está en el API o en la resource-based policy, no en el código.
- **`logs tail --follow`** — `--follow` deja el comando abierto siguiendo el log en vivo,
  como `tail -f`. `--format short` recorta el timestamp largo y deja el mensaje legible.
  Acepta también `--since 10m` para arrancar con contexto reciente.
- **`list-event-source-mappings`** — `LastProcessingResult` es el campo que hay que mirar:
  dice literalmente por qué se atascó el mapping. Y `State` distingue `Enabled` de
  `Disabled` y de `Creating`, que explica por qué un mapping recién creado todavía no
  procesa nada.
- **`get-queue-attributes`** — `ApproximateNumberOfMessages` es **aproximado** a propósito,
  por la naturaleza distribuida de SQS. Sirve para saber si la DLQ tiene algo o no; no
  sirve para llevar una cuenta exacta.

---

## 14. 🩺 Fallos que hay que provocar a propósito

| Provocación | Síntoma | Causa que hay que reconocer |
|---|---|---|
| Quitar `AWS::Lambda::Permission` | 500 en el endpoint, cero logs de la función | Falta resource-based policy: la invocación ni llega |
| Quitar `dynamodb:PutItem` del rol | 502 y `AccessDeniedException` en los logs | Execution role insuficiente |
| Bajar `VisibilityTimeout` a 5 s | Mensajes procesados dos veces | Visibilidad menor que la duración del proceso |
| Lanzar excepción para un `productId` fijo | El lote entero se reprocesa | Falta `ReportBatchItemFailures` |
| `MemorySize: 128` con carga | Timeouts intermitentes | La CPU de Lambda es proporcional a la memoria |
| Cambiar a payload format 1.0 | `KeyError: 'routeKey'` | El contrato del evento cambió |
| `reserved-concurrent-executions 0` | `Throttles` en la métrica, cero invocaciones | Límite de concurrencia, no error de código |

Para cada uno: anota síntoma, primer comando de diagnóstico y causa. Ese cuaderno es
el material real para las preguntas de troubleshooting en entrevista.

---

## 15. 📋 Checklist de salida

- [ ] El flujo completo funciona: `curl` → DynamoDB → stream → projector → SQS → alert.
- [ ] Cada función tiene su propio execution role sin `Resource: "*"`.
- [ ] Los tres log groups están declarados en el template con retención.
- [ ] La DLQ recibió al menos un mensaje a propósito y lo reenviaste con `start-message-move-task`.
- [ ] Probaste idempotencia con la misma `Idempotency-Key` tres veces.
- [ ] Provocaste al menos cinco de los siete fallos de la sección 14 y los anotaste.
- [ ] `aws cloudformation delete-stack` deja la cuenta sin recursos de este lab (se verifica en [`L04`](l04-observabilidad-y-destruccion-verificada.md)).

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia hay entre una fuente de eventos push y una pull para Lambda?
2. ¿Qué documento autoriza que API Gateway invoque tu función?
3. ¿Qué rol usa Lambda para leer un DynamoDB Stream?
4. ¿Qué pasa con un lote de SQS o de Streams si un solo registro falla y no usas `ReportBatchItemFailures`?
5. ¿Cuál es la relación recomendada entre el visibility timeout de una cola y el timeout de la función?
6. ¿Qué hace `BisectBatchOnFunctionError`?
7. ¿Cómo se implementa idempotencia en una escritura a DynamoDB sin tabla auxiliar?
8. ¿Qué diferencia hay entre reserved concurrency y provisioned concurrency, y cuál cobra por hora?
9. ¿Cómo detienes las invocaciones de una función sin borrarla?
10. ¿Por qué el log group de una Lambda sobrevive al borrado del stack?
11. ¿Cuándo hace falta poner una Lambda dentro de una VPC y qué costo introduce?
12. ¿Qué cambia en el objeto `event` entre payload format 1.0 y 2.0 de API Gateway?
13. ¿Qué relación hay entre la memoria asignada a una Lambda y su CPU?
14. ¿Qué diferencia hay entre la trust policy y la permissions policy de un rol IAM?

---

## 🧪 Ejercicios (16)

Los obligatorios se pagan con las cuotas *always free* de la §2: **centavos en el peor
caso, y $0.00 en casi todos**. Ninguno enciende algo que cobre por hora; los que lo hacen
están en 🔥 y llevan su precio declarado.

### 🟢 Fácil — invocar y observar (1–5)

#### 🟢 Ejercicio 1 — La misma llamada, por los dos caminos

Manda un movimiento por `curl` contra el endpoint del HTTP API y después el mismo por
`aws lambda invoke`, saltándote API Gateway. Compara las dos salidas.

**Pregunta:** ¿qué campos del `event` existen solo cuando la invocación viene de API
Gateway, y qué le pasa al handler si faltan?

#### 🟢 Ejercicio 2 — Leer el `REPORT`

Invoca la función dos veces seguidas y busca en el log la línea `REPORT` de cada una.
Anota `Duration`, `Billed Duration`, `Max Memory Used` e `Init Duration`.

**Pregunta:** ¿por qué `Init Duration` aparece solo en una de las dos?

#### 🟢 Ejercicio 3 — Seguir el flujo entero en vivo

Abre `aws logs tail --follow` sobre las tres funciones a la vez, en tres terminales, y
manda un movimiento. Anota el orden en que aparecen los logs.

**Objetivo:** ver con los ojos que entre la escritura y la alerta no hay ninguna llamada
síncrona: hay un stream y una cola.

#### 🟢 Ejercicio 4 — El estado del event source mapping

Consulta `list-event-source-mappings` y localiza `State` y `LastProcessingResult`.

**Objetivo:** saber dónde mira uno primero cuando "la función no se dispara", antes de
tocar el código.

#### 🟢 Ejercicio 5 — La DLQ vacía

Consulta `ApproximateNumberOfMessages` de la cola principal y de la DLQ con el sistema en
reposo, y explica por qué el número es aproximado.

**Objetivo:** fijar que esa métrica sirve para saber si hay algo, no para llevar la
cuenta.

### 🟡 Intermedio — cambiar el comportamiento (6–10)

#### 🟡 Ejercicio 6 — Idempotencia con y sin cabecera

Manda tres peticiones con la misma `Idempotency-Key` y otras tres sin ella. Cuenta los
items resultantes en la tabla con una `Query`.

**Pregunta:** ¿cuántos movimientos hay en cada caso y cuál de los dos comportamientos
querrías en un endpoint de cobro?

#### 🟡 Ejercicio 7 — Recortar el execution role hasta que duela

Quita `dynamodb:Query` del rol de `inv-lab-api` y prueba los dos endpoints. Después
devuélvelo.

**Pregunta:** ¿qué código HTTP devuelve el API y en qué log aparece la causa real? ¿Por
qué el cliente no ve el motivo?

#### 🟡 Ejercicio 8 — El ARN que no cubre el índice

Añade un GSI a la tabla y una consulta que lo use, sin tocar el `Resource` del rol. Lee el
`AccessDenied`.

**Objetivo:** comprobar que el ARN de la tabla no cubre sus índices, y que el mensaje de
error menciona la tabla y no el índice — la trampa que la §5 anuncia.

#### 🟡 Ejercicio 9 — Ajustar el lote

Cambia `BatchSize` a 1 y `MaximumBatchingWindowInSeconds` a 0, manda diez movimientos
seguidos y cuenta las invocaciones del projector. Vuelve después a 10 y 5, y repite.

**Pregunta:** ¿cuántas invocaciones hubo en cada configuración y qué cambiaste realmente:
costo, latencia o las dos?

#### 🟡 Ejercicio 10 — Memoria y tiempo

Despliega la función de API con 128 MB y con 512 MB, y compara `Duration` y
`Billed Duration` de diez invocaciones de cada una.

**Pregunta:** ¿la de más memoria salió más cara o más barata? Justifícalo con los números,
no con la intuición.

### 🟠 Difícil — provocar el fallo y leerlo (11–14)

#### 🟠 Ejercicio 11 — La invocación que nunca llega

Borra el `AWS::Lambda::Permission` y llama al endpoint. Antes de mirar nada, **predice**
qué vas a encontrar en los logs de la función.

**Pregunta:** ¿cuántas entradas hay en el log de `inv-lab-api` para esa petición, y qué te
dice ese número sobre dónde se detuvo la llamada?

#### 🟠 Ejercicio 12 — El lote envenenado

Haz que el projector lance una excepción para un `productId` concreto, manda un lote de
cinco movimientos con uno envenenado, y observa el comportamiento **con y sin**
`ReportBatchItemFailures`.

**Objetivo:** medir el daño real de un fallo parcial: cuántas veces se reprocesan los
cuatro registros sanos en cada caso.

#### 🟠 Ejercicio 13 — Visibilidad demasiado corta

Baja el `VisibilityTimeout` de la cola por debajo del timeout de `inv-lab-alert`, fuerza
un procesamiento lento y cuenta cuántas veces se procesa el mismo mensaje.

**Pregunta:** ¿el mensaje se duplicó, o se procesó dos veces el mismo mensaje? ¿Por qué la
distinción importa para diseñar el consumidor?

#### 🟠 Ejercicio 14 — Llenar la DLQ y vaciarla bien

Provoca que tres mensajes agoten sus reintentos y caigan en la DLQ. Arregla la causa,
reenvíalos con `start-message-move-task` y verifica que se procesaron.

**Objetivo:** practicar el orden correcto —arreglar primero, reenviar después— y ver qué
pasa si lo inviertes: hazlo mal a propósito una vez y cuenta los ciclos que gasta.

### 🔴 Muy difícil — diseño y adversarial (15–16)

#### 🔴 Ejercicio 15 — El freno de emergencia

El projector está duplicando datos en producción y no sabes por qué. Deja de procesar
**sin borrar nada y sin perder los eventos pendientes**, investiga con la función
detenida, y reanuda.

**Pregunta:** ¿qué le pasa a los registros del stream mientras la función está frenada, y
cuánto tiempo tienes antes de perderlos?

#### 🔴 Ejercicio 16 — Idempotencia que no alcanza

La escritura condicional de la §10 protege el movimiento, pero el projector también
escribe, y `inv-lab-alert` publica en SNS. Diseña —y defiende por escrito— qué pasa si el
projector se reintenta después de haber escrito su proyección pero antes de confirmar el
lote, y qué habría que cambiar para que la alerta no salga dos veces.

**Objetivo:** ver que la idempotencia no es una casilla que se marca en un sitio, sino una
propiedad de cada salto con efecto externo.

### 🔥 Opcionales y ampliaciones

- **Autorizador JWT.** Monta un Cognito User Pool y protege la ruta `POST` con un JWT
  authorizer. El User Pool no cobra en la capa gratuita; cierra el bucle con
  [`05` §17](05-seguridad-iam-kms-secretos.md#17--jwt-authorizers-en-api-gateway).
- **Provisioned concurrency, una hora.** Actívala en la función de API, mide el
  `Init Duration` antes y después y **apágala en la misma sesión**. 💰 Cobra por hora
  aunque no haya tráfico: es el único elemento serverless de este lab que factura así.
- **La Lambda en VPC.** Mete `inv-lab-projector` en una VPC sin NAT y observa qué deja de
  funcionar y con qué error. 💰 No cuesta nada mientras no añadas NAT ni Interface
  endpoints; no los añadas.
- **Empaquetado real.** Migra la función de `Code.ZipFile` a un artefacto en S3 con
  dependencias propias, y anota qué gana y qué pierde el ciclo de iteración.

### 💀 Boss fight — el sistema que se cae en silencio

Recibes el sistema de este lab con **tres fallos inyectados a la vez** por otra persona
(pídeselos a alguien, o prepáralos tú y déjalos reposar un día para no recordar cuáles
son). Los síntomas son: el endpoint responde `201` con normalidad, la tabla se llena, pero
**no llega ninguna alerta a SNS y la DLQ está vacía**.

Los tres fallos se eligen de esta lista, y no sabes cuáles tocaron: permiso que falta en
un execution role, `Lambda::Permission` borrado, event source mapping deshabilitado,
reserved concurrency en 0, `VisibilityTimeout` mal, o `MaximumRecordAgeInSeconds`
demasiado bajo.

Entrega un informe corto con, para cada fallo: **el síntoma observado, el comando que lo
aisló, la causa y la corrección**, en ese orden. Prohibido abrir la consola y prohibido
cambiar más de una variable a la vez.

**Objetivo:** es el ejercicio que más se parece a una guardia real, y la respuesta a la
pregunta de entrevista *"cuéntame cómo depuraste un sistema distribuido"*. La dificultad
no está en arreglar: está en que el sistema no da error en ninguna parte.

**Criterio de terminado:** el flujo completo vuelve a funcionar de punta a punta y puedes
explicar, sin mirar, por qué cada uno de los tres fallos producía silencio en vez de
error.

---

## 🏁 La señal de que quedó bien

> Mando la misma petición tres veces con la misma `Idempotency-Key` y en la tabla hay un
> solo movimiento. Y cuando algo no se dispara, sé en menos de un minuto si el problema
> es la resource-based policy, el execution role o el event source mapping — porque sé
> cuál de los tres interviene en cada caso.

---

## 📚 Referencias oficiales

- AWS Lambda Developer Guide: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- Execution role de Lambda: https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html
- Resource-based policies de Lambda: https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html
- Event source mappings: https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html
- Lambda con DynamoDB Streams: https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html
- Lambda con SQS: https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html
- Fallos parciales de lote: https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-errorhandling.html
- Concurrencia en Lambda: https://docs.aws.amazon.com/lambda/latest/dg/lambda-concurrency.html
- Configuración de memoria y CPU: https://docs.aws.amazon.com/lambda/latest/dg/configuration-memory.html
- Lambda en una VPC: https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html
- API Gateway HTTP API: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html
- Formato de payload de integración Lambda: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html
- SQS visibility timeout: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html
- SQS dead-letter queues y redrive: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html
- Escrituras condicionales en DynamoDB: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html#WorkingWithItems.ConditionalUpdate
- DynamoDB Streams: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html
- `AWS::Lambda::Function` (propiedad `Code.ZipFile`): https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-lambda-function-code.html
- AWS Free Tier: https://aws.amazon.com/free/
