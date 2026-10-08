# A02 — Catálogo de costos, trampas y recursos huérfanos

> **Objetivo:** responder con certeza a "¿qué me puede cobrar y cómo lo apago?", y
> reconocer los recursos que sobreviven a un `delete-stack` aparentemente exitoso.
> **Tipo:** apéndice de referencia. Sin prerrequisitos ni orden de lectura.
> **Se conecta con:** [`L00`](l00-idea-lab-practico.md) (por qué el lab excluye lo que
> cobra por hora) y [`L04`](l04-observabilidad-y-destruccion-verificada.md) (el barrido verificado).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Las cuatro categorías de cobro](#1--las-cuatro-categorías-de-cobro) · [Cuotas always free relevantes](#2--cuotas-always-free-relevantes) · [Lo que cobra por hora](#3--lo-que-cobra-por-hora) · [Lo que cobra por almacenar](#4--lo-que-cobra-por-almacenar) · [Trampas concretas, con su antídoto](#5--trampas-concretas-con-su-antídoto) · [Estimar antes de desplegar](#6--estimar-antes-de-desplegar) · [Si aparece un cargo inesperado](#7--si-aparece-un-cargo-inesperado) · [Reglas de higiene del lab](#8--reglas-de-higiene-del-lab) · [Preguntas rápidas](#-preguntas-rápidas) · [Ejercicios](#-ejercicios-10) · [Referencias oficiales](#-referencias-oficiales)

Apéndice de referencia económica para los labs [`L01`](l01-preparacion-cli-y-blindaje-de-costos.md)
a [`L04`](l04-observabilidad-y-destruccion-verificada.md) y para cualquier cuenta
personal de práctica. Responde a una sola pregunta: **¿qué me puede cobrar y cómo lo
apago con certeza?**

---

## 1. 🧭 Las cuatro categorías de cobro

Confundirlas es el origen de casi toda factura sorpresa.

```text
1. POR HORA ENCENDIDA     cobra exista o no tráfico    ← el peligroso
2. POR USO REAL           cobra por invocación/request ← en un lab, centavos
3. POR ALMACENAMIENTO     sobrevive al apagado         ← el invisible
4. POR TRANSFERENCIA      salida y cruce de AZ         ← el que nadie estima
```

> Regla de arquitectura: apagar una instancia detiene la categoría 1, no la 3. El
> volumen EBS sigue facturando mientras exista.

---

## 2. 💰 Cuotas always free relevantes

Se renuevan cada mes, no vencen con la antigüedad de la cuenta y no acumulan.

| Servicio | Cuota mensual |
|---|---|
| Lambda | 1 M invocaciones + 400.000 GB-segundo |
| DynamoDB | 25 GB de almacenamiento |
| SQS | 1 M solicitudes |
| SNS | 1 M publicaciones |
| CloudWatch | 10 métricas custom, 10 alarmas, 5 GB de ingesta de logs |
| X-Ray | 100.000 trazas registradas |
| CloudFormation | Sin cargo por tipos de recurso nativos de AWS |
| CloudTrail | Una copia de eventos de gestión |
| SSM Parameter Store | Parámetros estándar sin cargo |
| EventBridge | Eventos publicados por servicios AWS |

⚠️ La cuota de la cuenta es compartida: si ya tienes 9 alarmas de otro proyecto, las
del lab empiezan a costar $0.10 al mes cada una.

---

## 3. 💰 Lo que cobra por hora

| Recurso | Precio | Al mes si se olvida |
|---|---|---|
| EKS control plane (standard support) | $0.10/h por cluster | ~$73 |
| EKS control plane (extended support) | $0.60/h por cluster | ~$438 |
| NAT Gateway | $0.045/h + $0.045/GB procesado | ~$33 + tráfico |
| Amazon MQ ActiveMQ `mq.t3.micro` | $0.036/h | ~$26 |
| Application Load Balancer | $0.0225/h + LCU | ~$16 + LCU |
| Kinesis Data Stream on-demand | $0.04/h por stream | ~$29 |
| Kinesis Data Stream provisionado | $0.015/h por shard | ~$11 por shard |
| RDS PostgreSQL `db.t4g.micro` single-AZ | ~$0.016/h | ~$12 |
| EC2 `t3.medium` on-demand | ~$0.0416/h | ~$30 |
| Fargate | $0.04048/vCPU-h + $0.004445/GB-h | ~$9 por 0,25 vCPU + 0,5 GB |
| Dirección IPv4 pública | $0.005/h por dirección | ~$3,60 por dirección |
| VPC Interface endpoint | ~$0.01/h por AZ + datos | ~$7,30 por AZ |
| Lambda provisioned concurrency | por GB-hora aprovisionado | según configuración |
| ElastiCache `cache.t4g.micro` | ~$0.016/h | ~$12 |

> Regla: en un lab, un stream de Kinesis on-demand ($0.04/h) cuesta casi tres veces
> más que un shard provisionado ($0.015/h). On-demand ahorra cuando el tráfico es
> alto y variable, no cuando es cero.

---

## 4. 💰 Lo que cobra por almacenar

Estos cargos sobreviven al apagado y, en varios casos, al `delete-stack`.

| Recurso | Precio orientativo | Cómo se controla |
|---|---|---|
| EBS gp3 | $0.08/GB-mes | Borrar volúmenes en estado `available` |
| Snapshots EBS y RDS | por GB-mes | `DeletionPolicy: Delete` explícito; borrar snapshots manuales |
| S3 estándar | por GB-mes | Lifecycle rule de expiración |
| Multipart uploads incompletos en S3 | ocupan y facturan sin aparecer en `ls` | Regla `AbortIncompleteMultipartUpload` |
| Versiones antiguas en S3 con versionado | facturan como objetos | Lifecycle de versiones no actuales |
| Imágenes en ECR | $0.10/GB-mes | Lifecycle policy del repositorio |
| CloudWatch Logs | por GB ingerido y por GB almacenado | `RetentionInDays` en todos los log groups |
| DynamoDB point-in-time recovery | por GB del tamaño de la tabla | Desactivado salvo que se practique restore |
| Secrets Manager | $0.40 por secreto y mes | Usar SSM Parameter Store estándar en labs |
| Route 53 hosted zone | $0.50 por zona y mes | Borrar la zona si no se usa |

---

## 5. ⚖ Trampas concretas, con su antídoto

**El log group que Lambda crea sola.** Nace con retención "Never expire" y no
pertenece a ningún stack. Antídoto: declarar `AWS::Logs::LogGroup` en el template con
el nombre exacto `/aws/lambda/<función>` y `RetentionInDays`, como hace
[`L03` §12](l03-backend-serverless-lambda-api-y-eventos.md#12--los-log-groups-se-declaran-no-se-heredan).

**El `DeletionPolicy` implícito de RDS.** El valor por defecto es `Delete` para casi
todo, pero es `Snapshot` para `AWS::RDS::DBCluster` y para `AWS::RDS::DBInstance` sin
`DBClusterIdentifier`. Borras el stack, crees que terminaste, y el snapshot factura.
Antídoto: `DeletionPolicy: Delete` explícito en labs, y revisar
`describe-db-snapshots --snapshot-type manual` tras el teardown.

**El bucket que impide borrar el stack.** CloudFormation no vacía buckets: el borrado
falla con `DELETE_FAILED`. Antídoto: lifecycle de expiración corta, `aws s3 rm
--recursive` antes del teardown, y nunca resolverlo con `--retain-resources` salvo que
lo anotes. El caso completo, provocado a propósito, está en
[`L02` §10](l02-cloudformation-desde-la-cli.md#10--destruir-incluido-el-caso-que-falla).

**Las ENIs de Lambda en VPC.** Se liberan con retraso y bloquean el borrado de
subnets y security groups. Antídoto: no meter la función en la VPC salvo necesidad
real, y esperar antes de reintentar el borrado.

**Los Interface endpoints multiplicados.** Cuestan por endpoint **y por AZ**. Tres
endpoints en dos AZ son ~$44 al mes. Antídoto: los Gateway endpoints de S3 y DynamoDB
no cuestan nada; usa Interface solo para lo que no tiene Gateway.

**El NAT Gateway "por si acaso".** En un lab casi siempre se puede evitar: Gateway
endpoints para S3 y DynamoDB, o workloads en subnet pública con Security Group
estricto. Antídoto: no crearlo hasta que un requisito lo exija. El razonamiento completo
de por qué el laboratorio lo evita en vez de enseñarlo está en
[`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones).

**Las direcciones IPv4 públicas.** Se cobran todas desde 2024, asociadas o no. Un ALB
usa al menos dos. Antídoto: contarlas al estimar, y liberar las Elastic IP sueltas.

**Provisioned concurrency de Lambda.** Es serverless y aun así cobra por hora.
Antídoto: no activarla en labs; si se prueba, se apaga en la misma sesión.

**Servicios de seguridad activados sin querer.** GuardDuty, AWS Config, Security Hub,
Inspector y Macie facturan por volumen analizado y suelen habilitarse "para probar".
Antídoto: revisarlos en el desglose por servicio de Cost Explorer si aparece un cargo
inexplicable.

**El segundo trail de CloudTrail.** La primera copia de eventos de gestión no tiene
cargo; a partir de ahí sí, y los eventos de datos siempre cuestan. Antídoto: un solo
trail, sin eventos de datos, en una cuenta de práctica.

---

## 6. 💰 Estimar antes de desplegar

El ejercicio que convierte el costo en intuición: **adivina la factura antes de
mirarla**.

1. Antes de desplegar, escribe tu estimación por recurso y hora.
2. Enciende, trabaja, destruye.
3. A las 48 horas, compara contra Cost Explorer agrupado por servicio.
4. Anota la diferencia y su causa.

La calculadora oficial sirve para la estimación previa; el desglose por
`SERVICE` y por `USAGE_TYPE` de Cost Explorer sirve para explicar la diferencia:

```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -v-7d +%F),End=$(date -u +%F) \
  --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=USAGE_TYPE \
  --query 'ResultsByTime[-1].Groups[?Metrics.UnblendedCost.Amount!=`0`].{Uso:Keys[0],USD:Metrics.UnblendedCost.Amount}' \
  --output table
```

`USAGE_TYPE` es la dimensión que responde "¿qué línea exacta me está cobrando?":
distingue `NatGateway-Hours` de `NatGateway-Bytes`, o `BoxUsage` de `EBS:VolumeUsage`.

---

## 7. 🩺 Si aparece un cargo inesperado

```text
1. Cost Explorer, agrupado por SERVICE     → qué servicio
2. Cost Explorer, agrupado por USAGE_TYPE  → qué línea de ese servicio
3. Cost Explorer, agrupado por REGION      → dónde está el recurso
4. Barrido de esa región y ese servicio    → cuál es el recurso
5. Borrarlo y confirmar a las 48 horas
```

El paso 3 es el que resuelve el caso clásico: un recurso creado por error en una
región que nunca miras. Por eso el barrido de
[`L04` §10](l04-observabilidad-y-destruccion-verificada.md#10--barrido-por-tag) recorre
todas las regiones.

---

## 8. 🧭 Reglas de higiene del lab

- Todo recurso nace de un template; nada se crea a mano en la consola.
- Todo lleva el tag `Project`, y la clave está activada como cost allocation tag.
- Todo log group tiene retención.
- Todo bucket tiene lifecycle de expiración y de aborto de multipart.
- Nada que cobre por hora sobrevive al final de la sesión.
- El teardown se verifica enumerando recursos el mismo día y revisando la factura a
  las 48 horas.
- El budget de gasto cero es la red de seguridad para el día que te olvides de todo
  lo anterior.

---

## 🧠 Preguntas rápidas

1. ¿Cuáles son las cuatro categorías de cobro y cuál sobrevive al apagado?
2. ¿Por qué apagar una instancia EC2 no detiene todo su costo?
3. ¿Cuál es el `DeletionPolicy` por defecto y en qué recursos cambia?
4. ¿Por qué un log group de Lambda sobrevive al borrado del stack?
5. ¿Qué diferencia de costo hay entre un Gateway endpoint y un Interface endpoint?
6. ¿Cuánto cuesta una dirección IPv4 pública y desde cuándo se cobra siempre?
7. ¿Por qué un stream de Kinesis on-demand puede salir más caro que uno provisionado en un lab?
8. ¿Qué son los multipart uploads incompletos y por qué no aparecen en un listado normal?
9. ¿Por qué se prefiere SSM Parameter Store a Secrets Manager en una cuenta de práctica?
10. ¿Qué dimensión de Cost Explorer responde "qué línea exacta me está cobrando"?
11. ¿Qué pasos sigues para localizar un cargo inesperado?
12. ¿Cuál es el elemento serverless que, pese a serlo, cobra por hora?

---

## 🧪 Ejercicios (10)

Todos cuestan **$0.00**: son de auditoría y de lectura de la factura, no de despliegue.
Se pueden hacer sobre una cuenta vacía, y de hecho es cuando más enseñan — porque una
cuenta que crees vacía casi nunca lo está.

### 🟢 Fácil — leer la factura (1–3)

#### 🟢 Ejercicio 1 — Las cuatro categorías, en tu cuenta

Agrupa el gasto del último mes por `USAGE_TYPE` y clasifica cada línea en una de las
cuatro categorías de la §1: por hora, por uso, por almacenamiento o por transferencia.

**Pregunta:** ¿alguna línea sobrevive a apagarlo todo? Esa es la categoría 3, y es la que
nadie recuerda.

#### 🟢 Ejercicio 2 — Cuántas alarmas te quedan gratis

Cuenta las alarmas de CloudWatch de la cuenta en todas las regiones y réstalas de la cuota
de diez.

**Objetivo:** comprobar que la cuota *always free* es de la cuenta y no del proyecto, que
es lo que convierte "diez alarmas gratis" en "cero" sin que nadie lo anuncie.

#### 🟢 Ejercicio 3 — El inventario de lo que cobra por hora

Enumera, en tu cuenta y en todas las regiones habilitadas, si existe alguno de los
recursos de la tabla de la §3: NAT Gateways, balanceadores, clusters de EKS, instancias
RDS, Elastic IP sin asociar.

**Objetivo:** saber en cinco minutos si tu cuenta está costando dinero ahora mismo, que es
la pregunta que abre este apéndice.

### 🟡 Intermedio — cazar lo invisible (4–7)

#### 🟡 Ejercicio 4 — Multipart uploads fantasma

Localiza los multipart uploads incompletos de tus buckets con
`s3api list-multipart-uploads` y, si hay alguno, escribe la regla de ciclo de vida
`AbortIncompleteMultipartUpload` que los previene.

**Pregunta:** ¿por qué esas partes no aparecen en un `aws s3 ls` normal si están ocupando
almacenamiento y facturando?

#### 🟡 Ejercicio 5 — Versiones que no ves

Sobre un bucket versionado, compara el número de objetos que devuelve `list-objects-v2`
con el de versiones que devuelve `list-object-versions`.

**Objetivo:** entender de dónde sale el `DELETE_FAILED` de
[`L02` §10](l02-cloudformation-desde-la-cli.md#10--destruir-incluido-el-caso-que-falla)
cuando el bucket "está vacío".

#### 🟡 Ejercicio 6 — Volúmenes y direcciones sueltas

Busca volúmenes EBS en estado `available` y Elastic IP sin asociar en todas las regiones.
Calcula cuánto costarían al mes si los dejaras.

**Pregunta:** ¿cuál de los dos cuesta más al mes por unidad, y cuál es más fácil de
olvidar?

#### 🟡 Ejercicio 7 — Estimar antes de mirar

Elige un despliegue hipotético —un ALB, dos tasks de Fargate y una `db.t4g.micro`— y
escribe su costo mensual estimado **antes** de abrir la calculadora. Después compáralo con
la calculadora oficial.

**Objetivo:** calibrar la intuición con un caso completo, incluyendo las direcciones IPv4
públicas que casi nadie cuenta.

### 🟠 Difícil — el cargo que no esperabas (8–9)

#### 🟠 Ejercicio 8 — Seguir el rastro hasta el recurso

Toma la línea de costo más alta de tu cuenta del último mes y recórrela con el
procedimiento de la §7: `SERVICE` → `USAGE_TYPE` → `REGION` → barrido → recurso concreto.
Escribe las cuatro respuestas.

**Objetivo:** practicar el procedimiento con un cargo real, aunque sea pequeño, para no
estrenarlo el día que el cargo sea grande.

#### 🟠 Ejercicio 9 — Los servicios que se encienden solos

Comprueba si GuardDuty, AWS Config, Security Hub, Inspector o Macie están activos en
alguna región de tu cuenta, y cuánto han costado en los últimos treinta días.

**Pregunta:** si alguno está activo y no recuerdas haberlo encendido, ¿cómo averiguas
quién lo hizo y cuándo?

### 🔴 Muy difícil — la auditoría completa (10)

#### 🔴 Ejercicio 10 — La cuenta que creías vacía

Escribe un informe de una página sobre tu propia cuenta que responda a tres preguntas:
qué está encendido y cobra por hora, qué está almacenado y cobra por mes, y qué recurso
lleva más tiempo sin que nadie lo toque. Cada afirmación tiene que venir con el comando
que la sostiene.

**Objetivo:** el mismo trabajo que harías en tu primera semana en un equipo nuevo con una
cuenta heredada, y una respuesta excelente a *"¿cómo reducirías el gasto de esta cuenta?"*
en una entrevista.

### 🔥 Opcionales y ampliaciones

- **Presupuesto por servicio.** Crea un budget filtrado a un solo servicio —el que más te
  preocupe— en vez de a la cuenta entera. Sin cargo.
- **Cost Explorer contra la factura real.** A fin de mes, compara el desglose de Cost
  Explorer con la sección Bills de facturación y localiza las diferencias de redondeo y de
  impuestos.
- **Cronometrar el olvido.** Enciende un NAT Gateway, mídelo una hora exacta y apágalo.
  💰 Cuesta unos $0.045 y es la forma más barata de que el número deje de ser abstracto.

### 💀 Boss fight — el informe de reducción de costo

Recibes el encargo que abre muchas entrevistas de arquitectura: *"esta cuenta cuesta más
de lo que debería; dime qué recortarías"*. Usa tu propia cuenta, o los números de una
arquitectura de ejemplo si la tuya está vacía: un ALB, dos tasks de Fargate, una RDS
single-AZ, un NAT Gateway, tres Interface endpoints y 200 GB en S3 Standard.

Entrega un informe con tres secciones: **qué se puede quitar sin cambiar la arquitectura**
(recursos huérfanos, retenciones, endpoints duplicados), **qué se puede cambiar con un
trade-off explícito** (clase de almacenamiento, modo de capacidad, Savings Plans, Gateway
en vez de Interface), y **qué no tocarías y por qué**. Cada punto con su ahorro estimado
al mes y su riesgo.

**Objetivo:** demostrar que sabes que optimizar costo no es apagar cosas, sino conocer el
precio de cada decisión de arquitectura — que es exactamente lo que el pilar Cost
Optimization de [`11`](11-resiliencia-y-well-architected.md) pregunta.

**Criterio de terminado:** la tercera sección existe y tiene contenido. Un informe que
solo recorta y no defiende nada está incompleto.

---

## 📚 Referencias oficiales

- AWS Pricing Calculator: https://calculator.aws/
- AWS Free Tier: https://aws.amazon.com/free/
- EC2 pricing: https://aws.amazon.com/ec2/pricing/on-demand/
- EBS pricing: https://aws.amazon.com/ebs/pricing/
- VPC pricing (NAT Gateway y endpoints): https://aws.amazon.com/vpc/pricing/
- Direcciones IPv4 públicas y Elastic IP: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
- Elastic Load Balancing pricing: https://aws.amazon.com/elasticloadbalancing/pricing/
- EKS pricing: https://aws.amazon.com/eks/pricing/
- Fargate pricing: https://aws.amazon.com/fargate/pricing/
- Lambda pricing: https://aws.amazon.com/lambda/pricing/
- RDS for PostgreSQL pricing: https://aws.amazon.com/rds/postgresql/pricing/
- DynamoDB pricing: https://aws.amazon.com/dynamodb/pricing/
- S3 pricing: https://aws.amazon.com/s3/pricing/
- Kinesis Data Streams pricing: https://aws.amazon.com/kinesis/data-streams/pricing/
- Amazon MQ pricing: https://aws.amazon.com/amazon-mq/pricing/
- CloudWatch pricing: https://aws.amazon.com/cloudwatch/pricing/
- Secrets Manager pricing: https://aws.amazon.com/secrets-manager/pricing/
- Route 53 pricing: https://aws.amazon.com/route53/pricing/
- ECR pricing: https://aws.amazon.com/ecr/pricing/
- Ciclo de vida de objetos en S3: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html
- Cost Explorer: https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html
- Dimensiones y filtros de Cost Explorer: https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html
