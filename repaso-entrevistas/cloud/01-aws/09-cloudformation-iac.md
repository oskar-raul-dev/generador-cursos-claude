# 09 — AWS CloudFormation e Infrastructure as Code

> **Objetivo:** leer un template ajeno sin ayuda, anticipar qué recurso se va a
> reemplazar en un update y saber por qué un stack puede quedar atascado.
> **Se asume leído:** [`01`](01-infraestructura-global-y-redes.md),
> [`03`](03-almacenamiento-y-bases-sql.md) y [`04`](04-dynamodb-nosql.md) — los recursos
> que aparecen en los ejemplos.
> **Se conecta con:** [`12`](12-orquestacion-y-cicd.md) (el pipeline que lo despliega) y
> [`L02`](l02-cloudformation-desde-la-cli.md), donde se rompe a propósito.
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Qué es Infrastructure as Code](#1--qué-es-infrastructure-as-code) · [Qué es CloudFormation](#2--qué-es-cloudformation) · [Template vs Stack](#3--template-vs-stack) · [YAML vs JSON](#4--yaml-vs-json) · [Anatomía de un template](#5--anatomía-de-un-template) · [Resources](#6--resources) · [Parameters](#7--parameters) · [`Ref`](#8--ref) · [`Fn::GetAtt` / `!GetAtt`](#9--fngetatt--getatt) · [`Fn::Sub` / `!Sub`](#10--fnsub--sub) · [`Fn::Join`](#11--fnjoin) · [Pseudo Parameters](#12--pseudo-parameters) · [Mappings](#13--mappings) · [Conditions](#14--conditions) · [Outputs](#15--outputs) · [Exports / ImportValue](#16--exports--importvalue) · [Dependencias implícitas](#17--dependencias-implícitas) · [`DependsOn`](#18--dependson) · [DeletionPolicy](#19--deletionpolicy) · [UpdateReplacePolicy](#20--updatereplacepolicy) · [Stack Create / Update / Delete](#21--stack-create--update--delete) · [Change Sets](#22--change-sets) · [Drift](#23--drift) · [Rollback](#24--rollback) · [Nested Stacks](#25--nested-stacks) · [StackSets — concepto](#26--stacksets--concepto) · [Transform / SAM](#27--transform--sam) · [Ejemplo mínimo — S3](#28--ejemplo-mínimo--s3) · [Ejemplo — VPC y Security Group](#29--ejemplo--vpc-y-security-group) · [Ejemplo — DynamoDB](#30--ejemplo--dynamodb) · [Ejemplo — Condition](#31--ejemplo--condition) · [Errores comunes](#32--errores-comunes) · [CloudFormation vs Terraform — respuesta corta](#33--cloudformation-vs-terraform--respuesta-corta) · [Workflow recomendado](#34--workflow-recomendado) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

## 1. 🧭 Qué es Infrastructure as Code

En vez de crear recursos manualmente en consola:

```text
Click → click → click → “¿cómo hicimos prod?”
```

defines estado deseado en archivos versionables:

```text
Git
└── infrastructure.yaml
```

Beneficios:

- repetibilidad;
- revisión por Pull Request;
- trazabilidad;
- automatización;
- múltiples entornos;
- reducción de snowflake environments;
- recuperación/recreación más consistente.

---

## 2. 🧭 Qué es CloudFormation

Servicio IaC declarativo nativo de AWS.

Tú defines un **template** y CloudFormation administra recursos como una unidad denominada **stack**.

```text
Template YAML/JSON
       │
       ▼
CloudFormation
       │
       ▼
Stack
├── VPC
├── Security Group
├── ECS Service
└── S3 Bucket
```

---

## 3. ⚖ Template vs Stack

### Template

Documento que describe infraestructura deseada.

### Stack

Instancia desplegada de ese template + parámetros/estado administrado.

```text
app-infra.yaml
   │
   ├── Stack dev
   ├── Stack qa
   └── Stack prod
```

No necesariamente debes reutilizar exactamente el mismo template para todo, pero Parameters/Conditions ayudan a hacerlo flexible.

---

## 4. ⚖ YAML vs JSON

CloudFormation admite ambos.

Para humanos suele preferirse YAML por legibilidad.

```yaml
Resources:
  AppBucket:
    Type: AWS::S3::Bucket
```

JSON equivalente es más verboso.

---

## 5. 🧱 Anatomía de un template

Secciones principales:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: ...
Metadata: ...
Parameters: ...
Rules: ...
Mappings: ...
Conditions: ...
Transform: ...
Resources: ...        # REQUIRED
Outputs: ...
```

Según la documentación actual, **Resources es la sección obligatoria**.

---

## 6. 🧱 Resources

Corazón del template.

Ejemplo:

```yaml
Resources:
  LogsBucket:
    Type: AWS::S3::Bucket
    Properties:
      VersioningConfiguration:
        Status: Enabled
```

### Logical ID

```text
LogsBucket
```

Nombre interno del recurso dentro del template.

### Resource Type

```text
AWS::S3::Bucket
AWS::EC2::VPC
AWS::DynamoDB::Table
AWS::IAM::Role
```

CloudFormation genera/usa el physical resource correspondiente al desplegar.

---

## 7. 🧱 Parameters

Entradas del template en create/update.

```yaml
Parameters:
  Environment:
    Type: String
    AllowedValues:
      - dev
      - qa
      - prod
    Default: dev
```

Uso:

```yaml
Tags:
  - Key: Environment
    Value: !Ref Environment
```

Beneficio:

```text
template reusable
≠ hardcodear cada valor
```

No conviertas todo en Parameter. Algunos valores se derivan mejor mediante mappings, conditions, SSM parameters o referencias a otros recursos.

---

## 8. 🧱 `Ref`

Función intrínseca muy común.

```yaml
!Ref Environment
```

Puede devolver:

- valor de un Parameter;
- identificador/value definido por el tipo de resource.

Ejemplo:

```yaml
VpcId: !Ref AppVpc
```

---

## 9. 🧱 `Fn::GetAtt` / `!GetAtt`

Obtiene un atributo expuesto por un resource.

```yaml
!GetAtt AppLoadBalancer.DNSName
```

Diferencia mental:

```text
Ref    → valor principal/ID según recurso
GetAtt → atributo específico
```

Consulta la referencia del resource type para saber qué devuelve cada uno.

---

## 10. 🧱 `Fn::Sub` / `!Sub`

Interpolación de strings.

```yaml
BucketName: !Sub '${AWS::AccountId}-${AWS::Region}-${Environment}-logs'
```

Útil con pseudo parameters y referencias.

---

## 11. 🧱 `Fn::Join`

Une valores.

```yaml
Value: !Join
  - '-'
  - - app
    - !Ref Environment
```

A menudo `!Sub` resulta más legible para strings con variables, pero `Join` sigue siendo fundamental.

---

## 12. 🧱 Pseudo Parameters

CloudFormation proporciona valores sin declararlos como Parameter.

Ejemplos importantes:

```text
AWS::AccountId
AWS::Region
AWS::StackName
AWS::Partition
AWS::NoValue
```

Ejemplo:

```yaml
!Sub 'arn:${AWS::Partition}:s3:::${BucketName}'
```

`AWS::NoValue` es útil con Conditions para omitir una propiedad.

---

## 13. 🧱 Mappings

Lookup tables estáticas.

Ejemplo:

```yaml
Mappings:
  RegionConfig:
    us-east-1:
      InstanceType: t3.micro
    eu-west-1:
      InstanceType: t3.small
```

Consulta:

```yaml
!FindInMap [RegionConfig, !Ref 'AWS::Region', InstanceType]
```

Útil cuando el valor depende de una matriz conocida.

---

## 14. 🧱 Conditions

Crean/configuran recursos según una condición.

```yaml
Parameters:
  Environment:
    Type: String

Conditions:
  IsProd: !Equals [!Ref Environment, prod]
```

Uso:

```yaml
Resources:
  ProductionBucket:
    Type: AWS::S3::Bucket
    Condition: IsProd
```

CloudFormation evalúa conditions al crear/actualizar. Una condition que pasa de true a false puede provocar eliminación de recursos asociados; revisa Change Sets antes de ejecutar cambios peligrosos.

---

## 15. 🧱 Outputs

Valores expuestos al final del stack.

```yaml
Outputs:
  BucketName:
    Value: !Ref LogsBucket
```

Casos:

- endpoint;
- resource ID;
- ARN;
- export cross-stack.

---

## 16. 🧱 Exports / ImportValue

Un stack puede exportar output y otro importarlo.

```text
Network Stack
   │ exports VpcId
   ▼
Application Stack
```

Esto crea dependencia entre stacks; hay restricciones para modificar/eliminar exports
mientras existen imports, y conviene entender cuán rígidas son antes de apoyarse en el
mecanismo: **mientras alguien importe un export, el stack que lo exporta no puede borrar
ese output ni cambiar su valor, ni borrarse él mismo**. El acoplamiento no es de lectura,
es de ciclo de vida.

En una topología estable —una VPC compartida que nadie va a tocar— eso es aceptable e
incluso deseable, porque impide romper por accidente algo de lo que otros dependen. En
stacks que se destruyen y se recrean seguido, es un bloqueo permanente. La alternativa
habitual es publicar el valor en SSM Parameter Store y leerlo desde el otro stack: el
dato se comparte igual, pero sin que CloudFormation encadene los ciclos de vida. Es la
decisión que toma [`L02` §3](l02-cloudformation-desde-la-cli.md#3--el-template-base), y
ahí está explicada sobre el template real.

---

## 17. 🧱 Dependencias implícitas

CloudFormation infiere dependencias cuando referencias recursos.

```yaml
SecurityGroupIngress:
  SourceSecurityGroupId: !Ref AlbSecurityGroup
```

CloudFormation sabe que necesita el referenced resource.

---

## 18. 🧱 `DependsOn`

Permite expresar dependencia explícita cuando no existe referencia suficiente o necesitas controlar ordering especial.

```yaml
AppResource:
  Type: ...
  DependsOn: AnotherResource
```

No usar para todo. Prefiere dependencias implícitas mediante `Ref`/`GetAtt` cuando representan la relación real.

---

## 19. 🧱 DeletionPolicy

Controla qué hacer con ciertos recursos cuando CloudFormation los elimina del stack o se elimina el stack.

Casos importantes:

```text
Delete
Retain
Snapshot  ← para tipos compatibles
```

Para databases/buckets críticos revisa este comportamiento antes de depender de defaults,
porque el default no es el mismo para todo: es `Delete` para casi todos los tipos, pero
**`Snapshot` para `AWS::RDS::DBCluster` y para `AWS::RDS::DBInstance`** sin
`DBClusterIdentifier`. Esa asimetría produce las dos sorpresas opuestas del servicio: un
bucket que desaparece con sus objetos porque nadie declaró nada, y un snapshot de RDS que
sigue facturando meses después de un `delete-stack` que todo el mundo dio por completo.

Ejemplo:

```yaml
Database:
  Type: AWS::RDS::DBInstance
  DeletionPolicy: Snapshot
```

`Retain` merece su propia advertencia: no protege el recurso, lo **desvincula**. El
recurso sigue vivo y facturando, pero ya no está en ningún stack, así que ningún
`delete-stack` posterior lo va a encontrar. Es una decisión legítima para una migración
y una fuga silenciosa si se usa para salir del paso; el catálogo de lo que sobrevive así
está en [`A02` §5](a02-costos-trampas-y-recursos-huerfanos.md#5--trampas-concretas-con-su-antídoto).

---

## 20. 🧱 UpdateReplacePolicy

Controla el destino del recurso físico antiguo cuando una actualización requiere
**replacement**.

Distinto de DeletionPolicy, y la diferencia está en el momento, no en el efecto:
`DeletionPolicy` se aplica cuando el recurso sale del stack; `UpdateReplacePolicy`, cuando
sigue en el stack pero CloudFormation tiene que crear uno nuevo y descartar el viejo. Un
template que solo declara el primero deja el segundo caso al default —`Delete`—, y ese es
el hueco por el que se pierden datos en una actualización que nadie consideraba
destructiva.

Pregunta de entrevista:

> Cambiar una propiedad puede requerir replacement. ¿Qué riesgo existe?

- downtime;
- nuevo identifier/endpoint;
- data loss si lifecycle policies no están bien diseñadas;
- dependencies.

Lo que hace peligroso el replacement es que no se anuncia en la sintaxis: cambiar el
`TableName` de una tabla o el `AvailabilityZone` de una instancia se ve en el diff igual
que cambiar un tag, y una de las tres recrea el recurso desde cero. La única forma de
saberlo por adelantado es la documentación del tipo de recurso —cada propiedad declara si
es *Update requires: Replacement*— o mirar el change set. Por eso Change Sets son
importantes.

---

## 21. 🧱 Stack Create / Update / Delete

### Create

Template + Parameters → recursos.

### Update

CloudFormation compara desired configuration y actualiza recursos necesarios. Según las propiedades puede:

- actualizar in place;
- interrumpir temporalmente;
- reemplazar recurso.

### Delete

Elimina recursos según policies y dependencias, salvo recursos retenidos/configurados de otra forma.

---

## 22. 🧱 Change Sets

Preview de cambios antes de ejecutarlos.

```text
new template
    │
    ▼
Change Set
    │
    ├── Modify SG
    ├── Add Lambda
    └── Replace DB  ← ⚠️
```

Tú revisas y después decides ejecutar.

La columna que hay que mirar es `Replacement`, y tiene tres valores, no dos: `True`,
`False` y `Conditional` —este último cuando el resultado depende de valores que solo se
conocen al ejecutar—. Un `Conditional` sobre un recurso con estado se trata como un
`True` hasta que puedas demostrar lo contrario.

AWS advierte que un Change Set no garantiza que la ejecución vaya a tener éxito, pero
reduce sorpresas al mostrar impacto previsto y hace validaciones previas. Conviene tener
clara esa frontera: el change set describe **la intención**, calculada comparando
template contra estado conocido. Los fallos por permisos que faltan, por límites de
servicio alcanzados o por el estado real del recurso no aparecen ahí; aparecen al
ejecutar. Un change set limpio no es una promesa de despliegue exitoso, es la garantía de
que no vas a destruir nada sin haberlo visto antes.

Para producción:

> preferir Change Set/review frente a direct update ciego.

---

## 23. 🩺 Drift

**Drift** ocurre cuando el estado real de un recurso cambia fuera de CloudFormation y deja de coincidir con el template esperado.

Ejemplo:

```text
CloudFormation template:
SG allows 443

Admin Console manual change:
SG allows 22 from 0.0.0.0/0
```

Ahora el resource está drifted, y el problema no es estético: el siguiente despliegue
puede revertir ese cambio sin avisar —si la propiedad está en el template, CloudFormation
la reescribe con su valor— o, peor, fallar de una forma incomprensible porque el estado
del que parte no es el que creía.

CloudFormation puede detectar drift para tipos/propiedades soportados, con tres límites
que hay que decir en voz alta al responder por él: la detección es **bajo demanda**, no
continua, así que nadie se entera hasta que alguien la lanza; **no cubre todos los tipos
de recurso**, y los que no cubre se reportan como `NOT_CHECKED`, que es fácil confundir
con "está bien"; y **no corrige nada**, solo informa. La corrección es volver a desplegar
el template, asumiendo que el cambio manual no debía estar ahí — y si debía estar, lo que
hay que actualizar es el template.

La documentación actual también incorpora **drift-aware change sets**, capaces de comparar estado actual, estado desplegado previo y desired state para recursos compatibles.

---

## 24. 🧱 Rollback

Si una operación falla CloudFormation normalmente intenta rollback según el tipo de operación/configuración.

Estados que verás:

```text
CREATE_IN_PROGRESS
CREATE_COMPLETE
UPDATE_IN_PROGRESS
UPDATE_ROLLBACK_IN_PROGRESS
UPDATE_ROLLBACK_COMPLETE
DELETE_IN_PROGRESS
...
```

Durante troubleshooting, revisar **Events** del stack suele mostrar el primer resource que falló.

---

## 25. 🧱 Nested Stacks

Permiten componer templates mediante stacks anidados.

```text
Root Stack
├── Network Nested Stack
├── Data Nested Stack
└── App Nested Stack
```

Útil para modularidad, aunque añade lifecycle/dependency complexity.

---

## 26. 🧱 StackSets — concepto

Permiten desplegar stacks de forma coordinada en múltiples cuentas y/o Regions.

Casos:

- baseline security;
- roles comunes;
- Config rules;
- networking standards;
- recursos organizacionales repetidos.

---

## 27. 🧱 Transform / SAM

`Transform` permite macros. Caso conocido:

```yaml
Transform: AWS::Serverless-2016-10-31
```

para AWS SAM, que ofrece sintaxis de mayor nivel para serverless y después se transforma a CloudFormation.

---

## 28. 🧪 Ejemplo mínimo — S3

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Minimal S3 example

Parameters:
  Environment:
    Type: String
    AllowedValues: [dev, qa, prod]
    Default: dev

Resources:
  AppBucket:
    Type: AWS::S3::Bucket
    Properties:
      VersioningConfiguration:
        Status: Enabled
      Tags:
        - Key: Environment
          Value: !Ref Environment

Outputs:
  BucketName:
    Value: !Ref AppBucket
  BucketArn:
    Value: !GetAtt AppBucket.Arn
```

---

## 29. 🧪 Ejemplo — VPC y Security Group

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Basic VPC and application security group

Parameters:
  VpcCidr:
    Type: String
    Default: 10.0.0.0/16

Resources:
  AppVpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: app-vpc

  AppSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Application security group
      VpcId: !Ref AppVpc
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          CidrIp: 10.0.0.0/16

Outputs:
  VpcId:
    Value: !Ref AppVpc
  SecurityGroupId:
    Value: !Ref AppSecurityGroup
```

**Nota:** es didáctico, no arquitectura de producción completa. En producción preferirías, por ejemplo, source SG desde ALB en vez de permitir todo el CIDR de la VPC cuando sea posible.

---

## 30. 🧪 Ejemplo — DynamoDB

```yaml
Resources:
  OrdersTable:
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
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: true
```

Mapping mental:

```text
HASH  → partition key
RANGE → sort key
```

---

## 31. 🧪 Ejemplo — Condition

```yaml
Parameters:
  Environment:
    Type: String
    AllowedValues: [dev, prod]

Conditions:
  IsProd: !Equals [!Ref Environment, prod]

Resources:
  AuditBucket:
    Type: AWS::S3::Bucket
    Condition: IsProd
```

En `dev` no se crea; en `prod` sí.

---

## 32. 🩺 Errores comunes

### 1. Cambios manuales en Console

Causan drift.

### 2. Hardcodear ARNs/account IDs

Usa pseudo parameters/Parameters cuando corresponde.

### 3. `Action: '*' Resource: '*'`

IaC no vuelve segura una policy insegura.

### 4. No revisar replacement

Un cambio aparentemente pequeño puede reemplazar DB/resource.

### 5. Meter todo en un stack gigantesco

Puede aumentar blast radius y dificultad operativa.

### 6. Templates sin lint/validation

Usa tooling como `cfn-lint` y pipeline de validación.

### 7. Guardar passwords plaintext en template

Usa Secrets Manager/SSM/dynamic references o mecanismos apropiados.

---

## 33. ⚖ CloudFormation vs Terraform — respuesta corta

| | CloudFormation | Terraform |
|---|---|---|
| Vendor | AWS | HashiCorp |
| Scope | AWS-centric | multi-provider |
| Language | YAML/JSON + intrinsic funcs | HCL |
| State | administrado por CloudFormation | state explícito Terraform |
| Integración AWS | nativa | provider AWS |

No hay necesidad de declarar ganador universal. Si la empresa usa Terraform, aprender CloudFormation sigue siendo útil para entender IaC nativo AWS y servicios que generan/consumen templates.

---

## 34. 🧪 Workflow recomendado

```text
edit template
    │
    ▼
lint / validate
    │
    ▼
commit / pull request
    │
    ▼
create change set
    │
    ▼
review replacement/security changes
    │
    ▼
execute
    │
    ▼
monitor stack events
    │
    ▼
drift/config checks
```

---

## 🧠 Preguntas rápidas

1. ¿Template vs Stack?
2. ¿Qué sección es obligatoria?
3. ¿`Ref` vs `Fn::GetAtt`?
4. ¿Para qué sirve `Fn::Sub`?
5. ¿Parameter vs Mapping?
6. ¿Qué es una Condition?
7. ¿Qué es `AWS::NoValue`?
8. ¿Cuándo usar `DependsOn`?
9. ¿`DeletionPolicy` vs `UpdateReplacePolicy`?
10. ¿Qué es replacement?
11. ¿Qué hace un Change Set?
12. ¿Qué es drift?
13. ¿Qué revisarías si UPDATE_ROLLBACK ocurre?
14. ¿Nested Stack vs StackSet?
15. ¿Por qué IaC no garantiza seguridad por sí sola?

---

## 📚 Referencias oficiales

- CloudFormation overview: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html
- Template sections: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html
- Resources: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html
- Parameters: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html
- Mappings: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html
- Conditions: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html
- Intrinsic functions: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/intrinsic-function-reference.html
- Stacks: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacks.html
- Change Sets: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html
- Drift detection: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-drift.html
- DeletionPolicy: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-attribute-deletionpolicy.html
- UpdateReplacePolicy: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-attribute-updatereplacepolicy.html
- StackSets: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/what-is-cfnstacksets.html
- `Ref`: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/intrinsic-function-reference-ref.html
- `Fn::GetAtt`: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/intrinsic-function-reference-getatt.html
- `Fn::Sub`: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/intrinsic-function-reference-sub.html
- Pseudo parameters: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html
- Outputs y Exports: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html
- `DependsOn`: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-attribute-dependson.html
- Actualizar stacks: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacks.html
- Comportamiento de update: qué recurso se reemplaza: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html
- Nested Stacks: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-nested-stacks.html
- Sección `Transform` y SAM: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/transform-section-structure.html
- Buenas prácticas de CloudFormation: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html
- Troubleshooting de stacks: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/troubleshooting.html
