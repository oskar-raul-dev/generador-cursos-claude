# 02 — Cómputo, contenedores y balanceo

> **Objetivo:** elegir con criterio entre EC2, ECS, Fargate, EKS y Lambda, y saber
> explicar en voz alta por qué descartaste los otros cuatro.
> **Se asume leído:** [`01`](01-infraestructura-global-y-redes.md) — VPC, subnets y
> Security Groups.
> **Se conecta con:** [`07`](07-mensajeria-eventos-integracion.md) (cómo se comunican
> estos componentes) y [`11`](11-resiliencia-y-well-architected.md) (cómo sobreviven a un fallo).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Mapa mental](#1--mapa-mental) · [EC2 — Elastic Compute Cloud](#2--ec2--elastic-compute-cloud) · [AMI — Amazon Machine Image](#3--ami--amazon-machine-image) · [EC2 purchase models — idea básica](#4--ec2-purchase-models--idea-básica) · [EBS con EC2](#5--ebs-con-ec2) · [User Data](#6--user-data) · [Auto Scaling Group — ASG](#7--auto-scaling-group--asg) · [Docker vs VM](#8--docker-vs-vm) · [ECR — Elastic Container Registry](#9--ecr--elastic-container-registry) · [ECS — Elastic Container Service](#10--ecs--elastic-container-service) · [Fargate](#11--fargate) · [ECS vs EKS](#12--ecs-vs-eks) · [Lambda](#13--lambda) · [Lambda en profundidad](#14--lambda-en-profundidad) · [API Gateway — idea base](#15--api-gateway--idea-base) · [Elastic Load Balancing](#16--elastic-load-balancing) · [ALB — Application Load Balancer](#17--alb--application-load-balancer) · [NLB — Network Load Balancer](#18--nlb--network-load-balancer) · [ALB vs NLB](#19--alb-vs-nlb) · [Arquitectura containerizada típica](#20--arquitectura-containerizada-típica) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

## 1. 🧭 Mapa mental

```text
Más control                                    Más administrado
◄─────────────────────────────────────────────────────────────►
EC2              ECS/Fargate                   Lambda
VM                Container workload            Function
```

No es una escala absoluta, pero ayuda a recordar cuánto de la infraestructura administras.

---

## 2. 🧱 EC2 — Elastic Compute Cloud

**EC2 = máquinas virtuales bajo demanda.**

Tú eliges, entre otras cosas:

- AMI;
- instance type;
- networking;
- storage;
- IAM role;
- Security Groups;
- lifecycle.

### Instance type

Determina combinación de:

- vCPU;
- memoria;
- networking;
- storage capabilities;
- arquitectura de procesador.

Familias conceptuales:

```text
T → burstable/general low-cost cases
M → general purpose
C → compute optimized
R → memory optimized
I → storage/I/O optimized
G/P → GPU/accelerated
```

No memorices generaciones completas para una entrevista general; entiende el propósito de las familias.

---

## 3. 🧱 AMI — Amazon Machine Image

Una **AMI** es la plantilla utilizada para lanzar EC2.

Puede incluir:

- sistema operativo;
- software preinstalado;
- configuración;
- mapping de volúmenes.

Modelo:

```text
AMI
 │
 ├── EC2 instance A
 ├── EC2 instance B
 └── EC2 instance C
```

---

## 4. 💰 EC2 purchase models — idea básica

### On-Demand

Capacidad sin compromiso a largo plazo.

### Savings Plans / Reserved capacity concepts

Compromiso de uso para optimizar costo; la mecánica exacta depende del producto.

### Spot

Capacidad sobrante con descuento fuerte —del orden del 70–90 % frente a On-Demand— con
una condición: AWS puede reclamarla, y te avisa con dos minutos.

Casos Spot:

- batch;
- CI;
- workers tolerantes a interrupciones;
- procesamiento distribuido.

No usar sin diseño adicional para un único componente crítico stateful.

Lo que une esos casos es que **el trabajo se puede reintentar en otra máquina sin que
nadie se entere**. Un runner de CI que muere reencola su job; un worker de cola devuelve
el mensaje y otro lo toma —para eso está el visibility timeout de
[`07` §5](07-mensajeria-eventos-integracion.md#5--visibility-timeout)—. Lo que no
sobrevive a Spot es lo que guarda estado en la propia instancia o lo que no tiene a quién
delegar: una base de datos, un nodo único con sesiones en memoria.

Sobre los tres modelos, la forma útil de decidir es por **la forma de la carga, no por el
precio**: la base estable y siempre encendida se compromete con un Savings Plan, el pico
predecible se cubre con On-Demand, y el trabajo diferible e interrumpible se manda a
Spot. Optimizar significa mezclarlos, no elegir uno.

> 💰 **Costo.** Un Savings Plan es un compromiso de gasto por hora durante uno o tres
> años: se paga entero aunque no lo uses, así que se dimensiona sobre el suelo medido de
> consumo, nunca sobre el pico ni sobre la previsión optimista.

---

## 5. 🧱 EBS con EC2

**EBS = block storage** persistente para EC2 y otros servicios compatibles.

Analogía:

```text
EC2 → VM
EBS → disco de bloques
```

El lifecycle de un volumen puede configurarse independientemente del de la instancia.

---

## 6. 🧱 User Data

EC2 User Data permite ejecutar bootstrap al iniciar una instancia, por ejemplo:

```bash
#!/bin/bash
dnf update -y
# instalar runtime/configurar servicio...
```

Útil para bootstrapping, aunque en sistemas maduros suele combinarse con AMIs, configuration management o IaC.

---

## 7. 🧱 Auto Scaling Group — ASG

Mantiene una cantidad deseada de instancias y puede ajustar capacidad.

```text
           ALB
            │
     ┌──────┼──────┐
     ▼      ▼      ▼
   EC2    EC2    EC2
     ▲             ▲
     └──── ASG ────┘
```

Conceptos:

- minimum capacity;
- desired capacity;
- maximum capacity;
- health checks;
- scaling policies;
- launch template.

### Scale up vs scale out

```text
vertical   → instancia más grande
horizontal → más instancias
```

En cloud suele preferirse diseñar para scale out cuando el workload lo permite.

---

## 8. ⚖ Docker vs VM

### VM

```text
Hardware
└── Hypervisor
    └── Guest OS
        └── JVM
            └── App
```

### Container

```text
Host OS
└── Container Runtime
    ├── App A
    └── App B
```

EC2 resuelve compute virtualizado; Docker resuelve packaging/aislamiento de procesos. Pueden coexistir: containers pueden ejecutarse sobre EC2.

---

## 9. 🧱 ECR — Elastic Container Registry

Registro administrado de imágenes.

```text
docker build
    │
    ▼
container image
    │
    ▼
   ECR
    │
    ▼
ECS / EKS / otros runtimes
```

Piensa en ECR como el registry, no como el orchestrator.

---

## 10. 🧱 ECS — Elastic Container Service

Orquestador de containers nativo de AWS.

Jerarquía mental:

```text
Cluster
└── Service
    └── Task
        └── Container(s)
```

### Task Definition

Blueprint declarativo del workload:

- images;
- CPU/memory;
- ports;
- environment variables;
- secrets;
- IAM roles;
- logging;
- volumes;
- networking options.

### Task

Instancia en ejecución de una task definition.

### Service

Mantiene un número deseado de tasks y puede integrarse con load balancing y autoscaling.

```text
Service desiredCount = 3

Task 1
Task 2
Task 3
```

Si una task muere, ECS intenta mantener el desired count.

---

## 11. 🧱 Fargate

**Fargate no reemplaza ECS.**

```text
ECS      → orchestrator/control plane de containers
Fargate  → compute administrado para ejecutar tasks
```

Comparación:

### ECS sobre EC2

Tú administras también:

- capacidad EC2;
- patching/base OS;
- scaling de hosts;
- utilización de cluster.

### ECS sobre Fargate

Tú defines el workload containerizado y AWS administra la capacidad de servidor subyacente.

Pregunta clásica:

> ¿Fargate es “serverless”?

En el sentido operativo de compute para containers, sí: no administras servidores/hosts.
La aplicación sigue teniendo CPU, memoria, networking y límites concretos.

Lo interesante es cuándo conviene cada uno, porque no es una escalera donde Fargate sea
siempre el peldaño superior. Fargate cobra por la CPU y la memoria que declara cada task,
mientras corre: en un cluster con carga irregular eso suele salir más barato que
mantener instancias encendidas al 20 % de uso, y te ahorras el parcheo del host. Pero en
un cluster con carga alta y sostenida la aritmética se invierte —pagas capacidad exacta
a precio de comodidad— y ahí ECS sobre EC2, con instancias bien llenas o con Spot, sale
claramente mejor.

Hay además dos casos donde EC2 no es una preferencia sino un requisito: cuando necesitas
algo del host que Fargate no expone (GPU, un demonio privilegiado, acceso al kernel) y
cuando necesitas exprimir la densidad de instancias reservadas que ya compraste.

---

## 12. ⚖ ECS vs EKS

| | ECS | EKS |
|---|---|---|
| Orquestador | AWS-native | Kubernetes |
| API Kubernetes | No | Sí |
| Complejidad | menor en muchos casos AWS-only | mayor |
| Ecosistema K8s | no | sí |
| Portabilidad conceptual K8s | menor | mayor |

Regla de arquitectura:

> No elijas EKS solamente porque Kubernetes sea popular. Elige EKS cuando necesitas Kubernetes/ecosistema/operación compatible con K8s.

> 💰 **Costo.** El control plane de EKS cuesta $0.10/h por cluster, exista o no un pod
> encima; ECS no cobra por el orquestador, solo por el cómputo. Ese número es el que
> decide muchas discusiones de "ECS o EKS" en empresas pequeñas, y es la razón por la
> que la serie práctica de este curso deja EKS fuera del tronco:
> [`L00` §3](l00-idea-lab-practico.md#3--el-caso-testigo-por-qué-no-montamos-un-microservicio-en-eks).

---

## 13. 🧱 Lambda

Servicio de ejecución de funciones administrado por AWS.

Modelo event-driven:

```text
Event
  │
  ▼
Lambda
  │
  ▼
resultado/otro servicio
```

Triggers comunes:

- API Gateway;
- SQS;
- EventBridge;
- S3;
- DynamoDB Streams.

Ideal para funciones event-driven, automatización y workloads que encajen bien con su modelo de ejecución. No sustituye automáticamente a todo servicio long-running.

---

## 14. 🧱 Lambda en profundidad

El nivel "qué es y cuándo usarlo" de la sección anterior alcanza para explicar el servicio. Defender un diseño con Lambda a nivel Architect exige un nivel más: qué pasa en el ciclo de vida real de una función bajo carga.

### Cold start

```text
Invocation
   │
   ├── execution environment ya inicializado (warm) → se reutiliza
   │
   └── no hay execution environment disponible (cold)
           │
           ├── descarga/inicialización del runtime
           ├── código de inicialización fuera del handler
           └── ejecución del handler
```

El cold start ocurre en la primera invocación tras crear un nuevo execution environment (deploy, escalado a más concurrencia, inactividad prolongada). Factores que lo afectan: runtime, tamaño del paquete, cantidad de código de inicialización y memoria asignada — más memoria implica más CPU proporcional, lo que también acelera la inicialización.

### Provisioned Concurrency

Mantiene un número de execution environments ya inicializados y listos, evitando el cold start en las invocaciones que caen dentro de esa concurrencia reservada.

Regla:

```text
On-Demand concurrency     → escala automáticamente, puede sufrir cold start
Provisioned Concurrency   → sin cold start dentro de lo reservado, pero deja de ser "costo cero en reposo"
```

### Layers

Empaquetan dependencias/librerías compartidas por separado del código de la función, para reutilizarlas entre varias funciones sin duplicar el paquete de despliegue.

```text
Function A ─┐
Function B ─┼── Layer (dependencias compartidas)
Function C ─┘
```

No resuelven versionado de dependencias por sí solas; siguen siendo responsabilidad del equipo mantenerlas actualizadas y compatibles.

### Container image packaging

Lambda permite empaquetar el código como imagen de container además del formato zip tradicional, útil para dependencias grandes o nativas (por ejemplo, librerías de machine learning).

No digas "Lambda con container image es lo mismo que ECS". Mejor:

> El empaquetado como container image sigue siendo el mismo modelo de ejecución event-driven de Lambda, con sus mismos límites de tiempo/memoria; el container es el formato de empaquetado, no cambia el modelo operativo.

### Límites de tiempo y memoria

```text
Timeout máximo configurable   → hasta 15 minutos
Memoria configurable          → rango entre 128 MB y 10 240 MB
CPU                            → escala proporcionalmente a la memoria asignada
Almacenamiento efímero (/tmp) → configurable de forma independiente
```

| Concepto | Qué resuelve | Trade-off |
|---|---|---|
| Cold start | — | Latencia extra en la primera invocación tras inactividad o escalado |
| Provisioned Concurrency | Elimina cold start para la concurrencia reservada | Se paga por capacidad reservada, se use o no |
| Layers | Reutilizar dependencias entre funciones | No resuelve el versionado; sigue siendo responsabilidad del equipo |
| Container image packaging | Empaquetar dependencias grandes/nativas | Mismo modelo de ejecución Lambda, no equivale a ECS |

Todo esto se practica contra una cuenta real —cold start medido, concurrencia reservada
en cero, event source mappings— en [`L03`](l03-backend-serverless-lambda-api-y-eventos.md).

---

## 15. 🧭 API Gateway — idea base

Amazon API Gateway permite publicar, proteger y administrar APIs HTTP/REST/WebSocket según el tipo de API.

Arquitectura serverless clásica:

```text
Client
  │ HTTPS
  ▼
API Gateway
  │
  ▼
Lambda
  │
  ▼
DynamoDB
```

También puede integrarse con backends HTTP y otros servicios AWS según el tipo de integración.

Conceptos de entrevista:

- endpoint administrado para APIs;
- routing/resources/routes según tipo de API;
- authorization/authentication integrations;
- throttling/quotas según capacidades;
- stages/deployment concepts según API type;
- integración con CloudWatch;
- no es un container orchestrator ni un load balancer genérico.

### API Gateway vs ALB

```text
API Gateway → API management, serverless/service integrations, API-specific controls
ALB         → L7 load balancing hacia targets dentro de arquitectura de aplicaciones
```

Para una REST API sobre ECS puedes usar ALB directamente o API Gateway delante cuando necesitas sus capacidades de API management/integración.

---

## 16. 🧱 Elastic Load Balancing

Los dos tipos fundamentales para este repaso:

```text
ALB → Layer 7
NLB → Layer 4
```

---

## 17. 🧱 ALB — Application Load Balancer

Entiende HTTP/HTTPS y puede enrutar según contenido de la solicitud.

Conceptos:

```text
ALB
├── Listener
├── Listener Rules
└── Target Groups
    ├── target
    └── target
```

### Listener

Ejemplo:

```text
HTTPS :443
```

### Listener rule

```text
/api/users/*  → TG-Users
/api/orders/* → TG-Orders
```

También puede enrutar por host header y otros criterios soportados.

### Target Group

Conjunto de destinos registrados. Los health checks se configuran a nivel de target group.

```text
TG-App
├── 10.0.2.10:8080
└── 10.0.4.15:8080
```

### Health Check

Ejemplo Spring Boot:

```text
GET /actuator/health
```

El ALB dirige tráfico a targets considerados healthy de acuerdo con la configuración.

---

## 18. 🧱 NLB — Network Load Balancer

Trabaja principalmente en Layer 4.

Casos:

- TCP;
- UDP;
- TLS;
- alto rendimiento y baja latencia;
- IPs estáticas/EIP por AZ cuando se necesita ese modelo.

---

## 19. ⚖ ALB vs NLB

| Necesidad | ALB | NLB |
|---|---:|---:|
| HTTP/HTTPS application routing | ✅ | |
| Routing por path | ✅ | |
| Routing por hostname | ✅ | |
| TCP/UDP genérico | | ✅ |
| Layer 4 | | ✅ |
| Layer 7 | ✅ | |
| REST/Spring Boot común | ✅ usual | caso específico |

La tabla dice qué hace cada uno; lo que decide en un diseño es qué pierdes al elegir. El
ALB entiende HTTP, y por eso puede enrutar por path y por host, terminar TLS, reescribir
cabeceras e integrarse con autenticación — pero para hacerlo tiene que leer y reconstruir
cada request, lo que añade latencia y le impide hablar protocolos que no sean HTTP. El
NLB no entiende nada de lo que transporta, y justamente por eso sostiene millones de
conexiones con latencia mínima, admite TCP y UDP, y puede darte **IPs estáticas por AZ**,
que es lo que necesitas cuando alguien tiene que meter tu servicio en la allowlist de su
firewall.

> 🧠 **Modelo mental.** ALB si tu decisión de enrutado depende de lo que dice la request;
> NLB si solo depende de a dónde va. Para una API REST detrás de ECS, la respuesta por
> defecto es ALB, y desviarse de ella exige nombrar cuál de las tres razones —protocolo
> no HTTP, latencia extrema o IP fija— lo justifica.

---

## 20. 🧭 Arquitectura containerizada típica

```text
Internet
   │
   ▼
Route 53
   │
   ▼
ALB
   │
   ├─────────────┐
   ▼             ▼
ECS Task       ECS Task
Fargate        Fargate
AZ-a           AZ-b
   │             │
   └──────┬──────┘
          ▼
      RDS/Aurora
```

CI/CD conceptual:

```text
source
  │
  ▼
build
  │
  ▼
Docker image
  │
  ▼
ECR
  │
  ▼
ECS Service deployment
```

---

## 🧠 Preguntas rápidas

1. ¿EC2 vs container?
2. ¿AMI vs EBS?
3. ¿Scale up vs scale out?
4. ¿ECR ejecuta containers?
5. ¿Task Definition vs Task vs Service?
6. ¿Fargate reemplaza a ECS?
7. ¿ECS vs EKS?
8. ¿Cuándo usarías Lambda en vez de un servicio ECS permanente?
9. ¿API Gateway vs ALB?
10. ¿ALB vs NLB?
11. ¿Qué ocurre cuando falla un health check del target?
12. ¿Qué es un cold start y qué lo dispara?
13. ¿Provisioned Concurrency elimina el costo de Lambda en reposo?
14. ¿Qué resuelven las Layers y qué NO resuelven?
15. ¿Empaquetar Lambda como container image la vuelve equivalente a ECS?

---

## 📚 Referencias oficiales

- EC2 concepts: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html
- EC2 instance types: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
- EBS: https://docs.aws.amazon.com/ebs/latest/userguide/what-is-ebs.html
- ECS: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html
- Fargate: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html
- ECR: https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html
- EKS: https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html
- Lambda: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- Lambda execution environment / cold start: https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtime-environment.html
- Lambda Provisioned Concurrency: https://docs.aws.amazon.com/lambda/latest/dg/provisioned-concurrency.html
- Lambda Layers: https://docs.aws.amazon.com/lambda/latest/dg/chapter-layers.html
- Lambda container images: https://docs.aws.amazon.com/lambda/latest/dg/images-create.html
- Lambda quotas: https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html
- API Gateway: https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html
- ALB: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html
- ALB target groups: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html
- NLB: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html
- Purchase options (On-Demand, Spot, Reserved, Savings Plans): https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-purchasing-options.html
- AMI: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html
- EC2 Auto Scaling: https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html
- ECS Task Definitions: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html
