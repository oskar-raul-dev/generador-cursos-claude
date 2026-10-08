# AWS Core Refresh — repaso para entrevistas y laboratorio práctico

> **Objetivo:** refrescar AWS para entrevistas técnicas y conversaciones de arquitectura
> backend/Senior/Architect, y practicar en una cuenta real solo aquello que **únicamente**
> se puede aprender en la nube.
> **Audiencia:** gente que ya programa y ya entiende sistemas distribuidos. No se explica
> qué es una base de datos ni qué es un contenedor.
> **Vigencia:** 6 de septiembre de 2026. Los 264 enlaces de documentación oficial del
> curso se verificaron uno a uno en esa fecha, y los enlaces internos entre documentos
> resuelven todos, incluidas sus anclas.

Esta guía no intenta cubrir el catálogo de AWS. Cubre el vocabulario, los mecanismos y
los matices que separan a quien entiende el modelo de quien memorizó la lista de
servicios. Cada documento cierra con preguntas sin respuesta a la vista; todas las
respuestas, explicadas, viven en un único sitio: [`13`](13-respuestas.md).

**El curso tiene dos mitades independientes.** Puedes leer solo la teórica, o hacer solo
los labs, pero rinden mucho más juntas.

---

## Parte 1 — Documentos teóricos

Se leen en orden la primera vez, y después se consultan sueltos: cada uno abre con un
índice de salto rápido.

| # | Documento | Qué te deja poder explicar |
|---|---|---|
| 01 | **[Infraestructura global y redes](01-infraestructura-global-y-redes.md)** | Regions, AZ, VPC, CIDR, subnets, route tables, IGW, NAT, Security Groups, NACL, endpoints, peering y Transit Gateway |
| 02 | **[Cómputo, contenedores y balanceo](02-computo-contenedores-y-balanceo.md)** | EC2, AMI, EBS, Auto Scaling, ECR, ECS, Fargate, EKS, Lambda en profundidad, ALB y NLB |
| 03 | **[Almacenamiento y bases SQL](03-almacenamiento-y-bases-sql.md)** | S3, EBS, EFS, RDS, Aurora, Multi-AZ, read replicas, AWS Backup y ElastiCache |
| 04 | **[DynamoDB y NoSQL](04-dynamodb-nosql.md)** | Partition key, sort key, access patterns, Query vs Scan, GSI/LSI, consistencia, capacidad, TTL, Streams y transacciones |
| 05 | **[Seguridad, IAM, cifrado y secretos](05-seguridad-iam-kms-secretos.md)** | IAM, STS, policy evaluation, least privilege, Cognito, JWT authorizers, KMS, Secrets Manager y estrategia multi-cuenta |
| 06 | **[Route 53, DNS y conectividad](06-route53-dns-conectividad.md)** | Hosted zones, registros, Alias vs CNAME, routing policies, health checks, CloudFront, ACM, VPN, Direct Connect y PrivateLink |
| 07 | **[Mensajería, eventos e integración](07-mensajeria-eventos-integracion.md)** | SQS, SNS, EventBridge, Kinesis, DLQ, idempotencia, fan-out y patrones asíncronos |
| 08 | **[Observabilidad, auditoría y gobierno](08-observabilidad-auditoria-gobierno.md)** | CloudWatch, CloudTrail, AWS Config, Flow Logs, X-Ray, Reachability Analyzer y tags |
| 09 | **[CloudFormation e Infrastructure as Code](09-cloudformation-iac.md)** | Templates, stacks, funciones intrínsecas, Change Sets, `DeletionPolicy`, drift y rollback |
| 11 | **[Resiliencia y Well-Architected](11-resiliencia-y-well-architected.md)** | Los 6 pilares, trade-offs, circuit breaker, retry con backoff+jitter, bulkhead, timeout budgets y las 4 estrategias de DR con RTO/RPO |
| 12 | **[Orquestación y CI/CD](12-orquestacion-y-cicd.md)** | Step Functions, State Machines, CodePipeline, CodeBuild, CodeDeploy y estrategias de despliegue |
| 10 | **[Simulación de entrevista](10-preguntas-entrevista-y-mapa-mental.md)** | 60 preguntas `P#` y 6 escenarios de arquitectura resueltos. Se hace al final, no al principio |
| 13 | **[Respuestas](13-respuestas.md)** | Solucionario centralizado de **todo** el curso: `01`–`09`, `11`–`12`, las `P#` de `10` y la serie práctica `L00`–`L04`/`A01`–`A02` |

> El orden numérico y el orden de lectura no coinciden a propósito: `10` es la simulación
> final y `13` es la referencia. Los documentos `11` y `12` se escribieron después de `10`
> y conservan su número.

**Por qué ningún documento lleva la respuesta al lado de la pregunta.** Una respuesta
leída antes de intentarla no se recuerda en una entrevista. Contesta en voz alta, escribe
tu versión, y solo entonces abre [`13`](13-respuestas.md).

**Los capítulos teóricos no llevan ejercicios**, solo preguntas: se estudian sin
computadora y sin cuenta de AWS. Lo ejecutable vive entero en la Parte 2.

---

## Parte 2 — Serie práctica: labs y apéndices

Un laboratorio **serverless, solo backend, sin frontend**, construido y destruido
íntegramente desde la AWS CLI con CloudFormation. Cubre únicamente lo que no se puede
practicar en local con contenedores: identidad, ciclo de vida de IaC, servicios
administrados, observabilidad nativa y costo.

**Empieza por [`L00`](l00-idea-lab-practico.md).** Es la introducción a la serie y su
contrato: qué se construye, qué queda fuera, por qué, y cuánto cuesta.

| Doc | Contenido | Costo | Duración |
|---|---|---|---|
| **[L00 — Introducción: qué se hace en la nube y qué no](l00-idea-lab-practico.md)** | Doctrina de reparto, el caso testigo de EKS, catálogo de exclusiones, presupuesto y emuladores | — | 30 min de lectura |
| **[L01 — Preparación: CLI, identidad y blindaje de costos](l01-preparacion-cli-y-blindaje-de-costos.md)** | Perfiles, cost allocation tags, budgets, anomaly detection, Cost Explorer | $0.00 | 60–90 min |
| **[L02 — CloudFormation desde la CLI](l02-cloudformation-desde-la-cli.md)** | Change sets, `Replacement`, rollback, drift, `DeletionPolicy`, `DELETE_FAILED` | $0.00 | 2–3 h |
| **[L03 — Backend serverless: Lambda, HTTP API y eventos](l03-backend-serverless-lambda-api-y-eventos.md)** | Execution role vs resource policy, event source mappings, SQS/DLQ, idempotencia, concurrencia | centavos | 3–4 h |
| **[L04 — Observabilidad y destrucción verificada](l04-observabilidad-y-destruccion-verificada.md)** | EMF, Logs Insights, alarmas, X-Ray, CloudTrail, barrido de huérfanos y confirmación de costo | centavos | 2–3 h |
| **[A01 — AWS CLI de supervivencia](a01-cli-de-supervivencia.md)** | Perfiles, JMESPath, paginación, waiters, esqueletos, reintentos | — | referencia |
| **[A02 — Catálogo de costos, trampas y recursos huérfanos](a02-costos-trampas-y-recursos-huerfanos.md)** | Qué cobra por hora, qué sobrevive al `delete-stack`, cómo localizar un cargo | — | referencia |

Los labs son acumulativos y se hacen en orden:
[`L01`](l01-preparacion-cli-y-blindaje-de-costos.md) →
[`L02`](l02-cloudformation-desde-la-cli.md) →
[`L03`](l03-backend-serverless-lambda-api-y-eventos.md) →
[`L04`](l04-observabilidad-y-destruccion-verificada.md). Cada uno
declara en su cabecera qué deja encendido y el siguiente asume exactamente ese estado.
Los apéndices se consultan en cualquier momento, sin prerrequisitos.

**Cada lab y cada apéndice cierra con ejercicios graduados** —🟢 🟡 🟠 🔴, más 🔥 opcionales
y un 💀 *boss fight* donde el contenido lo justifica—, y todos los obligatorios respetan la
regla de costo de la serie: $0.00 o centavos, con su teardown declarado. El 💀 de
[`L04`](l04-observabilidad-y-destruccion-verificada.md#-boss-fight--el-proyecto-final-de-la-serie)
es el proyecto final del curso: levantar el sistema entero, probarlo, destruirlo y
demostrar que no queda nada, con un comando por fase y sin abrir la consola.

**Costo total de la serie completa, repetida varias veces: menos de $1.** Ningún recurso
del tronco cobra por hora, y eso no es casualidad — es la regla de diseño.

### El principio que decide el alcance

> En la nube se practica lo que **solo** existe en la nube. Todo lo demás se practica en
> local con contenedores: gratis, y con un ciclo de iteración de segundos.

Por eso quedan fuera del lab de pago Kubernetes, ECS, RDS, los brokers de mensajería,
Kinesis, los pipelines y los dashboards. No porque no importen, sino porque un contenedor
local los enseña igual o mejor, sin factura y sin esperar quince minutos por iteración.
Cada exclusión se justifica una por una —con su precio y con dónde se practica en su
lugar— en [`L00`](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones), y el
caso de EKS se desarrolla entero en
[`L00` §3](l00-idea-lab-practico.md#3--el-caso-testigo-por-qué-no-montamos-un-microservicio-en-eks).

---

## Cómo estudiar con esto

**Si tienes una entrevista esta semana.** Lee [`01`](01-infraestructura-global-y-redes.md),
[`02`](02-computo-contenedores-y-balanceo.md), [`04`](04-dynamodb-nosql.md),
[`05`](05-seguridad-iam-kms-secretos.md) y [`07`](07-mensajeria-eventos-integracion.md) —el núcleo
de una entrevista backend— y después haz [`10`](10-preguntas-entrevista-y-mapa-mental.md)
completo, contestando en voz alta. Los
[escenarios de arquitectura](10-preguntas-entrevista-y-mapa-mental.md#escenarios-de-arquitectura)
son la parte que más se parece a la entrevista real.

**Si tienes un mes.** Lee los doce documentos teóricos en orden, uno por sesión, y haz la
serie práctica [`L00`](l00-idea-lab-practico.md)–[`L04`](l04-observabilidad-y-destruccion-verificada.md)
en paralelo: [`L02`](l02-cloudformation-desde-la-cli.md) después de leer
[`09`](09-cloudformation-iac.md), [`L03`](l03-backend-serverless-lambda-api-y-eventos.md)
después de [`04`](04-dynamodb-nosql.md) y [`07`](07-mensajeria-eventos-integracion.md), y
[`L04`](l04-observabilidad-y-destruccion-verificada.md) después de
[`08`](08-observabilidad-auditoria-gobierno.md). Cierra con
[`10`](10-preguntas-entrevista-y-mapa-mental.md).

**Si ya trabajaste con AWS y solo quieres el filo.** Ve directo a
[`10`](10-preguntas-entrevista-y-mapa-mental.md), marca lo que no
sepas contestar, y usa los índices de salto rápido de cada documento para ir solo a esas
secciones.

### La regla de las cinco preguntas

Para cada servicio del temario, intenta contestar estas cinco. Si puedes con las cinco,
ese servicio ya no te lo tumban en una entrevista:

1. **¿Qué problema resuelve?**
2. **¿Es regional, zonal o global?**
3. **¿Quién administra la infraestructura: AWS o yo?**
4. **¿Cuál es la alternativa más parecida y en qué se diferencia?**
5. **¿Qué fallo o requisito de seguridad cambia el diseño?**

---

## Mapa mental de una aplicación típica

```text
Usuarios
   │
   ▼
Route 53
   │
   ▼
ALB
   │
   ├───────────────┐
   ▼               ▼
ECS/Fargate     ECS/Fargate
AZ-a            AZ-b
   │               │
   └───────┬───────┘
           │
     ┌─────┼──────────┬─────────────┐
     ▼     ▼          ▼             ▼
   RDS   DynamoDB     S3            SQS
  SQL     NoSQL     Objects       Async work
     │                              │
     └──────────────┐               ▼
                    │             Worker
                    ▼
                CloudWatch

Security/IAM alrededor de todos los recursos.
VPC/subnets/routing debajo de los workloads de red.
CloudFormation puede describir gran parte de la infraestructura.
```

Y este es el sistema que construyes en la serie práctica — deliberadamente más pequeño,
y sin un solo componente que cobre por hora:

```text
  curl → API Gateway (HTTP API) → inv-lab-api (Lambda) → DynamoDB inv-lab-events
                                                          │
                                                       Stream
                                                          ▼
                                              inv-lab-projector (Lambda)
                                                          │
                                                     SQS ──► DLQ
                                                          ▼
                                              inv-lab-alert (Lambda) → SNS
```

---

## Asociaciones que conviene memorizar

| Necesidad | Servicio/concepto |
|---|---|
| Región geográfica | Region |
| Aislamiento de fallos | Availability Zone |
| Red virtual | VPC |
| Segmento de red zonal | Subnet |
| Firewall stateful de workload | Security Group |
| Firewall stateless de subnet | NACL |
| VM | EC2 |
| Imagen de VM | AMI |
| Block storage | EBS |
| Object storage | S3 |
| File storage compartido | EFS |
| Registry de contenedores | ECR |
| Orquestación nativa de containers | ECS |
| Compute serverless para containers | Fargate |
| Kubernetes administrado | EKS |
| Functions serverless | Lambda |
| API administrada | API Gateway |
| CDN/edge cache | CloudFront |
| Certificados TLS administrados | ACM |
| SQL administrado | RDS / Aurora |
| NoSQL key-value/document | DynamoDB |
| Queue | SQS |
| Pub/Sub | SNS |
| Event bus / routing | EventBridge |
| Streaming ordenado con múltiples lectores | Kinesis |
| DNS | Route 53 |
| L7 load balancing | ALB |
| L4 load balancing | NLB |
| Identidad y autorización entre servicios | IAM |
| Identidad de usuario final de una app | Cognito |
| Cifrado/keys | KMS |
| Secretos | Secrets Manager |
| Métricas/logs/alarmas | CloudWatch |
| Trazas distribuidas | X-Ray |
| Auditoría de API | CloudTrail |
| Configuración/compliance | AWS Config |
| IaC declarativo AWS | CloudFormation |
| Orquestación de workflows Lambda/ECS | Step Functions |
| Framework de evaluación de arquitectura | Well-Architected Framework |
| Backup centralizado cross-servicio | AWS Backup |

---

## Convenciones del curso

Todo `.md` de este directorio sigue [`prompts/guia-de-estilo-y-convenciones.md`](prompts/guia-de-estilo-y-convenciones.md).
Lo mínimo que conviene saber para leerlo o para editarlo:

- **Emoji de encabezado funcional**, no decorativo: 🧭 encuadre · 🧱 mecanismo ·
  ⚖ comparación · 🩺 diagnóstico · 💰 costo · 🧪 verificación · 🧠 preguntas ·
  📚 referencias.
- **Callouts en blockquote:** ⚠️ advertencia · 🧠 modelo mental · 💡 truco ·
  🩺 diagnóstico · 💰 costo · 📝 contexto · 📚 referencia inline.
- **Ningún comando ni flag queda sin explicar**, en especial en los labs.
- **Todo lo que cobra por hora se nombra con su precio y su unidad.**
- **Las respuestas viven solo en [`13`](13-respuestas.md)**; quien toca una pregunta,
  actualiza ese archivo en la misma edición. Los **ejercicios** de labs y apéndices no van
  ahí: se verifican con su `Objetivo:` y con la salida real del comando.
- **Solo se enlaza documentación oficial de AWS**; las herramientas de terceros van en
  una subsección aparte marcada como opcional.
- **Los enlaces se verifican por código de estado, no a ojo**: la documentación de AWS
  responde a una URL muerta con una redirección al índice de la guía, no con un 404, así
  que un enlace que aterriza en la portada cuenta como roto.

---

## Relación con el resto del repositorio

```text
docker-container-legacy   → cómo funciona un contenedor por dentro
                            namespaces, cgroups, overlayfs, capas, PID 1

laboratorio local          → cómo funcionan muchos contenedores juntos
(en preparación)             Kubernetes, mensajería, observabilidad, pipelines

repaso-aws-entrevistas     → qué cambia cuando el dueño de la infraestructura
+ serie práctica L00-L04     es otro: identidad, red, IaC, servicios
                             administrados y costo
```

---

## Referencias oficiales base

Cada documento cierra con las suyas, específicas del tema. Estas son las portadas:

- AWS Regions and Availability Zones: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-regions-availability-zones.html
- Amazon VPC User Guide: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
- Amazon EC2 User Guide: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html
- Amazon ECS Developer Guide: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html
- AWS Lambda Developer Guide: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- Amazon DynamoDB Developer Guide: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html
- Amazon Route 53 Developer Guide: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html
- IAM User Guide: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html
- AWS CloudFormation User Guide: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html
- AWS Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
- AWS CLI Command Reference: https://docs.aws.amazon.com/cli/latest/reference/
- AWS Pricing Calculator: https://calculator.aws/
