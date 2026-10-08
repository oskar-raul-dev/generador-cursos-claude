# A01 — AWS CLI de supervivencia

> **Objetivo:** manejar la AWS CLI con soltura —precedencia de credenciales, JMESPath,
> paginación, waiters, dry runs— para que los labs no se atasquen en la herramienta.
> **Tipo:** apéndice de referencia. Sin prerrequisitos, sin costo, sin orden de lectura.
> **Se conecta con:** todos los labs, y en especial
> [`L01`](l01-preparacion-cli-y-blindaje-de-costos.md).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Versión y comprobación de entorno](#1--versión-y-comprobación-de-entorno) · [Precedencia de credenciales](#2--precedencia-de-credenciales) · [`--query`: JMESPath en la práctica](#3----query-jmespath-en-la-práctica) · [`--query` no es lo mismo que `--filters`](#4----query-no-es-lo-mismo-que---filters) · [Formatos de salida](#5--formatos-de-salida) · [Paginación](#6--paginación) · [Waiters](#7--waiters) · [Ensayar antes de ejecutar](#8--ensayar-antes-de-ejecutar) · [Esqueletos de entrada](#9--esqueletos-de-entrada) · [Payloads binarios](#10--payloads-binarios) · [Logs en vivo](#11--logs-en-vivo) · [Reintentos y tiempos](#12--reintentos-y-tiempos) · [Combinaciones útiles con `jq`](#13--combinaciones-útiles-con-jq) · [Los comandos que de verdad se usan](#14--los-comandos-que-de-verdad-se-usan) · [Preguntas rápidas](#-preguntas-rápidas) · [Ejercicios](#-ejercicios-10) · [Referencias oficiales](#-referencias-oficiales)

Apéndice de referencia para los labs [`L01`](l01-preparacion-cli-y-blindaje-de-costos.md)
a [`L04`](l04-observabilidad-y-destruccion-verificada.md). No enseña servicios: enseña a
manejar la herramienta con la que se recorren todos. Está pensado para alguien que ya
usó la CLI y necesita recuperar el filo, no para una primera instalación.

---

## 1. 🧪 Versión y comprobación de entorno

```bash
aws --version
aws configure list          # de dónde salen credenciales y región, y con qué precedencia
aws configure list-profiles
```

`aws configure list` es el primer comando de cualquier diagnóstico: muestra el valor
efectivo de cada ajuste **y su origen** (`env`, `config-file`, `iam-role`), que es
justo lo que se necesita cuando "los permisos fallan" y en realidad estás usando otra
identidad.

---

## 2. 🧱 Precedencia de credenciales

```text
1. Parámetros de línea de comandos   (--profile, --region)
2. Variables de entorno              (AWS_ACCESS_KEY_ID, AWS_PROFILE, AWS_REGION...)
3. Archivos ~/.aws/credentials y ~/.aws/config
4. Credenciales de contenedor        (ECS/EKS)
5. Credenciales de instancia         (perfil de instancia EC2)
```

⚠️ Una variable de entorno olvidada gana sobre el perfil. El síntoma es un
`AccessDenied` que no corresponde a la política que acabas de revisar. Diagnóstico:
`aws sts get-caller-identity` y `aws configure list`.

```bash
export AWS_PROFILE=inv-lab
export AWS_REGION=us-east-1
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

Con IAM Identity Center, la sesión caduca y hay que renovarla:

```bash
aws sso login --profile inv-lab
```

---

## 3. 🧱 `--query`: JMESPath en la práctica

`--query` es la diferencia entre leer JSON de 300 líneas y leer una tabla de tres
columnas. Se aplica a la respuesta ya recibida.

| Necesidad | Expresión |
|---|---|
| Un campo de cada elemento | `Functions[].FunctionName` |
| Varios campos con nombre propio | `Functions[].{N:FunctionName,R:Runtime}` |
| Filtrar por igualdad de string | `Volumes[?State=='available']` |
| Filtrar por literal booleano o número | ``Rules[?Enabled==`true`]`` |
| Filtrar por prefijo | ``Buckets[?starts_with(Name, `inv-lab`)]`` |
| Filtrar por contenido | ``Topics[?contains(TopicArn, `inv-lab`)]`` |
| Contar | `length(Reservations[].Instances[])` |
| Ordenar | `sort_by(Snapshots, &StartTime)[-1]` |
| Último elemento | `ResultsByTime[-1]` |
| Aplanar listas anidadas | `Reservations[].Instances[].InstanceId` |
| Encadenar | `Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue \| [0]` |

⚠️ En JMESPath, las comillas simples delimitan **strings** y las comillas invertidas
delimitan **literales JSON** (números, booleanos, null). `[?Enabled=='true']` compara
contra el string `"true"` y no encuentra nada si el campo es booleano.

---

## 4. 🧱 `--query` no es lo mismo que `--filters`

```text
--filters   → lo aplica el servicio.  Reduce lo que viaja por la red.
--query     → lo aplica la CLI en tu máquina, DESPUÉS de recibir todo.
```

En cuentas grandes la diferencia es real: `--query` no reduce llamadas a la API, no
reduce paginación y no reduce el riesgo de throttling. Cuando el servicio ofrece
filtro propio, se usa el filtro.

```bash
# correcto: filtra el servicio, la CLI solo formatea
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[].{Id:VolumeId,GB:Size}' --output table
```

---

## 5. 🧱 Formatos de salida

| Formato | Cuándo |
|---|---|
| `json` | Por defecto; para encadenar con `jq` |
| `text` | Para capturar un valor en una variable de shell |
| `table` | Para leer con los ojos |
| `yaml` | Para comparar contra plantillas |

```bash
API=$(aws cloudformation describe-stacks --stack-name inv-lab-app \
      --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text)
```

⚠️ Con `--output text`, varios valores salen separados por tabuladores en una línea.
Si esperas uno solo, restringe la consulta con `| [0]` en vez de confiar en el orden.

Para que la CLI no abra un paginador interactivo dentro de scripts:

```bash
export AWS_PAGER=""        # o el flag --no-cli-pager
```

---

## 6. 🧱 Paginación

Muchas APIs devuelven páginas. La CLI las recorre sola salvo que le digas lo contrario.

```bash
aws s3api list-objects-v2 --bucket mi-bucket --max-items 100
aws s3api list-objects-v2 --bucket mi-bucket --page-size 100 --no-paginate
```

- `--page-size` cambia el tamaño de cada llamada a la API (útil contra throttling).
- `--max-items` limita cuántos elementos te devuelve la CLI en total, y te da un
  `NextToken` para continuar con `--starting-token`.
- `--no-paginate` hace una sola llamada.

---

## 7. 🧱 Waiters

Bloquean hasta que un recurso alcanza un estado. Sustituyen a los bucles con `sleep`.

```bash
aws cloudformation wait stack-create-complete --stack-name inv-lab-app
aws cloudformation wait stack-delete-complete --stack-name inv-lab-app
aws dynamodb wait table-exists --table-name inv-lab-events
aws ec2 wait instance-running --instance-ids i-0123456789abcdef0
```

Un waiter sondea la API cada pocos segundos hasta que se cumple la condición o se agotan
sus reintentos, y **su valor está en el código de salida**, no en lo que imprime (no
imprime nada): 0 si se alcanzó el estado, distinto de 0 si se agotaron los reintentos.
Por eso encadena bien con `&&` y `||` en un script.

```bash
aws cloudformation wait stack-delete-complete --stack-name X && echo OK || echo REVISAR
```

> ⚠️ Un waiter que sale con error significa una de dos cosas, y no son lo mismo: que la
> operación terminó mal, o que se agotaron los reintentos con la operación todavía en
> curso. Distinguirlas exige consultar el estado real después. Un script que trate
> "waiter falló" como "la operación falló" se equivoca en cuanto la creación de un
> recurso tarda más de lo habitual.

---

## 8. 🧪 Ensayar antes de ejecutar

```bash
# comprueba permisos y parámetros sin crear nada (solo en APIs que lo soportan, sobre todo EC2)
aws ec2 create-tags --resources vol-123 --tags Key=Project,Value=inv-lab --dry-run
```

```text
An error occurred (DryRunOperation) ... Request would have succeeded
```

Ese mensaje es el resultado bueno: tienes permiso y los parámetros son válidos.

---

## 9. 🧱 Esqueletos de entrada

Para llamadas con muchos parámetros anidados, conviene generar la estructura y
rellenarla en un archivo en vez de pelear con comillas en la shell.

```bash
aws lambda create-function --generate-cli-skeleton > fn.json
# editar fn.json
aws lambda create-function --cli-input-json file://fn.json
```

- `--generate-cli-skeleton` no llama a la API: imprime la estructura JSON completa de la
  petición, con todos los campos posibles y valores de relleno. Acepta además el valor
  `output` (`--generate-cli-skeleton output`) para ver la forma de la **respuesta**, que
  es la forma rápida de escribir un `--query` sin ejecutar nada.
- `--cli-input-json file://fn.json` envía ese archivo como petición. El prefijo `file://`
  es obligatorio, igual que en `create-stack`, y **no** lleva el `://` doble de una URL.
- Los flags de línea de comandos que pongas junto a `--cli-input-json` **sobrescriben** lo
  del archivo. Es útil para tener una plantilla y variar un solo valor por invocación.

---

## 10. 🧱 Payloads binarios

```bash
aws lambda invoke --function-name inv-lab-api \
  --cli-binary-format raw-in-base64-out \
  --payload '{"routeKey":"GET /health"}' \
  /dev/stdout
```

⚠️ Sin `--cli-binary-format raw-in-base64-out`, la CLI v2 espera el payload ya
codificado en base64 y devuelve `Invalid base64`. Es uno de los errores más comunes al
volver a la CLI después de un tiempo.

---

## 11. 🧱 Logs en vivo

```bash
aws logs tail /aws/lambda/inv-lab-api --follow --format short
aws logs tail /aws/lambda/inv-lab-api --since 30m --filter-pattern ERROR
```

`aws logs tail` es de los pocos comandos con experiencia de terminal decente: sigue el
log, colorea y acepta filtros. Para consultas analíticas, Logs Insights: la mecánica desde la CLI está en
[`L04` §3](l04-observabilidad-y-destruccion-verificada.md#3--logs-insights-desde-la-cli).

---

## 12. 🧱 Reintentos y tiempos

```bash
export AWS_RETRY_MODE=adaptive     # legacy | standard | adaptive
export AWS_MAX_ATTEMPTS=5
```

`adaptive` añade limitación del lado del cliente cuando el servicio devuelve
throttling. Útil en barridos que recorren muchas regiones o muchos recursos.

---

## 13. 🧱 Combinaciones útiles con `jq`

Cuando la transformación excede a JMESPath:

```bash
# ARNs de todo lo etiquetado con el proyecto, agrupados por servicio
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=inv-lab \
  | jq -r '.ResourceTagMappingList[].ResourceARN' \
  | awk -F: '{print $3}' | sort | uniq -c | sort -rn
```

---

## 14. 🧭 Los comandos que de verdad se usan

| Área | Comandos |
|---|---|
| Identidad | `sts get-caller-identity`, `configure list`, `sso login` |
| CloudFormation | `deploy`, `describe-stacks`, `describe-stack-events`, `create-change-set`, `describe-change-set`, `execute-change-set`, `detect-stack-drift`, `describe-stack-resource-drifts`, `delete-stack`, `wait` |
| Lambda | `invoke`, `list-functions`, `get-function-configuration`, `update-function-configuration`, `list-event-source-mappings`, `put-function-concurrency` |
| DynamoDB | `list-tables`, `describe-table`, `put-item`, `get-item`, `query`, `scan` |
| SQS | `list-queues`, `get-queue-attributes`, `send-message`, `receive-message`, `start-message-move-task` |
| Logs | `tail`, `describe-log-groups`, `put-retention-policy`, `start-query`, `get-query-results` |
| CloudWatch | `list-metrics`, `get-metric-statistics`, `put-metric-alarm`, `describe-alarms` |
| IAM | `list-roles`, `get-role`, `simulate-principal-policy` |
| Costos | `ce get-cost-and-usage`, `budgets describe-budgets`, `ce list-cost-allocation-tags` |
| Barrido | `resourcegroupstaggingapi get-resources`, `ec2 describe-regions` |

---

## 🧠 Preguntas rápidas

1. ¿Qué muestra `aws configure list` que no muestra `aws sts get-caller-identity`?
2. ¿Qué gana en la precedencia: una variable de entorno o el perfil de `~/.aws/config`?
3. ¿Cuál es la diferencia funcional y económica entre `--query` y `--filters`?
4. ¿Por qué `[?Enabled=='true']` puede no devolver nada sobre un campo booleano?
5. ¿Qué hace `--page-size` que no hace `--max-items`?
6. ¿Qué código de salida devuelve un waiter que expira y qué significa realmente?
7. ¿Qué mensaje devuelve un `--dry-run` exitoso y por qué no es un error?
8. ¿Para qué sirve `--generate-cli-skeleton`?
9. ¿Qué error produce olvidar `--cli-binary-format raw-in-base64-out` en `lambda invoke`?
10. ¿Qué aporta `AWS_RETRY_MODE=adaptive` frente a `standard`?

---

## 🧪 Ejercicios (10)

Todos cuestan **$0.00**: son de lectura, consulta y formateo de salida. Ninguno crea un
recurso. Sirven con la cuenta vacía, así que se pueden hacer antes de
[`L02`](l02-cloudformation-desde-la-cli.md) o después del teardown.

### 🟢 Fácil — la herramienta (1–3)

#### 🟢 Ejercicio 1 — Tres identidades, tres orígenes

Consigue que `aws configure list` muestre la región saliendo de tres orígenes distintos en
tres ejecuciones: del archivo de configuración, de una variable de entorno y de un
`--region` en la línea de comandos.

**Objetivo:** ver la precedencia funcionando en vivo, en vez de memorizar la lista de la
§2.

#### 🟢 Ejercicio 2 — El mismo dato en cuatro formatos

Toma cualquier comando de listado y devuelve su salida en `json`, `text`, `table` y
`yaml`. Quédate con el que usarías para capturar un valor en una variable de shell.

**Pregunta:** ¿qué le pasa a `--output text` cuando la consulta devuelve dos valores en
vez de uno, y cómo lo evitas?

#### 🟢 Ejercicio 3 — El booleano que no es un string

Escribe una consulta con `[?Enabled=='true']` sobre cualquier lista que tenga un campo
booleano, comprueba que no devuelve nada, y arréglala.

**Objetivo:** interiorizar la diferencia entre comillas simples e invertidas en JMESPath,
que es el error silencioso más frecuente de `--query`.

### 🟡 Intermedio — exprimir `--query` (4–7)

#### 🟡 Ejercicio 4 — Una tabla de tres columnas renombradas

Lista tus regiones habilitadas y produce una tabla con solo el nombre y el endpoint,
renombrando las columnas a algo corto.

**Objetivo:** dominar la proyección `{A:campo,B:campo}`, que es la que convierte una
respuesta ilegible en una tabla que cabe en pantalla.

#### 🟡 Ejercicio 5 — Filtro del servicio contra filtro local

Consigue el mismo resultado dos veces: una con `--filters` y otra con `--query`. Compara
el tamaño de la respuesta cruda de cada una añadiendo `--debug` o midiendo con `wc -c`.

**Pregunta:** ¿cuál de las dos habría fallado por throttling en una cuenta con diez mil
recursos, y por qué?

#### 🟡 Ejercicio 6 — Paginar a mano

Lista algo que tenga más de una página con `--max-items 2`, captura el `NextToken` y trae
la página siguiente con `--starting-token`.

**Objetivo:** ver la paginación que la CLI normalmente te oculta, que es lo que hay que
entender el día que un script se queda a medias.

#### 🟡 Ejercicio 7 — Esqueleto de entrada y de salida

Genera el esqueleto de petición de `lambda create-function` y, aparte, el de **salida**
con `--generate-cli-skeleton output`.

**Objetivo:** descubrir que el segundo te da la forma de la respuesta sin ejecutar nada, y
que es la manera rápida de escribir un `--query` a ciegas.

### 🟠 Difícil — automatizar sin mentir (8–9)

#### 🟠 Ejercicio 8 — Un waiter que expira

Fuerza un waiter a agotar sus reintentos —por ejemplo, esperando un estado que no va a
llegar— y captura su código de salida.

**Pregunta:** ¿ese código significa que la operación falló? Escribe el fragmento de script
que distingue las dos situaciones antes de decidir qué hacer.

#### 🟠 Ejercicio 9 — El `--dry-run` que sí informa

Corre un `--dry-run` con permisos suficientes y otro sin ellos, y compara los dos
mensajes.

**Objetivo:** aprender a leer `DryRunOperation` como un éxito y a distinguirlo de un
`UnauthorizedOperation`, que es la comprobación de permisos más barata que existe.

### 🔴 Muy difícil — la salida que necesitas (10)

#### 🔴 Ejercicio 10 — Inventario por servicio, en una línea

Escribe un único pipeline que produzca, a partir de la API de tagging, la cuenta de
recursos etiquetados **agrupados por servicio y ordenados de mayor a menor**, usando
`--query` para todo lo que JMESPath pueda hacer y `jq` solo para lo que no.

**Pregunta:** ¿qué parte tuviste que dejarle a `jq` y por qué JMESPath no llegaba?

### 🔥 Opcionales y ampliaciones

- **Alias de shell.** Convierte los cinco comandos que más repites en alias con el perfil
  y la región ya fijados, y mide cuántas pulsaciones te ahorras en una sesión de lab.
- **Autocompletado.** Activa el completado de la CLI v2 en tu shell y comprueba si sugiere
  también los valores de `--query`.
- **Comparar v1 y v2.** Si tienes acceso a una máquina con la CLI v1, corre el mismo
  `lambda invoke` en las dos y anota qué cambia en el manejo del payload binario.

---

## 📚 Referencias oficiales

- AWS CLI User Guide: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html
- Precedencia y orígenes de configuración: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html
- Perfiles con IAM Identity Center: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html
- Filtrar salida con `--query` (JMESPath): https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-filter.html
- Formatos de salida: https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-output-format.html
- Paginación de resultados: https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-pagination.html
- Waiters de la CLI: https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/
- Parámetros desde archivo (`--cli-input-json`, esqueletos): https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-skeleton.html
- Variables de entorno de la CLI: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
- Reintentos y modos `standard`/`adaptive`: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-retries.html
- `aws logs tail`: https://docs.aws.amazon.com/cli/latest/reference/logs/tail.html
- Referencia completa de comandos: https://docs.aws.amazon.com/cli/latest/reference/

### Fuera de la documentación de AWS (opcional)

- Especificación de JMESPath, el lenguaje que implementa `--query`: https://jmespath.org/specification.html
