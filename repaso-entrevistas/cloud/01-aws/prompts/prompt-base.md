# Prompt: tutorial rápido de AWS para refresco técnico e entrevistas

Genera un tutorial de repaso rápido de AWS orientado a refrescar conocimientos técnicos y preparar entrevistas para perfiles **Backend Senior / Software Architect**.

El objetivo no es crear un curso exhaustivo de certificación, sino una colección de **notas técnicas concisas, prácticas, modulares y fáciles de consultar**.

---

## 1. Formato de entrega

Estructura el contenido en **varios archivos Markdown (`.md`)**, separados por categoría y ordenados desde los conceptos más fundamentales hasta los temas de arquitectura e entrevista.

Crea además un archivo:

```text
00-README.md
```

que funcione como:

- índice general;
- mapa de estudio;
- guía de navegación;
- resumen de servicios;
- orden recomendado de lectura.

Usa una numeración consistente, por ejemplo:

```text
00-README.md
01-infraestructura-global-y-redes.md
02-computo-y-maquinas-virtuales.md
03-contenedores-y-orquestacion.md
04-almacenamiento-y-bases-sql.md
05-dynamodb-y-nosql.md
06-seguridad-e-iam.md
07-route53-dns-y-conectividad.md
08-mensajeria-y-eventos.md
09-observabilidad-y-auditoria.md
10-cloudformation-e-iac.md
11-preguntas-de-entrevista.md
```

Puedes reorganizar, dividir o fusionar categorías si mejora la coherencia pedagógica, pero evita generar un único documento demasiado grande.

Cada archivo debe poder consultarse de forma independiente, aunque manteniendo continuidad con los anteriores.

---

# 2. Infraestructura global de AWS

Incluir como mínimo:

- AWS Regions;
- Availability Zones;
- Edge Locations;
- Local Zones;
- relación:

```text
AWS
└── Region
    └── VPC
        ├── Availability Zone A
        │   ├── Public Subnet
        │   └── Private Subnet
        │
        └── Availability Zone B
            ├── Public Subnet
            └── Private Subnet
```

Explicar:

- Region vs Availability Zone;
- recursos regionales vs zonales;
- aislamiento de fallos;
- alta disponibilidad;
- Multi-AZ;
- Multi-Region;
- cuándo cada estrategia tiene sentido.

---

# 3. Networking

Cubrir:

- VPC;
- CIDR;
- IPv4;
- IPv6;
- Subnets;
- Public Subnets;
- Private Subnets;
- Isolated Subnets;
- Route Tables;
- rutas locales;
- longest prefix match;
- Internet Gateway;
- NAT Gateway;
- Elastic IP;
- ENI;
- Security Groups;
- Network ACLs;
- Stateful vs Stateless;
- VPC Endpoints;
- Gateway Endpoints;
- Interface Endpoints;
- AWS PrivateLink;
- VPC Peering;
- Transit Gateway;
- Site-to-Site VPN;
- Direct Connect;
- Egress-Only Internet Gateway;
- Managed Prefix Lists;
- IPAM.

Explicar claramente diferencias como:

```text
Public Subnet vs Private Subnet
Security Group vs NACL
Internet Gateway vs NAT Gateway
VPC Peering vs Transit Gateway
VPN vs Direct Connect
Gateway Endpoint vs Interface Endpoint
IPv4 vs IPv6
```

Incluir troubleshooting básico de conectividad.

Por ejemplo, utilizar esta secuencia mental:

```text
1. ¿DNS resuelve?
2. ¿La IP es correcta?
3. ¿Existe una ruta?
4. ¿El gateway o endpoint correcto está disponible?
5. ¿La NACL permite tráfico?
6. ¿El Security Group permite tráfico?
7. ¿El servicio escucha realmente en el puerto?
```

---

# 4. Máquinas virtuales y cómputo

Cubrir:

- EC2;
- AMI;
- Instance Types;
- familias de instancias;
- CPU, memoria, red y almacenamiento;
- EBS;
- Instance Store;
- Auto Scaling Groups;
- Launch Templates;
- Health Checks;
- escalado vertical;
- escalado horizontal;
- alta disponibilidad;
- Placement Groups a nivel introductorio.

Explicar diferencias:

```text
EC2 vs Lambda
EC2 vs containers
Scale Up vs Scale Out
EBS vs Instance Store
```

---

# 5. Load Balancing

Incluir:

- Elastic Load Balancing;
- ALB;
- NLB;
- listeners;
- listener rules;
- target groups;
- health checks;
- routing por host;
- routing por path;
- integración con Auto Scaling;
- integración con ECS.

Comparar:

```text
ALB vs NLB
Layer 7 vs Layer 4
```

Ejemplo:

```text
/api/users/*  → User Service
/api/orders/* → Order Service
```

---

# 6. Contenerización

Explicar el uso de Docker en AWS.

Cubrir:

- Docker Images;
- ECR;
- ECS;
- ECS Cluster;
- Task Definition;
- Task;
- Service;
- ECS Service;
- ECS sobre EC2;
- ECS con Fargate;
- Auto Scaling;
- integración con ALB;
- EKS;
- Kubernetes administrado;
- Lambda para comparación.

Explicar especialmente:

```text
Docker vs ECS
EC2 vs ECS
ECS vs EKS
ECS vs Fargate
EC2 vs Fargate
ECR vs Docker Hub
Containers vs Lambda
```

Dejar muy claro que:

```text
ECS     = orquestación
Fargate = capacidad de cómputo administrada
```

y que Fargate no reemplaza ECS.

---

# 7. Caso recurrente: Spring Boot

Usa durante los documentos una aplicación backend Java/Spring Boot como ejemplo recurrente.

Por ejemplo:

```text
Internet
   │
Route 53
   │
ALB
   │
ECS / Fargate
   │
Spring Boot
   ├── Aurora / RDS
   ├── DynamoDB
   ├── S3
   ├── SQS
   └── Secrets Manager
```

Utiliza este sistema para explicar cómo interactúan los servicios.

---

# 8. Almacenamiento

Cubrir:

- Amazon S3;
- buckets;
- objects;
- keys;
- metadata;
- versioning;
- lifecycle policies;
- storage classes;
- replication a nivel introductorio;
- encryption;
- presigned URLs;
- EBS;
- EFS.

Explicar:

```text
Object Storage
Block Storage
File Storage
```

Comparar:

```text
S3 vs EBS vs EFS
```

Usar la analogía:

```text
EBS ≈ disco
EFS ≈ filesystem compartido
S3  ≈ almacén de objetos accesible mediante API
```

---

# 9. Bases de datos SQL

Cubrir:

- Amazon RDS;
- PostgreSQL;
- MySQL;
- MariaDB;
- SQL Server;
- Oracle a nivel general;
- Amazon Aurora;
- Aurora PostgreSQL;
- Aurora MySQL;
- Multi-AZ;
- Read Replicas;
- backups;
- snapshots;
- automated backups;
- failover;
- RDS Proxy;
- connection pooling;
- ElastiCache como complemento introductorio.

Explicar:

```text
RDS vs Aurora
Multi-AZ vs Read Replica
Primary vs Replica
HA vs Scaling
```

Explicar cuándo usar una base SQL:

- relaciones complejas;
- joins;
- integridad referencial;
- transacciones;
- consultas flexibles;
- reporting.

---

# 10. DynamoDB y NoSQL

Dedicar un documento específico y con mayor profundidad a DynamoDB.

Explicar primero:

- qué es NoSQL;
- Key-Value;
- Document Model;
- diferencias conceptuales con SQL.

Cubrir:

- Table;
- Item;
- Attribute;
- Partition Key;
- Sort Key;
- Composite Primary Key;
- Access Patterns;
- Query;
- Scan;
- Global Secondary Index — GSI;
- Local Secondary Index — LSI;
- eventual consistency;
- strongly consistent reads;
- on-demand capacity;
- provisioned capacity;
- RCU;
- WCU;
- hot partitions;
- partition distribution;
- conditional writes;
- optimistic locking;
- transactions;
- TTL;
- DynamoDB Streams;
- Global Tables;
- Single Table Design;
- sparse indexes;
- idempotency patterns.

Explicar especialmente:

```text
Query vs Scan
GSI vs LSI
DynamoDB vs PostgreSQL
Partition Key vs Sort Key
On-Demand vs Provisioned
Strong Consistency vs Eventual Consistency
```

Enfatizar:

> En DynamoDB el modelo se diseña principalmente a partir de los access patterns, no de las entidades relacionales.

Incluir ejemplos como:

```text
PK           SK
USER#123     PROFILE
USER#123     ORDER#001
USER#123     ORDER#002
USER#456     PROFILE
USER#456     ORDER#001
```

Mostrar qué access patterns resuelve cada diseño.

---

# 11. Seguridad

Crear un documento específico de seguridad.

Incluir:

## Shared Responsibility Model

Explicar:

```text
Security OF the Cloud
vs
Security IN the Cloud
```

## IAM

Cubrir:

- IAM Users;
- IAM Groups;
- IAM Roles;
- Policies;
- permissions;
- identity-based policies;
- resource-based policies;
- trust policies;
- permission boundaries a nivel introductorio;
- STS;
- temporary credentials;
- AssumeRole;
- Principle of Least Privilege;
- explicit Allow;
- implicit Deny;
- explicit Deny;
- MFA;
- root user;
- AWS IAM Identity Center.

Explicar especialmente:

```text
IAM Role vs IAM User
Identity Policy vs Resource Policy
Permissions Policy vs Trust Policy
Long-lived credentials vs temporary credentials
```

Enfatizar que una aplicación:

```text
EC2
ECS
Lambda
```

debe preferir IAM Roles y credenciales temporales en lugar de almacenar:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

en código, repositorios o imágenes Docker.

---

# 12. KMS y cifrado

Cubrir:

- AWS KMS;
- KMS Keys;
- encryption at rest;
- encryption in transit;
- TLS;
- symmetric keys;
- envelope encryption;
- data keys;
- key policies;
- integración con S3, EBS, RDS, DynamoDB y Secrets Manager.

Explicar:

```text
Encryption at Rest
vs
Encryption in Transit
```

y:

```text
KMS
vs
Secrets Manager
```

---

# 13. Secretos y configuración

Cubrir:

- AWS Secrets Manager;
- Systems Manager Parameter Store;
- secretos;
- configuración;
- rotación de credenciales;
- acceso mediante IAM;
- cifrado con KMS.

Comparar:

```text
Secrets Manager vs Parameter Store
```

---

# 14. Seguridad perimetral

Introducir:

- AWS WAF;
- AWS Shield;
- Shield Standard;
- Shield Advanced a nivel conceptual;
- CloudFront;
- protección DDoS;
- reglas WAF;
- rate limiting a nivel conceptual.

Comparar:

```text
Security Group vs WAF
WAF vs Shield
```

---

# 15. Organizations y gobierno

Introducir:

- AWS Organizations;
- Accounts;
- Organizational Units;
- Service Control Policies — SCP;
- separación de cuentas;
- producción vs desarrollo;
- centralized security.

Explicar:

```text
IAM Policy
vs
SCP
```

y dejar claro que una SCP funciona principalmente como un límite de permisos organizacional, no como un permiso concedido directamente.

---

# 16. Route 53 y DNS

Crear un documento específico.

Explicar primero los fundamentos:

- DNS;
- domain;
- hostname;
- resolver;
- authoritative DNS;
- TTL.

Cubrir Route 53:

- Hosted Zones;
- Public Hosted Zones;
- Private Hosted Zones;
- registros:
  - A;
  - AAAA;
  - CNAME;
  - Alias;
  - MX;
  - TXT;
- health checks;
- DNS failover.

Cubrir todas las políticas relevantes:

- Simple Routing;
- Weighted Routing;
- Latency Routing;
- Failover Routing;
- Geolocation Routing;
- Geoproximity Routing;
- IP-Based Routing;
- Multivalue Answer Routing.

Comparar:

```text
A vs AAAA
CNAME vs Alias
Public Hosted Zone vs Private Hosted Zone
Weighted vs Failover
Latency vs Geolocation
```

Mostrar integración:

```text
Route 53
    │
    ├── ALB
    ├── CloudFront
    └── API Gateway
```

---

# 17. CloudFront y certificados

Introducir:

- CloudFront;
- CDN;
- Edge Locations;
- Origin;
- Cache;
- TTL;
- behaviors;
- S3 origin;
- ALB origin;
- AWS Certificate Manager — ACM;
- TLS certificates;
- HTTPS.

Comparar:

```text
Route 53 vs CloudFront
ALB vs CloudFront
ACM vs KMS
```

---

# 18. API Gateway

Introducir:

- API Gateway;
- HTTP API;
- REST API a nivel conceptual;
- integración con Lambda;
- integración con HTTP backends;
- authentication/authorization a nivel general;
- throttling;
- stages;
- routing.

Comparar:

```text
API Gateway vs ALB
```

sin entrar todavía en detalles avanzados.

---

# 19. Mensajería y eventos

Cubrir:

## SQS

- Queue;
- producer;
- consumer;
- Standard Queue;
- FIFO Queue;
- at-least-once delivery;
- ordering;
- deduplication;
- Visibility Timeout;
- retries;
- Dead Letter Queue — DLQ;
- retention;
- long polling;
- idempotencia.

Explicar:

```text
Standard vs FIFO
Visibility Timeout
DLQ
Idempotent Consumer
```

## SNS

Cubrir:

- Topic;
- Publisher;
- Subscriber;
- pub/sub;
- fan-out;
- integración SNS + SQS.

Ejemplo:

```text
             SNS
          ┌───┼────┐
          ▼   ▼    ▼
         SQS SQS  SQS
```

## EventBridge

Cubrir:

- Event Bus;
- events;
- rules;
- targets;
- event-driven architecture;
- integración con servicios AWS.

Comparar:

```text
SQS vs SNS vs EventBridge
Queue vs Pub/Sub vs Event Bus
```

---

# 20. Procesamiento asíncrono

Usar escenarios como:

```text
POST /orders
      │
      ▼
Spring Boot
      │
      ▼
     SQS
      │
      ▼
Payment Worker
```

Explicar:

- desacoplamiento;
- buffering;
- backpressure;
- retries;
- DLQ;
- idempotencia;
- escalado de consumers;
- respuesta HTTP `202 Accepted`.

---

# 21. Observabilidad

Cubrir:

## CloudWatch

- Metrics;
- Logs;
- Log Groups;
- Log Streams;
- Alarms;
- Dashboards;
- custom metrics;
- retention.

## CloudTrail

- auditoría de acciones;
- API activity;
- quién hizo qué;
- cuándo;
- desde dónde.

## AWS Config

- configuration history;
- compliance;
- cambios de recursos.

## Networking diagnostics

- VPC Flow Logs;
- Reachability Analyzer.

Comparar:

```text
CloudWatch vs CloudTrail
CloudTrail vs AWS Config
Metrics vs Logs vs Audit Events
VPC Flow Logs vs Application Logs
```

---

# 22. Infrastructure as Code

Crear un documento específico de **AWS CloudFormation**.

Explicar primero:

```text
Infrastructure as Code
```

y los conceptos:

- Template;
- Stack;
- Stack Update;
- Resource;
- YAML;
- JSON.

---

# 23. CloudFormation básico

Cubrir las secciones:

```yaml
AWSTemplateFormatVersion:
Description:
Metadata:
Parameters:
Mappings:
Conditions:
Resources:
Outputs:
```

Dejar claro que:

```text
Resources
```

es la sección central y obligatoria para definir infraestructura.

---

# 24. CloudFormation Resources

Ejemplo pequeño:

```yaml
Resources:
  ExampleBucket:
    Type: AWS::S3::Bucket
```

Explicar:

```text
Logical ID
Resource Type
Properties
```

---

# 25. Parameters

Ejemplo:

```yaml
Parameters:
  Environment:
    Type: String
    AllowedValues:
      - dev
      - test
      - prod
```

Explicar para qué sirven y cuándo usarlos.

---

# 26. Outputs

Ejemplo:

```yaml
Outputs:
  BucketName:
    Value: !Ref ExampleBucket
```

Explicar:

- mostrar resultados;
- exportar valores;
- cross-stack references a nivel introductorio.

---

# 27. Funciones intrínsecas

Cubrir como mínimo:

```text
Ref
Fn::GetAtt
Fn::Sub
Fn::Join
Fn::FindInMap
Fn::If
```

y su sintaxis corta YAML:

```yaml
!Ref
!GetAtt
!Sub
!Join
!FindInMap
!If
```

---

# 28. Pseudo Parameters

Explicar:

```text
AWS::Region
AWS::AccountId
AWS::StackName
AWS::Partition
```

Ejemplo:

```yaml
BucketName: !Sub "${AWS::StackName}-${AWS::Region}"
```

---

# 29. Conditions

Ejemplo:

```yaml
Conditions:
  IsProduction: !Equals
    - !Ref Environment
    - prod
```

Explicar cómo crear recursos condicionales.

---

# 30. DependsOn

Explicar:

- dependencias implícitas;
- dependencias explícitas;
- cuándo `DependsOn` es realmente necesario.

Evitar enseñar a usar `DependsOn` innecesariamente.

---

# 31. Lifecycle de recursos

Cubrir:

```text
DeletionPolicy
UpdateReplacePolicy
```

Ejemplo:

```yaml
DeletionPolicy: Retain
```

Explicar riesgos al borrar stacks con:

- bases de datos;
- buckets;
- datos persistentes.

---

# 32. Change Sets

Explicar el flujo:

```text
Template modificado
      │
      ▼
Change Set
      │
      ▼
Revisión
      │
      ▼
Execute
```

Enfatizar que permiten revisar cambios antes de aplicarlos.

---

# 33. Rollback

Explicar:

- fallo durante creación;
- fallo durante update;
- rollback;
- rollback completo vs troubleshooting.

---

# 34. Drift Detection

Explicar qué ocurre cuando alguien modifica manualmente un recurso fuera de CloudFormation.

Ejemplo:

```text
CloudFormation:
port 443

Cambio manual:
port 22 añadido
```

Resultado:

```text
DRIFTED
```

Explicar por qué mezclar IaC con cambios manuales dificulta la administración.

---

# 35. Nested Stacks y StackSets

Introducir:

## Nested Stacks

Para composición y reutilización de templates.

## StackSets

Para desplegar infraestructura en:

- múltiples cuentas;
- múltiples Regions.

No profundizar excesivamente.

---

# 36. Ejemplos CloudFormation

Incluir ejemplos pequeños y completos de:

1. bucket S3;
2. Security Group;
3. DynamoDB Table;
4. VPC;
5. Subnet;
6. parámetros;
7. outputs.

Ejemplo objetivo:

```yaml
AWSTemplateFormatVersion: "2010-09-09"

Description: Example DynamoDB table

Parameters:
  Environment:
    Type: String
    Default: dev

Resources:

  UsersTable:
    Type: AWS::DynamoDB::Table
    Properties:
      BillingMode: PAY_PER_REQUEST

      AttributeDefinitions:
        - AttributeName: PK
          AttributeType: S
        - AttributeName: SK
          AttributeType: S

      KeySchema:
        - AttributeName: PK
          KeyType: HASH
        - AttributeName: SK
          KeyType: RANGE

Outputs:

  TableName:
    Value: !Ref UsersTable
```

Explicar línea por línea, pero de forma concisa.

---

# 37. CloudFormation vs Terraform

Crear solamente una comparación introductoria.

Comparar:

| CloudFormation | Terraform |
|---|---|
| AWS native | Multi-cloud |
| YAML/JSON | HCL |
| AWS-managed state | Terraform state |
| Integración inmediata con AWS | Ecosistema amplio |

No convertir esta sección en tutorial de Terraform.

---

# 38. Estilo general

El contenido debe sentirse como una:

```text
chuleta técnica ampliada
+
tutorial rápido
+
mapa mental
+
referencia arquitectónica
+
guía de preparación para entrevistas
```

Usa principalmente:

- explicaciones cortas;
- listas;
- tablas comparativas;
- diagramas ASCII;
- ejemplos pequeños;
- código;
- reglas mnemotécnicas;
- advertencias;
- escenarios;
- preguntas de entrevista.

Evita bloques de prosa excesivamente largos.

---

# 39. Formato de explicación

Para conceptos clave usar formatos similares a:

```text
Security Group
→ firewall asociado al recurso/ENI
→ stateful
→ solo reglas ALLOW

NACL
→ firewall de subnet
→ stateless
→ ALLOW + DENY
```

Cuando existan conceptos similares, usar tablas comparativas.

Ejemplos:

```text
EC2 vs ECS vs EKS vs Fargate
RDS vs Aurora
Multi-AZ vs Read Replica
S3 vs EBS vs EFS
Security Group vs NACL
SQS vs SNS vs EventBridge
IAM Role vs IAM User
ALB vs NLB
VPC Peering vs Transit Gateway
CloudFormation vs Terraform
DynamoDB vs PostgreSQL
Route 53 vs CloudFront
API Gateway vs ALB
Secrets Manager vs Parameter Store
KMS vs Secrets Manager
```

---

# 40. "Qué recordar"

Al final de cada tema importante agregar una pequeña sección:

```markdown
## Qué recordar
```

con entre 3 y 10 ideas esenciales.

Ejemplo:

```text
- VPC es regional.
- Subnet pertenece a una sola AZ.
- Security Group es stateful.
- NACL es stateless.
- Una public subnet tiene ruta hacia un Internet Gateway.
```

---

# 41. Errores frecuentes

Crear subsecciones:

```markdown
## Errores y confusiones frecuentes
```

Por ejemplo:

- creer que ECS y Fargate son lo mismo;
- creer que Fargate reemplaza ECS;
- confundir Multi-AZ con Read Replica;
- afirmar que una EC2 en una public subnet es automáticamente pública;
- confundir IAM Role con IAM User;
- usar Scan como patrón normal de acceso en DynamoDB;
- guardar Access Keys dentro de containers;
- confundir Route 53 con CloudFront;
- creer que Security Group tiene reglas DENY;
- asumir que VPC Peering es transitivo.

---

# 42. Preguntas de entrevista por documento

Al final de cada archivo agregar:

```markdown
## Preguntas de entrevista
```

con entre **5 y 15 preguntas rápidas**.

Ejemplo:

```text
1. ¿Qué diferencia existe entre una Region y una Availability Zone?
2. ¿Por qué una subnet es pública?
3. ¿Una EC2 en una public subnet es automáticamente accesible desde Internet?
4. ¿Por qué Security Groups son stateful?
5. ¿Qué diferencia existe entre Security Group y NACL?
```

---

# 43. Documento específico de entrevistas

Crear finalmente:

```text
11-preguntas-de-entrevista.md
```

o equivalente.

Organizar preguntas por dificultad:

```text
Junior refresher
Mid
Senior
Software Architect
Troubleshooting
Architecture scenarios
```

Incluir:

- pregunta;
- respuesta esperada;
- puntos que una buena respuesta debería mencionar;
- errores frecuentes.

---

# 44. Escenarios Senior / Architect

Incluir preguntas como:

### Escenario 1

Una API Java recibe más solicitudes de las que puede procesar síncronamente.

Preguntar:

> ¿Cómo diseñarías la arquitectura?

Esperar conceptos como:

```text
API
SQS
workers
autoscaling
DLQ
idempotency
backpressure
```

### Escenario 2

Una aplicación Spring Boot monolítica está desplegada directamente en una EC2.

Preguntar:

> ¿Cómo la modernizarías sin introducir complejidad innecesaria?

Esperar discutir:

```text
Docker
ECR
ECS
Fargate
ALB
Auto Scaling
RDS
Secrets Manager
CloudWatch
```

y justificar si realmente se necesita EKS.

### Escenario 3

Una aplicación necesita almacenar:

- usuarios;
- pedidos;
- sesiones;
- documentos PDF;
- imágenes;
- eventos.

Preguntar qué usar entre:

```text
RDS / Aurora
DynamoDB
S3
SQS
```

y justificar cada decisión.

---

# 45. Nivel técnico objetivo

El lector objetivo es:

```text
Backend Senior
Software Architect
Java / Spring Boot Developer
Cloud refresher
AWS interview preparation
```

Asume conocimientos previos de:

- programación;
- Java;
- HTTP;
- REST;
- Linux;
- Docker;
- SQL;
- redes básicas;
- sistemas distribuidos.

No gastar demasiado espacio explicando conceptos elementales de programación.

El propósito es **refrescar AWS**, no enseñar informática desde cero.

---

# 46. Profundidad

Utilizar aproximadamente esta prioridad:

```text
⭐⭐⭐⭐⭐ imprescindible para entrevista
⭐⭐⭐⭐ importante
⭐⭐⭐ útil
⭐⭐ conocimiento complementario
⭐ referencia
```

Priorizar profundidad en:

- EC2;
- VPC;
- Subnets;
- Route Tables;
- Security Groups;
- IAM;
- S3;
- RDS;
- Aurora;
- DynamoDB;
- ECS;
- Fargate;
- ALB;
- Route 53;
- SQS;
- CloudWatch;
- CloudFormation.

Dar menor profundidad a servicios especializados que no sean necesarios para construir el mapa mental principal.

---

# 47. Fuentes

Utiliza principalmente **documentación oficial de AWS**.

Antes de afirmar detalles que puedan haber cambiado, verifica la documentación actual.

Evita usar como fuente principal:

- blogs no oficiales;
- artículos SEO;
- respuestas de Stack Overflow;
- material de certificación de terceros,

cuando exista documentación oficial de AWS.

Al final de cada archivo agregar:

```markdown
## Referencias oficiales
```

con enlaces relevantes a:

```text
https://docs.aws.amazon.com/
```

Priorizar enlaces específicos de cada servicio.

---

# 48. Exactitud temporal

AWS cambia servicios y características con frecuencia.

Por tanto:

- verifica conceptos actuales;
- indica cuando una práctica haya cambiado;
- evita repetir reglas antiguas como absolutas;
- distingue características legacy de las actuales;
- especifica cuando una característica nueva modifique una regla común de entrevista.

---

# 49. Resultado esperado

El resultado final debe ser una colección de archivos `.md` que pueda utilizarse indistintamente como:

```text
repaso rápido de AWS
chuleta técnica
material de estudio
referencia diaria
preparación para entrevistas
base para discusión de arquitectura
```

La prioridad debe ser:

```text
claridad
>
estructura
>
capacidad de consulta rápida
>
profundidad útil
>
exhaustividad de certificación
```

No producir una enciclopedia de todos los servicios AWS.

Construir primero un mapa mental sólido de los servicios fundamentales y cómo se relacionan.