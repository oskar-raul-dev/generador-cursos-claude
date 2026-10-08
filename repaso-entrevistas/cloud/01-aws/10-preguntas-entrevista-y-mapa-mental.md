# 10 — AWS Core: preguntas de entrevista y mapa mental

> **Objetivo:** simular una entrevista completa. Sesenta preguntas `P#` agrupadas por
> bloque, seis escenarios de arquitectura resueltos y una autoevaluación final.
> **Se asume leído:** los documentos [`01`](01-infraestructura-global-y-redes.md) a
> [`09`](09-cloudformation-iac.md), [`11`](11-resiliencia-y-well-architected.md) y
> [`12`](12-orquestacion-y-cicd.md).
> **Cómo se usa:** las `P#` no llevan respuesta aquí a propósito. Contéstalas en voz
> alta, escribe tu versión y solo después ábrelas en
> [`13`](13-respuestas.md#10--preguntas-de-entrevista). Los escenarios sí traen su
> solución desarrollada: son ejemplos resueltos, no autochequeo.
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Asociaciones obligatorias](#1-las-asociaciones-obligatorias) · [I Networking](#parte-i--networking) · [II Compute/containers](#parte-ii--computecontainers) · [III Storage/database](#parte-iii--storagedatabase) · [IV DynamoDB](#parte-iv--dynamodb) · [V Messaging](#parte-v--messaging) · [VI Security](#parte-vi--security) · [VII Route 53](#parte-vii--route-53) · [VIII Edge/TLS](#parte-viii--edgetls) · [IX Observability](#parte-ix--observability) · [X CloudFormation](#parte-x--cloudformation) · [XI Resiliencia y orquestación](#parte-xi--resiliencia-well-architected-y-orquestación) · [Escenarios de arquitectura](#escenarios-de-arquitectura) · [Autoevaluación final](#autoevaluación-final)

---

## 1. Las asociaciones obligatorias

```text
Region                 → geografía
Availability Zone      → aislamiento de fallos
VPC                    → red virtual regional
Subnet                 → segmento de red zonal
Route Table            → destination → target
Security Group         → firewall stateful workload
NACL                   → firewall stateless subnet
IGW                    → VPC ↔ Internet
NAT                    → private workload → Internet
EC2                    → VM
AMI                    → image/template EC2
EBS                    → block storage
EFS                    → shared file storage
S3                     → object storage
ECR                    → container registry
ECS                    → container orchestration AWS
Fargate                → managed/serverless container compute
EKS                    → managed Kubernetes
Lambda                 → functions
API Gateway            → managed API front door
CloudFront             → CDN/edge cache
ACM                    → managed TLS certificates
ALB                    → L7 HTTP/HTTPS load balancing
NLB                    → L4 TCP/UDP/TLS load balancing
RDS                    → managed relational DB
Aurora                 → AWS relational engine compatible MySQL/Postgres
DynamoDB               → managed key-value/document NoSQL
SQS                    → queue
SNS                    → pub/sub topic
EventBridge            → event bus/routing
IAM                    → identity/authorization
KMS                    → keys/encryption
Secrets Manager        → secrets
Route 53               → DNS/domains/health checks
CloudWatch             → metrics/logs/alarms
CloudTrail             → audit/API activity
AWS Config             → resource configuration/compliance
CloudFormation         → AWS-native declarative IaC
Well-Architected Framework → 6 pilares para evaluar una arquitectura
Cognito                → identidad de usuario final (User Pool/Identity Pool)
Kinesis                → streaming ordenado, múltiples lectores independientes
Step Functions         → orquestación de workflows Lambda/ECS
```

---

# Parte I — Networking

Se repasa con [`01`](01-infraestructura-global-y-redes.md).

## P1. ¿Region vs AZ?

## P2. ¿VPC es zonal?

## P3. ¿Qué hace pública a una subnet?

## P4. ¿Security Group vs NACL?

## P5. ¿NAT permite Internet → EC2 privada?

## P6. ¿VPC Peering es transitivo?

## P7. ¿Cuándo Transit Gateway?

## P8. ¿Por qué VPC Endpoint?

---

# Parte II — Compute/containers

Se repasa con [`02`](02-computo-contenedores-y-balanceo.md).

## P9. ¿EC2 vs Docker?

## P10. ¿ECS vs Fargate?

## P11. ¿ECS vs EKS?

## P12. ¿ALB vs NLB?

## P13. ¿Task vs Service?

## P14. ¿API Gateway vs ALB?

## P15. ¿Cómo modernizar monolito Spring Boot en EC2?

---

# Parte III — Storage/database

Se repasa con [`03`](03-almacenamiento-y-bases-sql.md).

## P16. ¿S3 vs EBS vs EFS?

## P17. ¿Multi-AZ vs read replica?

## P18. ¿Aurora vs RDS PostgreSQL?

## P19. ¿Replica = backup?

---

# Parte IV — DynamoDB

Se repasa con [`04`](04-dynamodb-nosql.md).

## P20. ¿Partition key vs sort key?

## P21. ¿Query vs Scan?

## P22. ¿GSI vs LSI?

## P23. ¿GSI tiene strongly consistent reads?

## P24. ¿DynamoDB tiene transacciones?

## P25. ¿TTL borra exactamente al segundo?

## P26. ¿Por qué access patterns primero?

---

# Parte V — Messaging

Se repasa con [`07`](07-mensajeria-eventos-integracion.md).

## P27. ¿SQS vs SNS?

## P28. ¿Por qué SNS + múltiples SQS?

## P29. ¿Por qué consumer idempotente?

## P30. ¿Qué es visibility timeout?

## P31. ¿Qué es una DLQ?

## P32. ¿EventBridge vs SNS?

---

# Parte VI — Security

Se repasa con [`05`](05-seguridad-iam-kms-secretos.md).

## P33. ¿IAM User vs Role?

## P34. ¿Trust policy vs permission policy de un Role?

## P35. ¿Cuál es la regla de policy evaluation?

## P36. ¿IAM Role o access key en Docker image?

## P37. ¿KMS vs Secrets Manager?

## P38. ¿IAM vs Security Group?

---

# Parte VII — Route 53

Se repasa con [`06`](06-route53-dns-conectividad.md).

## P39. ¿CNAME vs Alias?

## P40. ¿Weighted vs Latency?

## P41. ¿Qué patrón implementa Failover?

## P42. ¿Route 53 vs ALB?

---

# Parte VIII — Edge/TLS

Se repasa con [`06` §18–§19](06-route53-dns-conectividad.md#18--cloudfront--cdn).

## P43. ¿CloudFront vs Route 53 vs ALB?

## P44. ¿ACM vs KMS?

---

# Parte IX — Observability

Se repasa con [`08`](08-observabilidad-auditoria-gobierno.md).

## P45. ¿CloudWatch vs CloudTrail?

## P46. ¿CloudTrail vs Config?

## P47. ¿Flow Logs vs Reachability Analyzer?

---

# Parte X — CloudFormation

Se repasa con [`09`](09-cloudformation-iac.md).

## P48. ¿Template vs Stack?

## P49. ¿Cuál es la sección obligatoria de un template?

## P50. ¿Ref vs GetAtt?

## P51. ¿Qué es un Change Set?

## P52. ¿Qué es drift?

## P53. ¿Por qué replacement importa?

---

# Parte XI — Resiliencia, Well-Architected y orquestación

Se repasa con [`11`](11-resiliencia-y-well-architected.md) y [`12`](12-orquestacion-y-cicd.md).

## P54. ¿Cuáles son los 6 pilares del Well-Architected Framework?

## P55. ¿RTO vs RPO?

## P56. ¿Pilot Light vs Warm Standby?

## P57. ¿Qué resuelve un circuit breaker?

## P58. ¿Cómo evitas un Lambda gigante con lógica de orquestación adentro?

## P59. ¿Cognito User Pool vs Identity Pool?

## P60. ¿Kinesis vs SQS?

---

# Escenarios de arquitectura

## Escenario 1 — API Java altamente disponible

```text
Internet
   │
Route 53
   │
ALB public subnets
   │
 ┌─┴──────────┐
 │            │
ECS          ECS
AZ-a         AZ-b
 │            │
 └─────┬──────┘
       ▼
  RDS Multi-AZ
```

Seguridad:

```text
Internet :443 → SG-ALB
SG-ALB :8080 → SG-App
SG-App :5432 → SG-DB
```

---

## Escenario 2 — Procesar 5000 órdenes/s sin bloquear API

```text
Client
  │
  ▼
Order API
  │ persist order
  └──────────────► SQS
                    │
              ┌─────┼─────┐
              ▼     ▼     ▼
            Worker Worker Worker
```

Respuesta posible:

```text
202 Accepted
```

Diseña idempotencia, DLQ, retries y autoscaling por backlog/age.

---

## Escenario 3 — Private app necesita S3

Peor si no necesitas Internet general:

```text
Private App → NAT → public S3 endpoint
```

Alternativa:

```text
Private App → S3 Gateway VPC Endpoint → S3
```

---

## Escenario 4 — Buscar DynamoDB por email

Tabla primary key:

```text
PK = USER#id
```

Nuevo access pattern:

```text
get user by email
```

Solución típica:

```text
GSI1PK = EMAIL#value
```

No hacer `Scan` de toda la tabla en cada login.

---

## Escenario 5 — CloudFormation cambio peligroso

Cambio de propiedad produce:

```text
RDS DBInstance → Replacement: True
```

Respuesta correcta:

1. no ejecutar ciegamente;
2. revisar Change Set;
3. evaluar data migration/snapshot/DeletionPolicy/UpdateReplacePolicy;
4. planear downtime/cutover;
5. ejecutar con rollback/observabilidad preparados.

---

## Escenario 6 — Elegir estrategia de Disaster Recovery

El negocio pide: "si perdemos la region primaria, no podemos estar más de 5 minutos caídos y no podemos perder más de 1 minuto de datos".

```text
RTO objetivo ≈ 5 minutos
RPO objetivo ≈ 1 minuto
```

Con esos números, Backup & Restore y Pilot Light quedan descartados (RTO en horas/decenas de minutos). La decisión queda entre Warm Standby y Multi-site Active/Active:

```text
Warm Standby              → RTO de minutos, requiere escalar capacidad al fallar
Multi-site Active/Active  → RTO de segundos, mayor costo y complejidad de datos multi-region
```

Con RTO de 5 minutos, Warm Standby ya cumple el objetivo sin pagar el costo de Active/Active — elegir Active/Active aquí sería sobre-ingeniería frente al RTO/RPO real pedido.

---

## Autoevaluación final

Si puedes explicar sin mirar:

1. Region/AZ/VPC/subnet.
2. SG vs NACL.
3. IGW vs NAT.
4. ALB vs NLB.
5. EC2 vs ECS/Fargate vs Lambda.
6. S3 vs EBS vs EFS.
7. Multi-AZ vs read replica.
8. DynamoDB PK/SK/GSI/Query/Scan.
9. SQS/SNS/EventBridge.
10. IAM Role/policy/least privilege.
11. KMS vs Secrets Manager.
12. Route 53 routing policies.
13. CloudWatch vs CloudTrail vs Config.
14. CloudFormation Template/Stack/Change Set/Drift.
15. Well-Architected Framework y sus 6 pilares.
16. RTO/RPO y las 4 estrategias de Disaster Recovery.
17. Circuit breaker, retry+jitter y bulkhead.
18. Step Functions vs Lambda gigante con orquestación interna.
19. Cognito User Pool vs Identity Pool, y Kinesis vs SQS.

…entonces ya tienes recuperado un núcleo sólido de AWS para una entrevista backend
Senior/Architect.

Y si alguna no sale de memoria, la respuesta explicada está en
[`13`](13-respuestas.md#10--preguntas-de-entrevista) — pero primero contéstala en voz
alta, que es como se va a preguntar.
