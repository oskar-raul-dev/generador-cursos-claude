# L02 — CloudFormation desde la CLI: construir, cambiar y destruir

> **Objetivo:** construir el stack de datos del sistema de inventario solo con la CLI, y
> provocar a propósito los cuatro estados que en producción cuestan una tarde.
> **Costo esperado:** $0.00. Una tabla DynamoDB on-demand vacía, un bucket S3 vacío y un
> parámetro estándar de SSM no generan cargo.
> **Duración:** 2–3 horas.
> **Prerrequisito:** [`L01`](l01-preparacion-cli-y-blindaje-de-costos.md) cerrado.
> **Deja encendido:** el stack `inv-lab-data` con la tabla `inv-lab-events`, el bucket
> y el parámetro SSM. Sin cargo, y [`L03`](l03-backend-serverless-lambda-api-y-eventos.md)
> lo asume existente.
> **Teoría de apoyo:** [`09`](09-cloudformation-iac.md) y [`04`](04-dynamodb-nosql.md).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Qué practica este lab](#1--qué-practica-este-lab) · [`deploy` frente a `create-stack`](#2--deploy-frente-a-create-stack) · [El template base](#3--el-template-base) · [Validar antes de desplegar](#4--validar-antes-de-desplegar) · [Desplegar](#5--desplegar) · [Change sets: la señal de `Replacement`](#6--change-sets-la-señal-de-replacement) · [Provocar `ROLLBACK_COMPLETE`](#7--provocar-rollback_complete) · [Drift](#8--drift) · [Protecciones](#9--protecciones) · [Destruir, incluido el caso que falla](#10--destruir-incluido-el-caso-que-falla) · [Checklist de salida](#11--checklist-de-salida) · [Preguntas rápidas](#-preguntas-rápidas) · [Ejercicios](#-ejercicios-14) · [La señal de que quedó bien](#-la-señal-de-que-quedó-bien) · [Referencias oficiales](#-referencias-oficiales)

Segundo lab. Construye el stack de datos del sistema de inventario usando únicamente
la CLI, y provoca a propósito los cuatro estados que en producción cuestan una tarde:
`ROLLBACK_COMPLETE`, `UPDATE_ROLLBACK_FAILED`, `DELETE_FAILED` y drift.

---

## 1. 🧭 Qué practica este lab

| Tema | Por qué no se aprende con un emulador |
|---|---|
| Ciclo de vida real de un stack | Los emuladores implementan el camino feliz, no los estados de fallo |
| Change sets y `Replacement` | Es la señal que evita destruir datos en producción |
| Drift | Solo tiene sentido si alguien puede cambiar el recurso fuera del template |
| Borrado con dependencias | Los bloqueos de borrado son específicos de cada servicio real |

---

## 2. 🧱 `deploy` frente a `create-stack`

```text
create-stack / update-stack  → API cruda. Falla si el stack ya existe (o si no existe).
                               Controlas cada paso.

deploy                       → crea un change set, lo ejecuta y espera.
                               Idempotente: sirve para crear y para actualizar.
```

Para el trabajo diario se usa `deploy`. Para aprender el mecanismo hay que pasar al
menos una vez por `create-change-set` → `describe-change-set` → `execute-change-set`,
que es exactamente lo que `deploy` hace por debajo.

---

## 3. 🧱 El template base

`base.yaml` — tabla de eventos de inventario, bucket de exportaciones y un parámetro
SSM para publicar el nombre de la tabla a los stacks siguientes.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: inv-lab - capa de datos

Parameters:
  ProjectName:
    Type: String
    Default: inv-lab
  BillingMode:
    Type: String
    Default: PAY_PER_REQUEST
    AllowedValues: [PAY_PER_REQUEST, PROVISIONED]

Conditions:
  IsProvisioned: !Equals [!Ref BillingMode, PROVISIONED]

Resources:
  EventsTable:
    Type: AWS::DynamoDB::Table
    DeletionPolicy: Delete          # explícito: el default también es Delete, pero no se deja implícito
    UpdateReplacePolicy: Delete
    Properties:
      TableName: !Sub '${ProjectName}-events'
      BillingMode: !Ref BillingMode
      ProvisionedThroughput: !If
        - IsProvisioned
        - { ReadCapacityUnits: 1, WriteCapacityUnits: 1 }
        - !Ref 'AWS::NoValue'
      AttributeDefinitions:
        - { AttributeName: PK, AttributeType: S }
        - { AttributeName: SK, AttributeType: S }
      KeySchema:
        - { AttributeName: PK, KeyType: HASH }
        - { AttributeName: SK, KeyType: RANGE }
      StreamSpecification:
        StreamViewType: NEW_AND_OLD_IMAGES
      TimeToLiveSpecification:
        AttributeName: expiresAt
        Enabled: true

  ExportsBucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Delete
    Properties:
      BucketName: !Sub '${ProjectName}-exports-${AWS::AccountId}-${AWS::Region}'
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      LifecycleConfiguration:
        Rules:
          - Id: expire-fast
            Status: Enabled
            ExpirationInDays: 1

  TableNameParam:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '/${ProjectName}/data/events-table'
      Type: String
      Value: !Ref EventsTable

Outputs:
  EventsTableName:
    Value: !Ref EventsTable
  EventsStreamArn:
    Value: !GetAtt EventsTable.StreamArn
  ExportsBucketName:
    Value: !Ref ExportsBucket
```

Puntos de diseño que conviene poder defender:

- **`AWS::NoValue`** elimina la propiedad cuando la condición no se cumple. Es la
  forma correcta de tener un template que sirve en dos modos sin duplicarlo.
- **Nombre de bucket con `${AWS::AccountId}-${AWS::Region}`** porque el espacio de
  nombres de S3 es global. Un nombre fijo hace el template irreproducible.
- **SSM Parameter Store en lugar de `Export`/`Fn::ImportValue`.** Mientras un stack
  importa un export, el stack que lo exporta no puede borrarse ni cambiar ese valor.
  En un lab que se destruye a diario, eso es un bloqueo permanente.

---

## 4. 🧪 Validar antes de desplegar

```bash
aws cloudformation validate-template --template-body file://base.yaml
```

- `--template-body file://base.yaml` lee el archivo del disco. El prefijo `file://` no
  es decorativo: sin él la CLI trata `base.yaml` como el **contenido literal** del
  template y devuelve un error de parseo que no menciona el archivo por ningún lado.
  Es el error de novato número uno con esta CLI.
- Para un template de más de 51.200 bytes este flag ya no vale y hay que subirlo a S3
  y pasar `--template-url`. Te enterarás por un `ValidationError` sobre el tamaño.

`validate-template` solo comprueba que el documento sea sintácticamente válido y que
las funciones intrínsecas estén bien formadas. **No** valida nombres de propiedades,
tipos de recurso ni permisos. Para eso:

```bash
pip install cfn-lint
cfn-lint base.yaml
```

---

## 5. 🧱 Desplegar

```bash
aws cloudformation deploy \
  --stack-name inv-lab-data \
  --template-file base.yaml \
  --parameter-overrides ProjectName=inv-lab BillingMode=PAY_PER_REQUEST \
  --tags Project=inv-lab Lab=L02 Owner=oskar AutoDelete=true
```

Flag por flag, porque cada uno tiene una trampa:

- `--stack-name inv-lab-data` es la identidad del stack dentro de la Region. Cambiarlo
  no renombra nada: crea un stack nuevo y te deja el viejo en pie, cobrando si tenía
  algo que cobra.
- `--template-file base.yaml` es la versión de `deploy` del `--template-body` de la API
  cruda, y aquí **no lleva el prefijo `file://`**. Sí: dos comandos del mismo servicio
  con convenciones distintas. Si le pones `file://`, `deploy` no encuentra el archivo.
- `--parameter-overrides` pasa los `Parameters` del template como pares `Clave=Valor`
  separados por espacios. Los que no menciones toman su `Default`; si un parámetro no
  tiene `Default` y no lo pasas, el despliegue falla antes de tocar un solo recurso.
- `--tags` etiqueta el stack **y propaga los tags a todos los recursos que lo soporten**.
  Es el mecanismo con el que [`L04`](l04-observabilidad-y-destruccion-verificada.md)
  demuestra que no quedó nada vivo, así que no es opcional: sin `Project=inv-lab` el barrido por tag no encuentra el recurso.
- Lo que **no** ves aquí: `deploy` crea un change set, lo ejecuta y espera a que
  termine, todo en una llamada. Por eso no hace falta un `wait` después.

> ⚠️ Si el template creara roles o políticas de IAM, este comando fallaría con
> `InsufficientCapabilitiesException` hasta que añadas `--capabilities CAPABILITY_IAM`
> (o `CAPABILITY_NAMED_IAM` si los recursos llevan nombre propio). No es un permiso que
> te falte: es una confirmación explícita que la API te exige a ti. En
> [`L03`](l03-backend-serverless-lambda-api-y-eventos.md), que sí crea roles, ese flag
> aparece en todos los despliegues.

Seguir el avance en otra terminal:

```bash
aws cloudformation describe-stack-events --stack-name inv-lab-data \
  --query 'StackEvents[].{T:Timestamp,R:LogicalResourceId,S:ResourceStatus,M:ResourceStatusReason}' \
  --output table
```

- `--query` es JMESPath y lo aplica la CLI en tu máquina, después de recibir la
  respuesta completa (el detalle está en [`A01` §3](a01-cli-de-supervivencia.md#3----query-jmespath-en-la-práctica)).
  Aquí `StackEvents[]` recorre la lista de eventos y `{T:...,R:...}` construye un objeto
  nuevo con solo cuatro campos, renombrados corto para que la tabla quepa en pantalla.
- `ResourceStatusReason` es la columna que importa: es el único sitio donde aparece el
  mensaje de error real cuando un recurso falla. El `ResourceStatus` solo te dice
  `CREATE_FAILED`, no por qué.
- `--output table` da el formato legible. Para encadenar con otro comando querrás
  `--output text`; para procesar con `jq`, `--output json`.

> 💡 **Truco.** Los eventos vienen del más reciente al más antiguo, así que el primer
> `CREATE_FAILED` que leas de arriba abajo suele ser una consecuencia, no la causa. La
> causa raíz está **abajo**, en el evento más viejo de la cascada de fallos.

Leer los Outputs:

```bash
aws cloudformation describe-stacks --stack-name inv-lab-data \
  --query 'Stacks[0].Outputs' --output table
```

`Stacks[0]` toma el primer (y único) elemento porque `describe-stacks` siempre devuelve
una lista, incluso filtrando por nombre. Omitir el `[0]` te deja una lista de una sola
posición y las expresiones que vengan después no encajan.

---

## 6. 🧱 Change sets: la señal de `Replacement`

Cambia `TableName` en el template (por ejemplo a `inv-lab-events-v2`) y **no
despliegues**. Genera el change set y míralo:

```bash
aws cloudformation deploy \
  --stack-name inv-lab-data \
  --template-file base.yaml \
  --no-execute-changeset
```

`--no-execute-changeset` parte en dos lo que `deploy` normalmente hace de corrido: crea
el change set y se detiene ahí, sin ejecutarlo. Es la forma corta de la secuencia
`create-change-set` → `describe-change-set` → `execute-change-set`, y es el flag que
convierte a `deploy` en algo seguro de correr contra un stack que te importa.

La CLI imprime el nombre del change set. Descríbelo:

```bash
aws cloudformation describe-change-set \
  --stack-name inv-lab-data \
  --change-set-name <nombre> \
  --query 'Changes[].ResourceChange.{Recurso:LogicalResourceId,Accion:Action,Reemplazo:Replacement,Scope:Scope}' \
  --output table
```

```text
|  Recurso      |  Accion  |  Reemplazo  |  Scope         |
|  EventsTable  |  Modify  |  True       |  ["Properties"]|
```

Cómo se lee esa tabla, columna por columna:

- **`Accion`** — `Add`, `Modify` o `Remove`. `Modify` suena inofensivo y no lo es: es
  justo el caso donde hay que mirar la columna siguiente.
- **`Reemplazo`** — la columna que decide si pierdes datos. Con `True`, CloudFormation
  crea el recurso nuevo, mueve las referencias y **borra el viejo**.
- **`Scope`** — qué parte del recurso cambia: `Properties`, `Tags`, `Metadata`. Si el
  scope es solo `Tags`, no hay riesgo.
- **`--change-set-name <nombre>`** es literal: pega el nombre que imprimió el comando
  anterior. No hay un "último change set" implícito, y por eso `describe-change-set`
  falla con `ChangeSetNotFound` si te equivocas en una letra.

> Regla de entrevista: `Replacement: True` significa que CloudFormation va a crear un
> recurso nuevo y borrar el viejo. En una tabla o una base de datos, eso es pérdida
> de datos, no una actualización.

Los tres valores posibles son `True`, `False` y `Conditional` — este último cuando
depende de valores que solo se conocen en tiempo de ejecución.

⚠️ Un change set describe lo que CloudFormation *intentará* hacer. No garantiza que
la ejecución tenga éxito: los errores de permisos, de límite de servicio o de estado
del recurso aparecen recién al ejecutar.

Descarta el change set sin ejecutarlo:

```bash
aws cloudformation delete-change-set --stack-name inv-lab-data --change-set-name <nombre>
```

---

## 7. 🩺 Provocar `ROLLBACK_COMPLETE`

Crea un stack nuevo con un error garantizado — por ejemplo, un bucket cuyo nombre ya
existe globalmente o un nombre inválido con mayúsculas:

```yaml
  BadBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: INV-LAB-MAYUSCULAS-INVALIDO
```

```bash
aws cloudformation create-stack --stack-name inv-lab-roto --template-body file://roto.yaml
aws cloudformation wait stack-create-complete --stack-name inv-lab-roto   # fallará
aws cloudformation describe-stacks --stack-name inv-lab-roto \
  --query 'Stacks[0].StackStatus' --output text
```

- `create-stack` es la API cruda: **devuelve el control de inmediato**, en cuanto AWS
  acepta la petición. El stack sigue creándose en segundo plano, así que el comando
  "exitoso" no significa nada todavía.
- Por eso hace falta `wait stack-create-complete`, que sondea cada pocos segundos hasta
  que el stack llega a un estado terminal. Si ese estado es de fallo, el waiter sale con
  código distinto de cero — que es exactamente lo que va a pasar aquí, y está bien.
- ⚠️ Un waiter que sale con error puede significar dos cosas distintas: que la operación
  falló, o que se agotaron sus reintentos con la operación todavía en curso. Distinguirlas
  requiere consultar el estado, que es lo que hace el tercer comando.

```text
ROLLBACK_COMPLETE
```

> Regla: un stack en `ROLLBACK_COMPLETE` **solo admite `delete-stack`**. No se puede
> actualizar. Es un estado terminal de una creación fallida.

Para depurar en vez de perder el rastro, la creación se hace con rollback desactivado:

```bash
aws cloudformation create-stack --stack-name inv-lab-roto2 \
  --template-body file://roto.yaml --disable-rollback
```

Así los recursos que sí se crearon quedan en pie para inspeccionarlos, y el stack
queda en `CREATE_FAILED`, desde donde sí se puede reintentar.

---

## 8. 🩺 Drift

Cambia algo a mano, por fuera del template:

```bash
aws ssm put-parameter --name /inv-lab/data/events-table \
  --value cambiado-a-mano --type String --overwrite
```

`--overwrite` es obligatorio para modificar un parámetro existente; sin él, la API
responde `ParameterAlreadyExists` y no cambia nada. Este comando es deliberadamente "lo
que no se debe hacer": tocar a mano un recurso que gestiona un template. Eso es
exactamente lo que significa drift.

Detecta:

```bash
ID=$(aws cloudformation detect-stack-drift --stack-name inv-lab-data \
      --query StackDriftDetectionId --output text)

aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id "$ID"

aws cloudformation describe-stack-resource-drifts --stack-name inv-lab-data \
  --stack-resource-drift-status-filters MODIFIED \
  --query 'StackResourceDrifts[].{R:LogicalResourceId,S:StackResourceDriftStatus}' \
  --output table
```

Son tres comandos y no uno porque la detección de drift es **asíncrona**:

1. `detect-stack-drift` solo *lanza* el análisis y devuelve un identificador. No trae
   ningún resultado. `--output text` aquí es importante: con el `json` por defecto, la
   variable `ID` se quedaría con las comillas incluidas y el comando siguiente fallaría.
2. `describe-stack-drift-detection-status` consulta si ese análisis terminó. Mientras
   esté en `DETECTION_IN_PROGRESS`, los resultados aún no están.
3. `describe-stack-resource-drifts` trae ya el detalle por recurso.
   `--stack-resource-drift-status-filters MODIFIED` limita la salida a lo que cambió;
   los otros valores posibles son `IN_SYNC`, `DELETED` y `NOT_CHECKED`, y este último es
   el interesante: significa que CloudFormation **no sabe** comprobar ese tipo de recurso.

⚠️ La detección de drift no es continua ni automática: es una operación bajo demanda,
no cubre todos los tipos de recurso y no corrige nada. Corregir es volver a desplegar
el template.

---

## 9. 🧱 Protecciones

**Termination protection** — impide `delete-stack` hasta desactivarla.

```bash
aws cloudformation update-termination-protection \
  --stack-name inv-lab-data --enable-termination-protection
```

`--enable-termination-protection` es un flag booleano cuyo contrario existe y se llama
`--no-enable-termination-protection`. Ese es el que necesitas antes del teardown, y el
que se olvida siempre.

**Stack policy** — impide que una actualización toque ciertos recursos.

```json
{
  "Statement": [
    { "Effect": "Allow", "Action": "Update:*", "Principal": "*", "Resource": "*" },
    { "Effect": "Deny",  "Action": "Update:Replace", "Principal": "*",
      "Resource": "LogicalResourceId/EventsTable" }
  ]
}
```

```bash
aws cloudformation set-stack-policy --stack-name inv-lab-data \
  --stack-policy-body file://stack-policy.json
```

> ⚠️ Una stack policy **no es una política de IAM**, aunque se le parezca. No controla
> quién puede hacer qué: controla qué operaciones de actualización puede aplicar el
> propio CloudFormation sobre cada recurso del stack. Sus acciones son `Update:Modify`,
> `Update:Replace`, `Update:Delete` y `Update:*`, que no existen en IAM, y su `Resource`
> es un `LogicalResourceId`, no un ARN. Confundirlas es un clásico de entrevista.

En un lab que se destruye a diario, ambas se activan una vez para entenderlas y luego
se desactivan: si dejas termination protection puesta, el teardown falla.

---

## 10. 🧪 Destruir, incluido el caso que falla

Sube un objeto al bucket y luego intenta borrar el stack:

```bash
echo prueba > x.txt
aws s3 cp x.txt "s3://inv-lab-exports-$(aws sts get-caller-identity --query Account --output text)-us-east-1/"

aws cloudformation delete-stack --stack-name inv-lab-data
aws cloudformation wait stack-delete-complete --stack-name inv-lab-data   # fallará
```

```text
DELETE_FAILED — The bucket you tried to delete is not empty
```

CloudFormation no vacía buckets. Dos salidas:

```bash
# correcta: vaciar y reintentar
aws s3 rm "s3://inv-lab-exports-.../" --recursive
aws cloudformation delete-stack --stack-name inv-lab-data

# escape: abandonar el recurso (solo válido desde DELETE_FAILED)
aws cloudformation delete-stack --stack-name inv-lab-data --retain-resources ExportsBucket
```

- `aws s3 rm --recursive` borra los objetos, no el bucket. Si el bucket tiene versionado
  activado esto **no basta**: las versiones anteriores y los delete markers siguen ahí, el
  bucket sigue sin estar vacío y el borrado vuelve a fallar. Ese caso concreto, con su
  comando, está en [`A02`](a02-costos-trampas-y-recursos-huerfanos.md).
- `--retain-resources ExportsBucket` recibe **logical IDs** del template, no nombres
  reales de recurso, y solo se acepta sobre un stack que ya está en `DELETE_FAILED`.
  Sobre un stack sano, la API lo rechaza.

⚠️ `--retain-resources` deja el recurso vivo y **fuera** de CloudFormation. Es una
fuga de recursos huérfanos: si lo usas, anótalo, porque el barrido de
[`L04` §11](l04-observabilidad-y-destruccion-verificada.md#11--barrido-explícito-por-servicio)
tiene que encontrarlo.

Verificación de que ya no existe:

```bash
aws cloudformation describe-stacks --stack-name inv-lab-data
# An error occurred (ValidationError): Stack with id inv-lab-data does not exist
```

---

## 11. 📋 Checklist de salida

- [ ] Desplegaste el stack con `deploy` y también con `create-change-set` + `execute-change-set`.
- [ ] Viste un `Replacement: True` y entiendes qué habría destruido.
- [ ] Provocaste y borraste un `ROLLBACK_COMPLETE`.
- [ ] Creaste drift y lo detectaste desde la CLI.
- [ ] Provocaste un `DELETE_FAILED` por bucket con objetos y lo resolviste.
- [ ] No quedan stacks: `aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE` sale vacío para el lab.

---

## 🧠 Preguntas rápidas

1. ¿Qué hace `aws cloudformation deploy` que no hacen `create-stack` ni `update-stack`?
2. ¿Qué valida realmente `validate-template` y qué no valida?
3. ¿Qué significa `Replacement: True` en un change set?
4. ¿Un change set garantiza que la actualización va a tener éxito?
5. ¿Qué operaciones admite un stack en `ROLLBACK_COMPLETE`?
6. ¿Para qué sirve `--disable-rollback` al crear un stack?
7. ¿Cuál es el `DeletionPolicy` por defecto y en qué tipo de recurso cambia?
8. ¿Por qué falla el borrado de un stack que contiene un bucket S3 con objetos?
9. ¿Qué riesgo introduce `--retain-resources`?
10. ¿Por qué `Export`/`Fn::ImportValue` es mala idea entre stacks de distinto ciclo de vida?
11. ¿La detección de drift es continua? ¿Corrige lo que encuentra?
12. ¿Qué hace `AWS::NoValue` y para qué se combina con `Fn::If`?

---

## 🧪 Ejercicios (14)

Todos los obligatorios cuestan **$0.00**: la tabla on-demand vacía, el bucket vacío y el
parámetro SSM no facturan. Cada ejercicio que crea un stack termina borrándolo.

### 🟢 Fácil — el ciclo básico (1–4)

#### 🟢 Ejercicio 1 — `create-stack` frente a `deploy`

Despliega el mismo `base.yaml` dos veces con nombres distintos: una con
`aws cloudformation deploy` y otra con `create-stack` + `wait stack-create-complete`.
Cronometra las dos y anota qué te devuelve cada comando y cuándo.

**Pregunta:** ¿cuál de los dos te devuelve el control antes de que el stack exista, y por
qué eso importa en un script?

#### 🟢 Ejercicio 2 — Romper el `file://`

Corre `validate-template` sin el prefijo `file://` y lee el error completo. Después
córrelo con el prefijo.

**Objetivo:** reconocer un error de parseo que no menciona el archivo por ningún lado, que
es el que más tiempo hace perder a quien vuelve a esta CLI.

#### 🟢 Ejercicio 3 — Los Outputs, en tabla y en variable

Lee los tres Outputs del stack con `--output table`, y después captura solo
`EventsTableName` en una variable de shell usando `--output text`.

**Objetivo:** ver por qué `Stacks[0]` es obligatorio y qué pasa exactamente si lo omites.

#### 🟢 Ejercicio 4 — Un parámetro sin `Default`

Quita el `Default` de `ProjectName` en el template y despliega sin pasar
`--parameter-overrides`. Lee el error, y fíjate en qué momento del despliegue aparece.

**Pregunta:** ¿llegó CloudFormation a tocar algún recurso antes de fallar? ¿Cómo lo sabes?

### 🟡 Intermedio — cambiar sin destruir (5–9)

#### 🟡 Ejercicio 5 — Un cambio sin replacement

Añade un tag nuevo al bucket y genera el change set con `--no-execute-changeset`. Mira las
columnas `Accion`, `Reemplazo` y `Scope`.

**Pregunta:** ¿qué valor tiene `Scope` y por qué este cambio es seguro aunque la acción
sea `Modify`?

#### 🟡 Ejercicio 6 — Cambiar el modo de facturación

Despliega con `BillingMode=PROVISIONED` sobre el stack existente y revisa el change set
antes de ejecutar. Vuelve después a `PAY_PER_REQUEST`.

**Objetivo:** ver `AWS::NoValue` trabajando: la misma plantilla sirve en dos modos porque
la propiedad `ProvisionedThroughput` desaparece del todo, en vez de quedarse vacía.

#### 🟡 Ejercicio 7 — TTL sobre otra columna

Cambia el atributo de TTL de `expiresAt` a otro nombre y observa el change set.

**Pregunta:** ¿es `Modify` o `Replacement`? ¿Y qué habría pasado si el cambio fuera el de
`KeySchema`?

#### 🟡 Ejercicio 8 — El drift que tú provocas

Cambia a mano el valor del parámetro SSM, detecta el drift con los tres comandos de la §8
y anota el `StackResourceDriftStatus` de cada recurso del stack.

**Pregunta:** ¿qué recurso aparece como `NOT_CHECKED` y por qué ese estado no significa
"está bien"?

#### 🟡 Ejercicio 9 — Corregir drift sin tocar la consola

Con el drift del ejercicio anterior todavía presente, devuelve el stack a su estado
declarado sin usar `put-parameter` a mano.

**Objetivo:** interiorizar que la corrección de drift es volver a desplegar el template, y
que la consola no participa.

### 🟠 Difícil — los estados que cuestan una tarde (10–12)

#### 🟠 Ejercicio 10 — `ROLLBACK_COMPLETE` y su única salida

Provoca un `ROLLBACK_COMPLETE` con el bucket de nombre inválido, e intenta después
**actualizar** ese stack con un template corregido. Lee el error, y solo entonces bórralo.

**Pregunta:** ¿por qué CloudFormation no te deja arreglar un stack cuya creación falló, si
el template nuevo sí es válido?

#### 🟠 Ejercicio 11 — `--disable-rollback` y la evidencia

Repite el fallo con `--disable-rollback` y, antes de borrar nada, enumera qué recursos sí
llegaron a crearse.

**Objetivo:** entender qué información destruye un rollback automático, y por qué en
producción a veces conviene conservarla aunque el stack quede en `CREATE_FAILED`.

#### 🟠 Ejercicio 12 — La causa raíz está abajo

Provoca un fallo que arrastre a varios recursos y lee `describe-stack-events` completo.
Identifica el primer evento de la cascada y demuestra por qué el `CREATE_FAILED` que
aparece arriba del todo es una consecuencia y no la causa.

**Objetivo:** leer eventos en el orden correcto —del más viejo al más nuevo— cuando todo
el mundo los lee al revés.

### 🔴 Muy difícil — el borrado que no ocurre (13–14)

#### 🔴 Ejercicio 13 — `DELETE_FAILED` con versionado

Activa el versionado del bucket, sube un objeto, bórralo (queda el delete marker) e
intenta borrar el stack. Cuando falle, resuélvelo **sin** `--retain-resources`.

**Pregunta:** ¿por qué `aws s3 rm --recursive` no basta aquí, y qué comando sí vacía un
bucket versionado?

#### 🔴 Ejercicio 14 — El huérfano deliberado

Provoca un `DELETE_FAILED`, sal del paso con `--retain-resources`, y después **encuentra y
borra** el recurso abandonado partiendo únicamente de la API de tagging, sin recordar su
nombre.

**Objetivo:** comprobar en carne propia que `--retain-resources` no resuelve nada, solo
mueve el problema fuera del alcance de CloudFormation. Es el escenario que
[`L04` §9](l04-observabilidad-y-destruccion-verificada.md#9--lo-que-sobrevive-al-delete-stack)
cataloga.

### 🔥 Opcionales y ampliaciones

- **Nested stack.** Parte `base.yaml` en un stack raíz y uno anidado para la capa de
  datos, y compara los eventos de borrado de los dos. Sin cargo.
- **Termination protection en el peor momento.** Activa la protección, olvídala, e intenta
  el teardown completo. Cronometra cuánto tardas en darte cuenta leyendo solo el error.
- **`cfn-lint` en un hook.** Añade `cfn-lint` a un pre-commit y comprueba cuántos de los
  errores de los ejercicios anteriores lo habrían frenado antes de llegar a AWS.

### 💀 Boss fight — recuperar un stack que nadie puede borrar

Prepara deliberadamente el peor escenario de esta serie y sal de él sin abrir la consola
ni una vez:

1. Despliega el stack con el bucket **versionado** y con `DeletionPolicy: Retain` en la
   tabla.
2. Sube dos objetos y borra uno, para dejar versiones y un delete marker.
3. Activa la termination protection.
4. Provoca además un drift cambiando el parámetro SSM a mano.
5. Ahora recibe el encargo: **dejar la cuenta exactamente como estaba antes del paso 1**,
   sin recursos huérfanos y sin nada facturando.

Entrega un script `teardown-forzado.sh` que resuelva la secuencia completa en el orden
correcto, que sea seguro de reejecutar si falla a la mitad, y que termine verificando con
la API de tagging que no queda nada con `Project=inv-lab`.

**Objetivo:** el boss no es borrar; es descubrir el orden. Cada obstáculo bloquea al
siguiente, y resolverlos en el orden equivocado te devuelve al principio.

**Criterio de terminado:** el script corre dos veces seguidas sin error, la segunda no
encuentra nada que borrar, y `describe-stacks` responde `does not exist`.

---

## 🏁 La señal de que quedó bien

> Puedo mirar un change set y decir, antes de ejecutarlo, qué recurso se va a recrear y
> qué datos se van a perder. Y cuando un `delete-stack` falla, no reintento a ciegas ni
> voy a la consola: leo el `ResourceStatusReason`, sé qué recurso lo bloquea y por qué.

---

## 📚 Referencias oficiales

- AWS CloudFormation User Guide: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html
- Change sets: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html
- Comportamiento de update y reemplazo de recursos: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html
- `DeletionPolicy`: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-attribute-deletionpolicy.html
- `UpdateReplacePolicy`: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-attribute-updatereplacepolicy.html
- Detección de drift: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-drift.html
- Stack policies: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html
- Termination protection: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-protect-stacks.html
- Funciones intrínsecas: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/intrinsic-function-reference.html
- Pseudo parameters: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html
- Conditions: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html
- Solución de problemas de CloudFormation: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/troubleshooting.html
- Referencia CLI de `cloudformation`: https://docs.aws.amazon.com/cli/latest/reference/cloudformation/
