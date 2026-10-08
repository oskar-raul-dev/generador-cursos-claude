# L01 — Preparación: CLI, identidad y blindaje de costos

> **Objetivo:** dejar la cuenta blindada antes de crear el primer recurso: identidad sin
> claves de larga duración, tags de rastreo, budgets y detección de anomalías.
> **Costo esperado:** $0.00. Budgets (los dos primeros), Cost Anomaly Detection, Cost
> Explorer y los cost allocation tags no tienen cargo.
> **Duración:** 60–90 minutos, una sola vez por cuenta.
> **Prerrequisito:** una cuenta de AWS con acceso a la información de facturación y la
> AWS CLI v2 instalada. Lee antes [`L00`](l00-idea-lab-practico.md).
> **Deja encendido:** nada. Al terminar no hay un solo recurso desplegado.
> **Teoría de apoyo:** [`05`](05-seguridad-iam-kms-secretos.md) (IAM) y
> [`A01`](a01-cli-de-supervivencia.md) (la mecánica de la CLI).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Qué practica este lab](#1--qué-practica-este-lab) · [Identidad y credenciales](#2--identidad-qué-credenciales-usa-la-cli) · [Región](#3--región-fijarla-explícitamente) · [Contrato de tagging](#4--contrato-de-tagging) · [Cost allocation tags](#5--activar-los-tags-de-asignación-de-costos) · [Budgets](#6--budgets) · [Cost Anomaly Detection](#7--cost-anomaly-detection) · [Cost Explorer](#8--cost-explorer) · [Checklist de salida](#9--checklist-de-salida) · [Preguntas rápidas](#-preguntas-rápidas) · [Ejercicios](#-ejercicios-12) · [La señal de que quedó bien](#-la-señal-de-que-quedó-bien) · [Referencias oficiales](#-referencias-oficiales)

Primer lab de la serie práctica. No crea infraestructura de aplicación: crea las
condiciones para que los labs siguientes se puedan encender y apagar sin sorpresas
en la factura.

---

## 1. 🧭 Qué practica este lab

| Tema | Por qué solo se aprende en AWS real |
|---|---|
| Identidad y perfiles de CLI | Ningún emulador local exige credenciales ni las rota |
| Tags de asignación de costos | Solo existen dentro del sistema de facturación de AWS |
| Budgets y anomaly detection | Requieren gasto real para tener sentido |
| Cost Explorer | Es la única fuente de verdad sobre lo que pagaste |

Regla de entrada:

```text
Sin tags → sin rastreo → sin certeza de teardown
```

Todo lo que se cree en los labs siguientes lleva `Project=inv-lab`. Ese tag es el
mecanismo con el que [`L04`](l04-observabilidad-y-destruccion-verificada.md) demuestra
que no quedó nada vivo.

---

## 2. 🧱 Identidad: qué credenciales usa la CLI

Tres opciones, en orden de preferencia:

**IAM Identity Center (recomendado).** Credenciales temporales, sin claves de larga
duración en disco.

```bash
aws configure sso --profile inv-lab
aws sso login --profile inv-lab
```

- `aws configure sso` es interactivo y se corre **una sola vez**: te pregunta la URL del
  portal, la Region del Identity Center, y escribe el perfil en `~/.aws/config`. No
  guarda ninguna credencial: guarda cómo conseguirlas.
- `aws sso login` es el que se repite cada vez que la sesión caduca (por defecto, entre
  ocho y doce horas). Abre el navegador, y al volver deja un token temporal en la caché
  local. Si un comando falla de golpe con `The SSO session has expired`, este es el
  arreglo, no tocar credenciales.
- `--profile inv-lab` nombra el perfil. Ese nombre es el que después exportas en
  `AWS_PROFILE`, y es la razón por la que el lab no puede tocar por accidente los
  recursos de otra cuenta que tengas configurada.

**Usuario IAM con access keys.** Aceptable si la cuenta es personal y no hay
Identity Center. Las claves quedan en `~/.aws/credentials` en texto plano.

```bash
aws configure --profile inv-lab
```

Pide cuatro datos —access key, secret key, Region y formato de salida— y los escribe en
`~/.aws/credentials` y `~/.aws/config`. **En texto plano, sin cifrar.** Es la razón por
la que esta opción va segunda: cualquiera con acceso a tu disco tiene tus credenciales
de AWS, y no caducan solas.

**Usuario root.** Nunca para trabajo diario. Se le pone MFA, se guarda y se usa solo
para lo que exige root (cerrar la cuenta, cambiar el plan de soporte, ciertos ajustes
de facturación).

Verificación obligatoria antes de cualquier otro comando:

```bash
export AWS_PROFILE=inv-lab
export AWS_REGION=us-east-1

aws sts get-caller-identity
```

- `AWS_PROFILE` le dice a la CLI qué perfil usar sin repetir `--profile` en cada comando.
- `AWS_REGION` fija la Region de todas las llamadas. Sin ella, la CLI usa la del perfil,
  y si el perfil tampoco la tiene, falla con `You must specify a region`. Fijarla en la
  shell del lab evita el error más molesto de todos: crear medio stack en `us-east-1` y
  la otra mitad en la Region que tenías configurada de otro proyecto.
- `sts get-caller-identity` responde a "¿quién soy ahora mismo?" y devuelve tres cosas:
  el `UserId`, el número de cuenta y el ARN de la identidad efectiva.

> 💡 **Truco.** Corre este comando **antes** de cualquier sesión de lab, siempre. Cuesta
> un segundo y te ahorra descubrir a los veinte minutos que llevas creando recursos en la
> cuenta del trabajo.

```text
{
    "UserId": "AROA...:oskar",
    "Account": "111122223333",
    "Arn": "arn:aws:sts::111122223333:assumed-role/AWSReservedSSO_.../oskar"
}
```

> Punto importante: `sts get-caller-identity` no requiere ningún permiso. Si falla,
> el problema es de credenciales o de red, nunca de IAM.

⚠️ La CLI resuelve credenciales por precedencia: parámetros de línea de comandos →
variables de entorno → perfil (`AWS_PROFILE`) → credenciales de instancia/contenedor.
Una variable `AWS_ACCESS_KEY_ID` vieja exportada en la shell gana sobre el perfil y
produce errores de permisos que parecen de IAM y no lo son.

---

## 3. 🧱 Región: fijarla explícitamente

Los labs usan `us-east-1` por ser la región más barata y la primera en recibir
servicios. La decisión importa por dos razones prácticas:

- Un recurso creado por error en otra región no aparece en tus listados si consultas
  solo la región configurada. Los barridos de
  [`L04` §10](l04-observabilidad-y-destruccion-verificada.md#10--barrido-por-tag)
  recorren varias regiones por eso.
- Algunos servicios son globales pero su plano de control vive en `us-east-1`
  (facturación, Cost Explorer, IAM, CloudFront, algunas partes de Route 53).

---

## 4. 🧱 Contrato de tagging

Todos los recursos del lab llevan estos tags. En CloudFormation se aplican una sola
vez, a nivel de stack, y se propagan a los recursos que lo soportan.

| Tag | Valor | Para qué |
|---|---|---|
| `Project` | `inv-lab` | Rastreo de costo y barrido de huérfanos |
| `Lab` | `L01`…`L04` | Saber qué lab creó el recurso |
| `Owner` | tu identificador | Higiene en cuentas compartidas |
| `AutoDelete` | `true` | Marca de "esto se destruye siempre" |

```bash
aws cloudformation deploy \
  --stack-name inv-lab-base \
  --template-file base.yaml \
  --tags Project=inv-lab Lab=L01 Owner=oskar AutoDelete=true
```

> 📝 **Contexto.** Este bloque es **ilustrativo**: enseña la forma del contrato de
> tagging, no un despliegue que debas correr ahora. `L01` no crea infraestructura; el
> primer stack real es el de [`L02`](l02-cloudformation-desde-la-cli.md). Lo que importa
> aquí es que `--tags` en un `deploy` etiqueta el stack **y propaga a los recursos que lo
> soporten**, que es el mecanismo del que depende todo el barrido de
> [`L04`](l04-observabilidad-y-destruccion-verificada.md).

⚠️ No todos los servicios soportan tags, y algunos recursos creados *por* AWS (los
log groups que Lambda crea sola, por ejemplo) nacen sin tags. Por eso el barrido de
[`L04` §11](l04-observabilidad-y-destruccion-verificada.md#11--barrido-explícito-por-servicio)
combina rastreo por tag con enumeración explícita por servicio.

---

## 5. 💰 Activar los tags de asignación de costos

Un tag existe en el recurso desde que lo creas, pero **no aparece como dimensión de
costo** hasta que lo activas en facturación. Es un paso que casi todo el mundo olvida.

```bash
# ver qué claves de tag conoce el sistema de facturación
aws ce list-cost-allocation-tags --status Inactive

# activar la clave Project
aws ce update-cost-allocation-tags-status \
  --cost-allocation-tags-status TagKey=Project,Status=Active
```

- `ce` es el prefijo de Cost Explorer. Estos comandos solo funcionan desde la cuenta de
  gestión de la organización (o desde una cuenta independiente), y solo si Cost Explorer
  está habilitado — de ahí que §8 lo active.
- `--status Inactive` lista las claves que el sistema de facturación **ya vio** en algún
  recurso pero que todavía no cuentan como dimensión de costo. Si `Project` no aparece
  ahí, es que ningún recurso lo lleva todavía: crea uno etiquetado y espera unas horas.
- `--cost-allocation-tags-status TagKey=Project,Status=Active` es la sintaxis abreviada
  de la CLI para una estructura anidada; el par va sin espacios alrededor de la coma. Un
  espacio de más y obtienes un error de parseo que no dice dónde está el problema.

⚠️ La activación **no es retroactiva**: solo etiqueta el costo generado a partir de
ese momento, y puede tardar hasta 24 horas en reflejarse. Actívalo hoy aunque el
primer lab con gasto sea la semana que viene.

---

## 6. 💰 Budgets

Dos budgets, ambos gratuitos.

**Budget de gasto cero.** Avisa apenas la cuenta genere cualquier cargo.

`budget-zero.json`:

```json
{
  "BudgetName": "inv-lab-zero-spend",
  "BudgetLimit": { "Amount": "0.01", "Unit": "USD" },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

`notifications.json`:

```json
[
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 100,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      { "SubscriptionType": "EMAIL", "Address": "tu@correo.com" }
    ]
  }
]
```

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws budgets create-budget \
  --account-id "$ACCOUNT_ID" \
  --budget file://budget-zero.json \
  --notifications-with-subscribers file://notifications.json
```

- `--query Account --output text` extrae solo el número de cuenta y sin comillas. Con el
  `--output json` por defecto, `ACCOUNT_ID` valdría `"111122223333"` **con** las comillas
  incluidas y la llamada siguiente fallaría con un error de validación del ARN.
- `--account-id` es obligatorio aunque estés autenticado: la API de Budgets no lo deduce
  de tus credenciales.
- `--budget` y `--notifications-with-subscribers` van en archivos porque son estructuras
  anidadas; pasarlas inline exige escapar comillas y es una fuente inagotable de errores.
  Aquí `file://` **sí** es necesario, igual que en `create-stack`.
- El `BudgetLimit` de `0.01` con umbral del 100 % es un truco deliberado: no existe un
  budget de importe cero, así que el mínimo posible funciona como "avísame ante cualquier
  cargo".

> ⚠️ La notificación llega al correo del `Subscribers`, y **hay que confirmar** la
> suscripción desde ese correo. Un budget creado y sin confirmar no avisa de nada, y no
> hay ninguna señal en la CLI de que te falte ese paso.

**Budget mensual de $5** con avisos al 50 %, 80 % y 100 %, usando `ACTUAL` para lo ya
gastado y `FORECASTED` para lo proyectado. La diferencia entre ambos tipos es
pregunta de entrevista: `ACTUAL` avisa cuando ya gastaste, `FORECASTED` cuando la
proyección del mes supera el umbral.

```bash
aws budgets describe-budgets --account-id "$ACCOUNT_ID" \
  --query 'Budgets[].{Name:BudgetName,Limit:BudgetLimit.Amount}' --output table
```

⚠️ Un budget **notifica, no bloquea**. No existe un mecanismo nativo que apague
recursos al superar un umbral; eso se implementa con una acción de Budgets, un tema
de SNS y una Lambda, y es un ejercicio válido de
[`L03`](l03-backend-serverless-lambda-api-y-eventos.md).

---

## 7. 💰 Cost Anomaly Detection

Detecta gasto fuera de patrón sin que tengas que fijar un umbral. Sin costo.

```bash
aws ce create-anomaly-monitor --anomaly-monitor '{
  "MonitorName": "inv-lab-services",
  "MonitorType": "DIMENSIONAL",
  "MonitorDimension": "SERVICE"
}'
```

- `MonitorType: DIMENSIONAL` vigila **todos** los servicios de la cuenta a la vez, que es
  lo que quieres en una cuenta de práctica. La alternativa, `CUSTOM`, vigila un
  subconjunto que defines con reglas, y solo tiene sentido cuando ya sabes qué mirar.
- `MonitorDimension: SERVICE` es el único valor admitido para un monitor `DIMENSIONAL`.
  No es una elección: es el requisito de la API.
- El JSON va inline entre comillas simples porque es corto. En cuanto crezca, pásalo a
  archivo con `file://` como en los budgets.

Luego una suscripción con la frecuencia de alerta y el umbral de impacto en dólares.

---

## 8. 💰 Cost Explorer

Se habilita una vez por cuenta y **la primera carga de datos tarda hasta 24 horas**.
Actívalo hoy: si esperas al día del primer lab con gasto, no tendrás datos cuando los
necesites.

Consulta del gasto del proyecto, que será el comando de cierre de todos los labs:

```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-09-01,End=2026-09-30 \
  --granularity DAILY \
  --metrics UnblendedCost \
  --filter '{"Tags":{"Key":"Project","Values":["inv-lab"]}}' \
  --query 'ResultsByTime[].{Fecha:TimePeriod.Start,USD:Total.UnblendedCost.Amount}' \
  --output table
```

⚠️ Los datos de Cost Explorer tienen un retraso de aproximadamente 24 horas. La
certeza de que un lab no dejó cargos se obtiene **primero** enumerando recursos
([`L04`](l04-observabilidad-y-destruccion-verificada.md)) y **después** confirmando en
Cost Explorer a las 48 horas. Invertir ese orden
te deja un día entero pagando sin saberlo.

---

## 9. 📋 Checklist de salida

- [ ] `aws sts get-caller-identity` devuelve un rol o usuario que no es root.
- [ ] `AWS_PROFILE` y `AWS_REGION` están fijados en la shell del lab.
- [ ] Root tiene MFA y no se usa.
- [ ] Existen los dos budgets y llegó al menos un correo de confirmación.
- [ ] Cost Anomaly Detection está creado.
- [ ] Cost Explorer está habilitado.
- [ ] La clave de tag `Project` está activa como cost allocation tag.
- [ ] Tienes escrito el comando de `get-cost-and-usage` en un script reutilizable.

---

## 🧠 Preguntas rápidas

1. ¿Qué permisos requiere `sts get-caller-identity`?
2. ¿Cuál es el orden de precedencia con que la CLI resuelve credenciales?
3. ¿Por qué un tag recién creado no aparece de inmediato como dimensión en Cost Explorer?
4. ¿La activación de un cost allocation tag es retroactiva?
5. ¿Un AWS Budget puede detener el gasto automáticamente?
6. ¿Qué diferencia hay entre una notificación de budget `ACTUAL` y una `FORECASTED`?
7. ¿Cuánto retraso tienen los datos de Cost Explorer y qué implica para verificar un teardown?
8. ¿Por qué conviene fijar explícitamente la región en la shell del lab?
9. ¿Qué tipo de credencial entrega IAM Identity Center y por qué se prefiere a las access keys?
10. ¿Por qué el rastreo por tags no basta por sí solo para garantizar que no quedaron recursos vivos?

---

## 🧪 Ejercicios (12)

Todos los obligatorios cuestan **$0.00**: ninguno crea un recurso que cobre. Los que
crean algo dicen cómo se borra.

### 🟢 Fácil — la identidad efectiva (1–4)

#### 🟢 Ejercicio 1 — Leer el origen de cada ajuste

Corre `aws configure list` con el perfil del lab y después sin `AWS_PROFILE` exportado.
Anota, para cada fila, qué valor sale y de qué origen viene (`env`, `config-file`,
`iam-role`).

**Objetivo:** saber que la CLI no tiene "una" configuración, sino una resuelta por
precedencia, y poder señalar de dónde salió cada pieza antes de culpar a IAM.

#### 🟢 Ejercicio 2 — Provocar el falso `AccessDenied`

Exporta una credencial inventada (`export AWS_ACCESS_KEY_ID=AKIAINVENTADA` y su secreta),
corre `aws sts get-caller-identity` y lee el error. Después recupera la sesión con `unset`
de las tres variables y vuelve a comprobar.

**Objetivo:** reproducir a propósito el fallo más caro en tiempo de esta serie —una
variable de entorno vieja que gana sobre el perfil— para reconocerlo la próxima vez en un
segundo.

#### 🟢 Ejercicio 3 — El error de perfil inexistente

Corre `aws sts get-caller-identity --profile no-existe` y lee el mensaje completo.

**Pregunta:** ¿en qué se distingue ese error del que produce una sesión de SSO caducada, y
cuál de los dos se arregla con `aws sso login`?

#### 🟢 Ejercicio 4 — Inventario de cost allocation tags

Lista las claves de tag que el sistema de facturación ya vio pero no están activas
(`aws ce list-cost-allocation-tags --status Inactive`) y después las activas.

**Objetivo:** distinguir "el tag existe en el recurso" de "el tag cuenta como dimensión de
costo", que son dos estados distintos y solo el segundo aparece en Cost Explorer.

### 🟡 Intermedio — el blindaje, pieza a pieza (5–8)

#### 🟡 Ejercicio 5 — Un budget con aviso anticipado

Crea un budget mensual de $1 con **una notificación `FORECASTED` al 80 %**, confirma la
suscripción desde tu correo y verifica con `describe-budgets` que existe. Bórralo después
con `aws budgets delete-budget`.

**Pregunta:** con gasto real de $0.00 en el mes, ¿puede dispararse igualmente esa
notificación? ¿Qué tendría que ocurrir para que sí?

#### 🟡 Ejercicio 6 — `whoami-lab.sh`

Escribe un script que imprima cuenta, región y ARN efectivo, y que **salga con código
distinto de cero** si la cuenta no es la del lab. Úsalo como primera línea de cada sesión.

**Objetivo:** convertir la verificación de identidad en un reflejo automatizado en vez de
una buena intención.

#### 🟡 Ejercicio 7 — El gasto por servicio, no por proyecto

Consulta el gasto de los últimos siete días agrupado por `SERVICE`, sin filtrar por tag.

**Pregunta:** ¿por qué esta consulta puede mostrar servicios que tu filtro por
`Project=inv-lab` nunca enseñaría? Nombra dos tipos de recurso que caerían en ese hueco.

#### 🟡 Ejercicio 8 — Anomaly detection completo

Crea el monitor `DIMENSIONAL` de la §7 y añádele una suscripción con umbral en dólares y
frecuencia de alerta. Verifícalo con `aws ce get-anomaly-monitors` y bórralo al terminar
con `delete-anomaly-monitor`.

**Objetivo:** ver que el monitor por sí solo no avisa a nadie: sin suscripción es una
métrica que nadie mira, igual que una alarma sin `--alarm-actions`.

### 🟠 Difícil — diagnóstico (9–11)

#### 🟠 Ejercicio 9 — Tres causas para un tag que no aparece

Activaste `Project` como cost allocation tag y sigue sin verse como dimensión en Cost
Explorer. Enumera las tres causas posibles y, para cada una, **el comando o la
comprobación que la confirma o la descarta**.

**Objetivo:** separar "no se propagó todavía" de "ningún recurso lo lleva" y de "no es
retroactivo", que producen el mismo síntoma y tienen arreglos distintos.

#### 🟠 Ejercicio 10 — El budget que no avisó

Un budget existe, el gasto superó el umbral y no llegó ningún correo. Da las tres causas
más probables en orden de probabilidad y di cómo se verifica cada una.

**Pregunta:** ¿cuál de las tres no deja ninguna señal en la salida de la CLI?

#### 🟠 Ejercicio 11 — Predecir antes de mirar

Antes de correr nada, escribe cuánto crees que gastaste este mes en la cuenta y en qué
servicios. Después consúltalo agrupado por `SERVICE` y por `USAGE_TYPE`, y anota la
diferencia y su causa.

**Objetivo:** empezar a construir la intuición de costo que
[`A02` §6](a02-costos-trampas-y-recursos-huerfanos.md#6--estimar-antes-de-desplegar)
convierte en método.

### 🔴 Muy difícil — el cierre de sesión (12)

#### 🔴 Ejercicio 12 — `estado-cuenta.sh`

Escribe un script que responda en una sola pasada, con código de salida 0 o 1: ¿el
blindaje sigue puesto —los dos budgets existen, el monitor de anomalías existe, la clave
`Project` está activa— y hay algún recurso etiquetado `Project=inv-lab` vivo? Que imprima
una línea por comprobación, con `OK` o `PENDIENTE`.

**Objetivo:** tener desde el primer lab la herramienta que
[`L04` §11](l04-observabilidad-y-destruccion-verificada.md#11--barrido-explícito-por-servicio)
va a ampliar, en vez de escribirla a la carrera el día del teardown.

### 🔥 Opcionales y ampliaciones

- **Budget action.** Configura una acción de budget que aplique una policy restrictiva al
  superar el umbral, en vez de solo notificar. Requiere un rol con permisos de budgets;
  sigue costando $0.00.
- **Aviso a Slack o Telegram.** Suscribe una Lambda al tema SNS del budget y reenvía el
  aviso a un canal. La Lambda entra en la cuota *always free*, pero recuerda declarar su
  log group con retención — el problema de
  [`L03` §12](l03-backend-serverless-lambda-api-y-eventos.md#12--los-log-groups-se-declaran-no-se-heredan).
- **Segunda cuenta.** Repite el blindaje completo en una cuenta distinta cronometrando el
  proceso. Si tardas más de quince minutos, es que el blindaje todavía no está escrito
  como script.

### 💀 Boss fight — `blindaje.sh`, idempotente y verificable

Escribe un único script que deje **una cuenta de AWS recién creada** en el estado de
salida de este lab, y que pueda volver a correrse sobre una cuenta ya blindada sin
duplicar nada ni fallar.

Tiene que: comprobar la identidad y abortar si es root; fijar región y perfil; crear los
dos budgets con sus suscripciones si no existen; crear el monitor de anomalías si no
existe; activar `Project` como cost allocation tag; y terminar imprimiendo un resumen de
qué creó y qué encontró ya hecho. Sin salida interactiva y sin tocar la consola.

**Objetivo:** el artefacto que hace que el resto de la serie sea repetible. Si dentro de
seis meses abres otra cuenta para practicar, el blindaje es un comando y no una tarde.

**Criterio de terminado:** dos ejecuciones seguidas producen exactamente el mismo estado
final, la segunda no crea nada, y el costo total sigue siendo $0.00.

---

## 🏁 La señal de que quedó bien

> Abro una terminal nueva, corro `aws sts get-caller-identity` y sé sin dudar en qué
> cuenta y con qué identidad estoy antes de escribir un solo comando que cree algo. Si
> mañana alguien enciende un recurso caro en esta cuenta, me entero por correo y no por
> la factura del mes.

---

## 📚 Referencias oficiales

- AWS CLI configuración y precedencia de credenciales: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html
- Configurar IAM Identity Center en la CLI: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html
- `sts get-caller-identity`: https://docs.aws.amazon.com/STS/latest/APIReference/API_GetCallerIdentity.html
- AWS Budgets: https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html
- Budget actions: https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-controls.html
- Cost allocation tags: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html
- Activar cost allocation tags definidas por el usuario: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/activating-tags.html
- Cost Anomaly Detection: https://docs.aws.amazon.com/cost-management/latest/userguide/manage-ad.html
- Cost Explorer: https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html
- Etiquetado de recursos AWS: https://docs.aws.amazon.com/tag-editor/latest/userguide/tagging.html
- Mejores prácticas de seguridad para el usuario root: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
