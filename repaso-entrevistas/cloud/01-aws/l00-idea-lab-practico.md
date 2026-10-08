# L00 — Introducción a la serie práctica: qué se hace en la nube y qué no

> **Objetivo:** entender qué vas a construir en los labs `L01`–`L04`, por qué el
> laboratorio incluye exactamente esos servicios y no otros, cuánto va a costar y
> cómo se garantiza que no quede nada encendido.
> **Se asume leído:** nada. Este es el primer documento de la serie práctica.
> **Precios de referencia:** `us-east-1`, orden de magnitud. Verifica siempre en la
> [calculadora oficial](https://calculator.aws/) antes de encender algo.
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial y precios de AWS
> verificados en esa fecha).

**Salto rápido:** [Las dos restricciones](#1--las-dos-restricciones-de-partida) ·
[Doctrina de reparto](#2--la-doctrina-de-reparto-qué-se-paga-y-qué-se-practica-en-local) ·
[Por qué no un microservicio en EKS](#3--el-caso-testigo-por-qué-no-montamos-un-microservicio-en-eks) ·
[Qué entra y qué no](#4--el-catálogo-completo-de-exclusiones) ·
[El sistema del lab](#5--el-sistema-que-vas-a-construir) ·
[Presupuesto](#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas) ·
[Cómo recorrer la serie](#7--cómo-recorrer-la-serie) ·
[Emuladores](#8--emuladores-locales-qué-sirve-y-qué-miente) ·
[Ampliaciones](#9--ampliaciones-opcionales) ·
[Preguntas](#-preguntas-rápidas)

Este documento no es material de estudio para la entrevista: es el contrato de la
serie práctica. Define qué entra en el laboratorio de pago, **qué queda fuera y por
qué**, el presupuesto y cómo se conecta con el resto del repositorio. Si solo vas a
leer un documento antes de abrir una cuenta de AWS, que sea este.

---

## 1. 🧭 Las dos restricciones de partida

Todo el diseño de la serie sale de dos hechos incómodos. Conviene tenerlos delante
antes de la primera línea de la CLI.

**No hay free tier de doce meses.** Desde el 15 de julio de 2025, una cuenta nueva no
recibe doce meses de recursos gratis: recibe créditos ($100, ampliables a $200), el
plan Free se cierra a los seis meses o cuando los créditos vencen, y lo único
permanentemente gratuito son las cuotas *always free* de una treintena de servicios.
Las cuentas creadas antes de esa fecha conservan las ofertas de doce meses hasta que
expiran.

> 📝 **Contexto.** Este cambio es reciente y muchísimo material de estudio en
> internet —tutoriales, cursos, respuestas de foros— sigue asumiendo el free tier
> viejo y te dice alegremente "levanta una `t2.micro`, es gratis". Ya no lo es en una
> cuenta nueva. Si sigues un tutorial de 2023 al pie de la letra, pagas.

En cualquiera de los dos casos la premisa del lab es la misma: **cada hora encendida
se paga**.

**El lab acompaña una búsqueda de empleo.** No hay presupuesto de empresa ni tiempo
ilimitado. El laboratorio tiene que poder encenderse en minutos, practicarse en una
sesión y destruirse con certeza. Un lab que tarda tres horas en levantarse se hace
una vez y nunca más, y un lab que no sabes destruir del todo es una suscripción
mensual que no pediste.

De ahí sale la tesis de la serie:

```text
El laboratorio no se mide por lo que despliegas.
Se mide por lo que destruyes y vuelves a levantar sin intervención manual.
```

---

## 2. ⚖ La doctrina de reparto: qué se paga y qué se practica en local

Aquí está la decisión de diseño que explica todo lo demás, y es la regla que más
gente hace al revés cuando monta su primer laboratorio de AWS.

> 🧠 **Modelo mental.** En la nube se practica lo que **solo** existe en la nube. Todo
> lo demás se practica en local con contenedores: gratis, con un ciclo de iteración de
> segundos en vez de minutos, y sin miedo a olvidarse algo encendido.

Un tema entra en el laboratorio de pago solo si cumple **al menos una** de estas
cuatro condiciones:

| Criterio | Ejemplos |
|---|---|
| Lo hace cumplir AWS y nadie más | IAM, policy evaluation, routing de VPC |
| El fallo real difiere del fallo emulado | `ROLLBACK_COMPLETE`, `DELETE_FAILED`, event source mappings, throttling |
| Solo se conoce pagando | Cost Explorer, cost allocation tags, budgets |
| Es la costura entre tu código y AWS | Execution role, resource-based policy, IRSA |

La contrapartida de esa regla es lo que hace útil al laboratorio:

> Regla de arquitectura: los emuladores son andamio de desarrollo, no instrumento de
> enseñanza. Lo que un emulador te quita —IAM que sí deniega, red que sí enruta,
> fallos que sí ocurren, una factura— es exactamente lo que AWS enseña.

Y al revés: lo que AWS **no** te enseña mejor que un contenedor local no merece que le
pagues. Correr Postgres en RDS no te enseña Postgres. Correr un contenedor en Fargate
no te enseña qué es un contenedor. Desplegar un microservicio en EKS no te enseña
Kubernetes. En los tres casos estás pagando por hora para practicar algo que ya
podías practicar gratis, y encima con un feedback loop diez veces más lento.

---

## 3. ⚖ El caso testigo: por qué no montamos un microservicio en EKS

Es la pregunta que más aparece cuando alguien ve el índice de la serie: *"¿un lab de
AWS sin un microservicio corriendo en Kubernetes?"*. Sí, y vale la pena desarmarla
entera, porque el razonamiento se aplica igual a ECS, a RDS y a media docena de
servicios más.

### 3.1 Qué esperas aprender y qué aprendes de verdad

Cuando imaginas ese lab, la lista mental de aprendizajes suele ser esta:

```text
Lo que crees que vas a aprender montando un microservicio en EKS
──────────────────────────────────────────────────────────────────
  1. Contenedores y su ciclo de vida        ← ya lo aprendes en local
  2. Deployments, Services, Ingress          ← ya lo aprendes en local (kind)
  3. Rolling updates, readiness, liveness    ← ya lo aprendes en local
  4. ConfigMaps, Secrets, resource limits    ← ya lo aprendes en local
  5. HPA y escalado                          ← ya lo aprendes en local
  6. IRSA / Pod Identity                     ← esto SÍ es de AWS
  7. AWS Load Balancer Controller            ← esto SÍ es de AWS
  8. VPC CNI y agotamiento de IPs            ← esto SÍ es de AWS
```

De ocho puntos, cinco los practicas gratis con `kind` o `minikube` en tu portátil, en
un cluster que levanta en cuarenta segundos y que puedes destruir y recrear veinte
veces en una tarde. Tres son específicos de AWS.

Ahora el precio. El control plane de EKS cuesta **$0.10/hora**, y ese reloj corre
tengas o no algo desplegado encima. A eso le sumas los nodos —Fargate o EC2— y, si el
Ingress crea un ALB, otros **~$0.0225/hora** más las LCU. Una sesión de tres horas
ronda los **$0.70**, y una semana olvidado son unos **$17** solo de control plane.

> 💰 **Costo.** EKS es el único servicio del temario que te cobra por existir aunque
> no lo uses. Un cluster vacío, sin un solo pod, sigue facturando $0.10/h. Es el
> recurso huérfano más caro que puedes dejarte olvidado en una cuenta de práctica.

### 3.2 El cálculo que decide

Ponlo en la balanza:

- **Aprendizaje específico de AWS por sesión:** tres conceptos (IRSA, el Load Balancer
  Controller, el VPC CNI).
- **Costo:** ~$0.70 por sesión, con riesgo de un olvido que cuesta veinte veces eso.
- **Latencia de iteración:** entre 10 y 15 minutos para crear un cluster, y otro tanto
  para borrarlo. En `kind`, cuarenta segundos.
- **Riesgo de teardown incompleto:** alto. Un cluster de EKS arrastra nodegroups,
  security groups creados por el controller, ENIs, un ALB y volúmenes EBS de los PVC,
  y varios de ellos **no se borran** cuando borras el cluster.

La conclusión no es "EKS no importa". Es que **EKS merece un drill dirigido de tres
horas al final del recorrido, no ser el escenario donde practicas el resto**. Los tres
conceptos que sí son de AWS caben en una sesión enfocada, con el teardown escrito
antes que el despliegue. Montar el microservicio de negocio encima solo añade costo,
tiempo de espera y superficie de olvido, sin añadir un solo aprendizaje de AWS.

Por eso EKS aparece en §9 como ampliación opcional, con su precio declarado, y no en
el tronco de `L01`–`L04`.

### 3.3 El mismo razonamiento, aplicado en general

La pregunta que decide cualquier caso dudoso es siempre esta:

> Regla de entrevista: *"¿Qué me enseña este servicio que no me enseñe el mismo
> software corriendo en un contenedor en mi máquina?"*. Si la respuesta cabe en dos
> conceptos, es un drill de una sesión. Si la respuesta es "nada", es un contenedor
> local. Si la respuesta es "el modelo entero", entonces sí es un lab de nube.

Y es, de paso, una respuesta excelente en una entrevista de arquitectura. Quien puede
justificar por qué **no** llevó algo a un servicio administrado demuestra criterio de
costo; quien lleva todo a Kubernetes porque sí, demuestra lo contrario.

---

## 4. ⚖ El catálogo completo de exclusiones

Lo que sí entra al laboratorio de pago, con lo que enseña cada cosa:

| Servicio | Qué enseña que no se aprende en local |
|---|---|
| CloudFormation + AWS CLI | Ciclo de vida real de un stack, change sets, drift, borrado con dependencias |
| IAM | Trust policy frente a permissions policy, `AccessDenied` real, simulador |
| Lambda | Modelo de ejecución, cold start, concurrencia, límites, facturación |
| API Gateway (HTTP API) | Formato de payload, integración proxy, resource-based policy |
| DynamoDB + Streams | Escritura condicional, TTL, event source mapping |
| SQS + DLQ + EventBridge | Visibility timeout, redrive, fallos parciales de lote |
| CloudWatch, X-Ray, CloudTrail | EMF, Logs Insights, alarmas con datos faltantes, auditoría |
| Cost Explorer, Budgets, tagging | La factura y su rastreo |

Y lo que queda fuera, cada uno con su razón y su destino. Ninguna exclusión se deja
sin justificar: una exclusión explicada es contenido, una exclusión silenciosa es un
hueco del temario.

**EKS.** Desarrollado en §3. El control plane cuesta $0.10/h y no enseña Kubernetes;
lo específico de AWS —IRSA, Load Balancer Controller, VPC CNI— cabe en un drill.
→ `kind` en local, más el drill de §9.

**ECS y Fargate.** El modelo de contenedores ya se domina en local. Lo que ECS añade
sobre eso es la definición de tarea, el registro en el target group y el health check
del ALB: tres conceptos, un drill. → Contenedores en local, más el drill de §9.

**RDS y Aurora.** RDS es PostgreSQL o MySQL con un sobre de gestión encima. El motor
se aprende mejor en un contenedor, donde puedes romperlo sin consecuencias; el sobre
—subnet groups, parameter groups, snapshot y restore, la ventana de mantenimiento— es
un drill de una sesión. Una `db.t4g.micro` ronda los $0.016/h, más el almacenamiento
que sigue cobrando aunque la instancia esté parada. → Postgres en contenedor, más el
drill de §9.

**Amazon MQ y MSK.** Un broker administrado enseña justamente aquello que no
administras. La semántica de ActiveMQ o de Kafka —particiones, consumer groups,
acks— se aprende idéntica en un contenedor, y ahí sí puedes matar un broker a mano
para ver qué pasa. → ActiveMQ, Artemis o Redpanda en contenedor.

**EC2 con un monolito JEE.** Alto costo en tiempo, bajísimo aprendizaje de AWS: pasas
la sesión peleando con el classpath, no con la nube. → Contenedor o VM local.

**Kinesis.** Un stream on-demand cuesta del orden de $0.04/h por existir, para enseñar
una semántica de log ordenado con múltiples lectores que Redpanda o Kafka enseñan
igual de bien en local. Lo específico de AWS —el enhanced fan-out, la integración con
Lambda como event source— se toca conceptualmente en [`07`](07-mensajeria-eventos-integracion.md).
→ Redpanda o Kafka en local.

**Frontend.** Cero aprendizaje de cloud. → Fuera de alcance del repositorio.

**NAT Gateway.** $0.045/h más $0.045 por GB procesado, y es completamente evitable:
el lab no mete las Lambdas en la VPC, y cuando algo necesita hablar con S3 o DynamoDB
desde dentro de una VPC se usan Gateway endpoints, que son gratis. Es la trampa de
costo número uno de las cuentas de práctica. → No se usa; el concepto se explica en
[`01`](01-infraestructura-global-y-redes.md) y se practica sin cargo en el drill de
VPC de §9.

**Jenkins, SonarQube, Prometheus, Grafana.** No son servicios de AWS. Pagar EC2 para
correrlos es pagar por un contenedor con pasos extra. → Contenedores en local.

---

## 5. 🧱 El sistema que vas a construir

Inventario de una cadena de tiendas. Solo backend, íntegramente serverless, sin una
sola línea de frontend y sin un solo recurso que cobre por hora.

```text
  curl
    │
    ▼
  API Gateway (HTTP API)
    │
    ▼
  inv-lab-api (Lambda)  ──►  DynamoDB inv-lab-events ──► Stream
                                                       │
                                                 inv-lab-projector (Lambda)
                                                       │
                                                 SQS ──► DLQ
                                                       │
                                                 inv-lab-alert (Lambda) ──► SNS
```

Es deliberadamente pequeño, y cada pieza está ahí por un motivo concreto:

- **API Gateway → Lambda** es la costura entre tu código y AWS: quién invoca a quién,
  con qué permiso y con qué formato de payload.
- **La escritura en DynamoDB** es donde practicas la escritura condicional y la
  idempotencia, que es la respuesta a la pregunta de entrevista más frecuente sobre
  procesamiento asíncrono.
- **El Stream y el event source mapping** son puro AWS: no hay emulador que reproduzca
  fielmente el reintento de un lote fallido ni el `bisect on function error`.
- **SQS con su DLQ** te deja provocar un poison message a propósito y ver a dónde va.
- **SNS al final** cierra el fan-out sin añadir infraestructura que cobre.

El flujo cubre así casi todo el vocabulario de mensajería y eventos de
[`04`](04-dynamodb-nosql.md) y [`07`](07-mensajeria-eventos-integracion.md), que es
justamente lo que se pregunta en una entrevista de arquitectura backend.

---

## 6. 💰 Presupuesto, y de dónde sale el gasto que no esperabas

| Concepto | Costo |
|---|---|
| [`L01`](l01-preparacion-cli-y-blindaje-de-costos.md) — preparación, budgets, tags | $0.00 |
| [`L02`](l02-cloudformation-desde-la-cli.md) — CloudFormation (tabla y bucket vacíos) | $0.00 |
| [`L03`](l03-backend-serverless-lambda-api-y-eventos.md) — backend serverless completo | centavos |
| [`L04`](l04-observabilidad-y-destruccion-verificada.md) — observabilidad y teardown | centavos |
| **Serie completa, repetida varias veces** | **menos de $1** |

Ahora la parte importante, porque el gasto real de una cuenta de práctica **nunca
viene del lab en sí**. Viene de tres sitios:

1. **Log groups sin retención.** Cada Lambda crea su log group automáticamente y por
   defecto retiene los logs **para siempre**. No cuesta casi nada al principio y no
   deja de crecer nunca. Se cubre en [`L04`](l04-observabilidad-y-destruccion-verificada.md).
2. **Recursos huérfanos de sesiones anteriores.** Lo que sobrevive a un `delete-stack`:
   buckets con `DeletionPolicy: Retain`, snapshots, ENIs, volúmenes EBS sueltos. El
   catálogo completo está en [`A02`](a02-costos-trampas-y-recursos-huerfanos.md).
3. **Drills opcionales que se quedan encendidos.** Los de §9. Un cluster de EKS
   olvidado un fin de semana son ~$5; olvidado un mes, ~$73.

Los tres tienen su barrido verificado en [`L04`](l04-observabilidad-y-destruccion-verificada.md)
y su catálogo de referencia en [`A02`](a02-costos-trampas-y-recursos-huerfanos.md), y
el blindaje preventivo —budgets, anomaly detection, tags de asignación— se monta en
[`L01`](l01-preparacion-cli-y-blindaje-de-costos.md) antes de crear el primer recurso.

---

## 7. 🧭 Cómo recorrer la serie

Los labs son **acumulativos y en orden** —[`L01`](l01-preparacion-cli-y-blindaje-de-costos.md) →
[`L02`](l02-cloudformation-desde-la-cli.md) →
[`L03`](l03-backend-serverless-lambda-api-y-eventos.md) →
[`L04`](l04-observabilidad-y-destruccion-verificada.md)—. Cada uno asume el estado que
dejó el anterior:

```text
L01  identidad, perfiles, budgets, tags        $0.00     60–90 min
  │  deja: la cuenta blindada, nada desplegado
  ▼
L02  CloudFormation desde la CLI               $0.00     2–3 h
  │  deja: el stack inv-lab-data vacío (tabla + bucket + parámetro SSM)
  ▼
L03  Lambda, HTTP API, DynamoDB Streams, SQS   centavos  3–4 h
  │  deja: el sistema de §5 corriendo
  ▼
L04  observabilidad y destrucción verificada   centavos  2–3 h
     deja: la cuenta vacía y verificada
```

Los dos apéndices se consultan en cualquier momento y no tienen prerrequisitos:
[`A01`](a01-cli-de-supervivencia.md) para la mecánica de la CLI —perfiles, JMESPath,
paginación, waiters— y [`A02`](a02-costos-trampas-y-recursos-huerfanos.md) para el
catálogo de qué cobra y qué sobrevive a un borrado.

**Lo que necesitas antes de empezar [`L01`](l01-preparacion-cli-y-blindaje-de-costos.md):** una cuenta de AWS con acceso a la
información de facturación, la AWS CLI v2 instalada, un método de pago válido y
—esto no es negociable— la disposición a hacer el teardown al final de cada sesión
aunque sean las once de la noche.

**Cuánto teórico conviene llevar leído.** Los labs se pueden hacer sin haber leído los
documentos teóricos, pero rinden mucho más con [`05`](05-seguridad-iam-kms-secretos.md)
(IAM) y [`09`](09-cloudformation-iac.md) (CloudFormation) delante.
[`L03`](l03-backend-serverless-lambda-api-y-eventos.md) se apoya directamente en
[`04`](04-dynamodb-nosql.md) y [`07`](07-mensajeria-eventos-integracion.md);
[`L04`](l04-observabilidad-y-destruccion-verificada.md), en
[`08`](08-observabilidad-auditoria-gobierno.md).

---

## 8. 🧪 Emuladores locales: qué sirve y qué miente

Para correr el sistema en local sin cuenta de AWS. La columna que importa es la de
fidelidad: usar un emulador creyendo que se comporta igual que el servicio real es la
forma más común de aprender algo falso.

| Servicio AWS | Sustituto local | Fidelidad |
|---|---|---|
| S3 | MinIO | Alta. API real. |
| DynamoDB | DynamoDB Local (oficial) | Alta para la API; sin throttling ni particiones reales. |
| SQS | ElasticMQ o LocalStack | Media. La API sí; el visibility timeout bajo carga, no. |
| Lambda y API Gateway | AWS SAM CLI local | Alta. Usa las imágenes de runtime reales. |
| Step Functions | Step Functions Local (oficial) | Alta. |
| Kinesis | LocalStack o Redpanda | Baja para la API; alta para la semántica si usas Redpanda. |
| RDS | Postgres en contenedor | No aplica: el motor es el mismo; lo administrado no se emula. |
| Cognito | Keycloak | Sirve para OIDC y JWT como concepto, no como producto. |
| IAM, VPC, CloudFormation | Ninguno | No se emulan de forma útil. |

> 💡 **Truco.** Corre la misma suite de pruebas contra el emulador y contra AWS real, y
> anota cada diferencia que encuentres. Esa lista —"qué me mintió el emulador"— es
> material de entrevista de primera calidad, porque demuestra que entiendes el
> servicio y no solo su API.

---

## 9. 🧪 Ampliaciones opcionales

Drills sueltos, **no acumulativos**, que se encienden y se destruyen en la misma
sesión. Cada uno cubre exactamente los conceptos que §3 y §4 identificaron como
"específicos de AWS" en un servicio excluido del tronco. Cada uno declara su costo
para una sesión de tres horas.

| Drill | Qué añade que no aprendes en local | Costo/3 h |
|---|---|---|
| ALB + Fargate + RDS | Target groups, health checks, deregistration delay, subnet groups, snapshot y restore | ~$0.20 |
| EKS, solo la costura | IRSA/Pod Identity, AWS Load Balancer Controller, agotamiento de IPs del VPC CNI | ~$0.70 |
| VPC con endpoints | Routing, SG frente a NACL, Flow Logs, Reachability Analyzer | ~$0.00 |
| Cognito + autorizador | User Pool, JWT, autorización en API Gateway | ~$0.00 |
| Step Functions | Reintentos, `Catch`, paralelismo, compensación | ~$0.00 |

> ⚠️ El drill de EKS es el único de la lista con un recurso que cobra por hora de forma
> significativa, y el único cuyo teardown deja residuos si lo haces mal. Se enciende
> **con el teardown escrito antes que el despliegue**, y se verifica con el barrido por
> tags de [`L04`](l04-observabilidad-y-destruccion-verificada.md) antes de cerrar la
> sesión.

---

## 10. 🧭 Relación con el resto del repositorio

```text
docker-container-legacy   → cómo funciona un contenedor por dentro
                            namespaces, cgroups, overlayfs, capas, PID 1

laboratorio local          → cómo funcionan muchos contenedores juntos
(en preparación)             Kubernetes, mensajería, observabilidad, pipelines

repaso-aws-entrevistas     → qué cambia cuando el dueño de la infraestructura
+ serie práctica L01-L04     es otro: identidad, red, IaC, servicios
                             administrados y costo
```

Cada nivel explica los fallos del siguiente, y por eso el reparto de §2 funciona.
Quien entendió cgroups reconoce un `OOMKilled` sin buscarlo. Quien operó Kubernetes
en local solo tiene que aprender la parte específica de AWS cuando llega a EKS —que
son, exactamente, los tres conceptos del drill.

---

## 11. 🧭 Decisiones abiertas y ampliaciones naturales

Cuatro cosas que la serie deja deliberadamente abiertas, y que son las extensiones más
naturales cuando termines el tronco:

1. **Región.** La serie asume `us-east-1`. Repetir [`L03`](l03-backend-serverless-lambda-api-y-eventos.md) en `sa-east-1` y comparar la
   factura sería un ejercicio de FinOps de media hora.
2. **Empaquetado de Lambda.** Los labs usan `Code.ZipFile` inline para evitar un
   bucket de artefactos y un paso de build. Migrar a AWS SAM con dependencias reales
   es la ampliación natural de [`L03`](l03-backend-serverless-lambda-api-y-eventos.md).
3. **Repositorio de código.** Los templates y los scripts de teardown de esta serie
   son un portafolio razonable por sí solos: publicarlos en un repo con su README es
   media hora de trabajo y algo concreto que enseñar en una entrevista.
4. **Drills opcionales.** Los cinco de §9 están descritos pero no desarrollados paso a
   paso. Cuál de ellos merece convertirse en un `L05` depende de a qué apunte tu
   siguiente entrevista.

---

## 🧠 Preguntas rápidas

1. ¿Qué condición tiene que cumplir un tema para entrar al laboratorio de pago?
2. ¿Por qué el curso practica Kubernetes en local y no en EKS?
3. ¿Cuánto cuesta un cluster de EKS completamente vacío y por qué?
4. De los ocho aprendizajes que se esperan de "un microservicio en EKS", ¿cuáles son realmente específicos de AWS?
5. ¿Qué pregunta decide si un servicio dudoso merece un lab de nube, un drill o un contenedor local?
6. ¿Por qué el laboratorio evita el NAT Gateway en lugar de enseñarlo?
7. ¿De dónde sale el gasto real de una cuenta de práctica, si no es del lab?
8. ¿Qué le falta a DynamoDB Local respecto de DynamoDB real, y por qué importa?
9. ¿Por qué el lab usa DynamoDB Streams en vez de Kinesis para la proyección?
10. ¿Qué estado deja `L02` y qué asume `L03` sobre él?
11. ¿Por qué el teardown de un drill de EKS se escribe antes que el despliegue?
12. ¿Qué cambió en el free tier de AWS en julio de 2025 y cómo afecta a un tutorial de 2023?

---

## 📚 Referencias oficiales

- AWS Free Tier y sus términos: https://aws.amazon.com/free/ · https://aws.amazon.com/free/terms/
- Cambio del Free Tier (julio de 2025): https://aws.amazon.com/about-aws/whats-new/2025/07/aws-free-tier-credits-month-free-plan/
- AWS Pricing Calculator: https://calculator.aws/
- Amazon EKS pricing: https://aws.amazon.com/eks/pricing/
- Amazon EKS — IAM roles for service accounts (IRSA): https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
- AWS Fargate pricing: https://aws.amazon.com/fargate/pricing/
- Amazon RDS pricing: https://aws.amazon.com/rds/pricing/
- Elastic Load Balancing pricing: https://aws.amazon.com/elasticloadbalancing/pricing/
- Amazon VPC pricing (NAT Gateway y endpoints): https://aws.amazon.com/vpc/pricing/
- Gateway endpoints para S3 y DynamoDB: https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html
- Amazon Kinesis Data Streams pricing: https://aws.amazon.com/kinesis/data-streams/pricing/
- Amazon MQ pricing: https://aws.amazon.com/amazon-mq/pricing/
- AWS Lambda pricing: https://aws.amazon.com/lambda/pricing/
- Amazon DynamoDB pricing: https://aws.amazon.com/dynamodb/pricing/
- AWS SAM: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html
- DynamoDB Local: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html
- AWS Step Functions Local: https://docs.aws.amazon.com/step-functions/latest/dg/sfn-local.html
- Etiquetado de recursos y Resource Groups Tagging API: https://docs.aws.amazon.com/tag-editor/latest/userguide/tagging.html

### Herramientas de terceros (opcional)

No forman parte del material de referencia del curso; se listan solo porque el
laboratorio local las utiliza.

- LocalStack: https://docs.localstack.cloud/
- MinIO: https://github.com/minio/minio
- ElasticMQ: https://github.com/softwaremill/elasticmq
- Redpanda: https://docs.redpanda.com/home/
- Keycloak: https://www.keycloak.org/documentation
- kind (Kubernetes in Docker): https://kind.sigs.k8s.io/
