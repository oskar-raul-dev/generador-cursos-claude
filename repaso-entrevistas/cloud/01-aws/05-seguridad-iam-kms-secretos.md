# 05 — Seguridad: IAM, políticas, KMS y secretos

> **Objetivo:** resolver de memoria un `AccessDenied` —qué política falta, cuál niega,
> quién asume qué rol— y separar la autorización entre servicios de la de usuarios finales.
> **Se asume leído:** [`01`](01-infraestructura-global-y-redes.md) y
> [`02`](02-computo-contenedores-y-balanceo.md).
> **Se conecta con:** [`08`](08-observabilidad-auditoria-gobierno.md) (CloudTrail para
> auditar quién hizo qué) y [`L03`](l03-backend-serverless-lambda-api-y-eventos.md)
> (execution role frente a resource-based policy, en la práctica).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Shared Responsibility Model](#1--shared-responsibility-model) · [IAM — Identity and Access Management](#2--iam--identity-and-access-management) · [Root User](#3--root-user) · [IAM User](#4--iam-user) · [IAM Group](#5--iam-group) · [IAM Role](#6--iam-role) · [STS — Security Token Service](#7--sts--security-token-service) · [IAM Policy](#8--iam-policy) · [Identity-based vs resource-based policies](#9--identity-based-vs-resource-based-policies) · [Trust Policy de un Role](#10--trust-policy-de-un-role) · [Policy evaluation — reglas mentales](#11--policy-evaluation--reglas-mentales) · [Least Privilege](#12--least-privilege) · [ARN — Amazon Resource Name](#13--arn--amazon-resource-name) · [MFA](#14--mfa) · [IAM Identity Center — idea base](#15--iam-identity-center--idea-base) · [Cognito — User Pools e Identity Pools](#16--cognito--user-pools-e-identity-pools) · [JWT Authorizers en API Gateway](#17--jwt-authorizers-en-api-gateway) · [OAuth2/OIDC — patrones de autenticación de API](#18--oauth2oidc--patrones-de-autenticación-de-api) · [Encryption at rest vs in transit](#19--encryption-at-rest-vs-in-transit) · [KMS — Key Management Service](#20--kms--key-management-service) · [KMS Key Policy](#21--kms-key-policy) · [Envelope Encryption — concepto](#22--envelope-encryption--concepto) · [Secrets Manager](#23--secrets-manager) · [Secrets Manager vs Parameter Store](#24--secrets-manager-vs-parameter-store) · [Security Groups también son seguridad](#25--security-groups-también-son-seguridad) · [WAF y Shield — bases](#26--waf-y-shield--bases) · [Organizations, SCP y estrategia multi-cuenta](#27--organizations-scp-y-estrategia-multi-cuenta) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

# Parte I — Identidad y acceso

## 1. 🧭 Shared Responsibility Model

Modelo mental:

```text
AWS        → security OF the cloud
Customer   → security IN the cloud
```

El límite exacto cambia según el servicio.

Ejemplo:

### EC2

AWS administra:

- datacenter;
- hardware;
- hypervisor/base cloud infrastructure.

Tú administras mucho más:

- guest OS;
- patching del guest;
- software;
- firewall rules;
- IAM;
- data;
- encryption choices.

### Fargate/Lambda/RDS

AWS administra más capas, pero tú sigues siendo responsable de identidad, datos, configuración, permisos y arquitectura segura.

---

## 2. 🧱 IAM — Identity and Access Management

IAM responde fundamentalmente:

```text
¿QUIÉN puede hacer QUÉ sobre QUÉ recurso bajo QUÉ condiciones?
```

Conceptos:

- principals;
- users;
- groups;
- roles;
- policies;
- actions;
- resources;
- conditions.

---

## 3. 🧱 Root User

La cuenta AWS tiene un root user con privilegios extremadamente altos.

Buenas prácticas:

- protegerlo con MFA;
- no usarlo para trabajo diario;
- no crear access keys de root salvo necesidad extraordinaria específica;
- guardar recuperación de forma segura.

---

## 4. 🧱 IAM User

Identidad de largo plazo dentro de una cuenta.

Puede tener:

- credenciales de consola;
- access keys programáticas;
- policies.

En organizaciones modernas AWS recomienda favorecer federación/IAM Identity Center y credenciales temporales frente a proliferación de users/access keys de largo plazo.

---

## 5. 🧱 IAM Group

Agrupa IAM users para asignar permisos comunes.

```text
Developers group
├── user A
├── user B
└── user C
```

Un group no es un principal asumible por workloads; es una forma de administrar permisos de users.

---

## 6. 🧱 IAM Role

Identidad asumible con credenciales temporales.

Casos:

- EC2 necesita leer S3;
- ECS Task necesita consumir SQS;
- Lambda necesita escribir DynamoDB;
- usuario de otra cuenta necesita acceso temporal;
- federated identity.

Ejemplo:

```text
ECS Task
   │ assume/use task role
   ▼
IAM Role
   │
   └── s3:GetObject sobre bucket específico
```

Evita:

```text
AWS_ACCESS_KEY_ID hardcodeado en Docker image
AWS_SECRET_ACCESS_KEY hardcodeado en Git
```

---

## 7. 🧱 STS — Security Token Service

AWS STS emite credenciales temporales.

Conceptos relacionados:

- `AssumeRole`;
- role sessions;
- temporary access key;
- secret key;
- session token.

La temporalidad reduce riesgo frente a credenciales permanentes y es pieza central de roles/federación.

---

## 8. 🧱 IAM Policy

Documento JSON que expresa permisos.

Ejemplo simplificado:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

Elementos:

```text
Effect
Action
Resource
Condition
Principal  ← aparece en resource-based/trust policies según tipo
```

---

## 9. ⚖ Identity-based vs resource-based policies

### Identity-based

Adjunta a:

- user;
- group;
- role.

Dice qué puede hacer esa identidad.

### Resource-based

Adjunta al recurso compatible.

Ejemplos:

- S3 bucket policy;
- SQS queue policy;
- KMS key policy;
- Secrets Manager resource policy;
- Lambda resource policy.

Dice qué principals pueden operar sobre el recurso.

La distinción no es académica: decide **dónde tienes que ir a arreglar un
`AccessDenied`**. Si el problema es identity-based, el permiso falta en el rol de quien
llama; si es resource-based, el rol está bien y quien no te conoce es el recurso. Y hay
un tercer caso que confunde a mucha gente: cuando un servicio de AWS invoca a otro por
ti —API Gateway llamando a tu Lambda, S3 disparando una función—, el execution role del
destino **no interviene en absoluto** en esa autorización de entrada; lo que hace falta
es la resource-based policy del destino. Es la costura que
[`L03` §7](l03-backend-serverless-lambda-api-y-eventos.md#7--http-api-y-el-permiso-que-sí-hace-falta)
practica provocando el fallo a propósito.

La otra consecuencia es la de cuentas cruzadas: una resource-based policy puede nombrar a
un principal de otra cuenta, y una identity-based no puede dar acceso a lo que no es
suyo. Por eso compartir un bucket entre cuentas se resuelve en el bucket, no en el rol.

---

## 10. 🧱 Trust Policy de un Role

Un IAM Role tiene una trust policy que responde:

```text
¿QUIÉN puede asumir este role?
```

Mientras que sus permission policies responden:

```text
¿QUÉ puede hacer una vez asumido?
```

Esta es una distinción frecuente de entrevista, y la razón de que lo sea es que los dos
documentos fallan con errores que no se parecen en nada. Si la trust policy está mal
—pusiste `ec2.amazonaws.com` donde iba `lambda.amazonaws.com`—, el rol se crea sin
protestar y el fallo aparece al arrancar, sin mencionar la palabra "trust" por ningún
lado. Si lo que está mal son las permission policies, el servicio arranca perfectamente
y revienta más tarde, al tocar el recurso, con un `AccessDenied` que sí dice qué acción
faltó.

> 🧠 **Modelo mental.** La trust policy es la lista de invitados de la fiesta; las
> permission policies son lo que te dejan tocar una vez dentro. Que te dejen entrar no
> dice nada sobre si puedes abrir la nevera.

---

## 11. 🧭 Policy evaluation — reglas mentales

Son las tres líneas que hay que poder recitar cuando alguien te enseña un `AccessDenied`
y pregunta por qué:

```text
Default → DENY
explicit ALLOW → puede permitir
explicit DENY → gana sobre ALLOW
```

El orden importa porque describe cómo se resuelve un conflicto. Que el default sea deny
significa que **nadie tiene que negarte nada para que falles**: basta con que ningún
Allow aplicable te alcance, y ese es el caso del 90 % de los `AccessDenied` reales —no
hay una policy malvada bloqueándote, hay una policy que no escribiste—. Que el explicit
deny gane siempre significa lo contrario: cuando sí existe uno, no hay Allow, por amplio
que sea, que lo revierta. Un `Action: "*"` de administrador no supera un deny de un SCP.

Pero AWS evalúa múltiples capas y tipos de policy, incluidos según caso:

- identity-based policies;
- resource-based policies;
- permissions boundaries;
- Organizations SCP/RCP;
- session policies;
- service-specific controls.

La regla que hace inteligible esa lista es que casi todas funcionan como **filtros que
recortan**, no como concesiones que suman: un permissions boundary o un SCP nunca dan
permiso, solo definen el techo de lo que las policies de dentro pueden llegar a dar. Por
eso una identidad con `AdministratorAccess` en una cuenta bajo un SCP restrictivo se
queda sin poder hacer lo que su policy dice que puede: el Allow existe, pero está por
encima del techo.

La excepción que conviene tener presente es el acceso cross-account: ahí no basta con
que una de las dos partes diga que sí. La cuenta de origen tiene que permitir la acción
a su identidad **y** el recurso de destino tiene que permitir a ese principal, en su
resource-based policy. Dos Allow, en dos cuentas. Es el caso que más veces se responde
mal.

No reduzcas todos los escenarios cross-account a una sola regla de tres líneas. Para
entrevista básica sí debes recordar que **explicit deny tiene prioridad**.

---

## 12. 🧭 Least Privilege

Principio:

> Otorga solamente las acciones necesarias, sobre los recursos necesarios, bajo las
> condiciones necesarias.

Malo:

```json
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}
```

Mejor:

```text
Action   → sqs:ReceiveMessage, sqs:DeleteMessage
Resource → ARN de la cola concreta
```

Lo que hace difícil el principio no es entenderlo, es que el atajo siempre funciona y la
versión correcta a veces no: `"*"` desbloquea el despliegue de esta noche, y nadie vuelve
a mirarlo. Por eso conviene saber decir qué se pierde exactamente. Con `"*"`, una
credencial filtrada de esa función deja de ser "acceso a una cola" y pasa a ser acceso a
la cuenta; y el permiso deja de documentar nada, porque ya no puedes leer el rol para
saber con qué habla el servicio.

La forma práctica de llegar ahí no es adivinar la lista de acciones desde cero, sino
apretar después: se empieza por lo que hace falta para que arranque, se deja correr, y
se recorta con lo que CloudTrail dice que la función usó de verdad. AWS recomienda
iterar hacia least privilege y usar herramientas como IAM Access Analyzer, que genera
políticas a partir de esa actividad registrada.

> 💡 **Truco.** Antes de desplegar un recorte, compruébalo en frío con
> `aws iam simulate-principal-policy`: evalúa la decisión sin ejecutar la acción. En
> [`L04` §7](l04-observabilidad-y-destruccion-verificada.md#7--cloudtrail-para-diagnosticar-un-accessdenied)
> se usa exactamente así.

---

## 13. 🧱 ARN — Amazon Resource Name

Identificador de recurso AWS.

Forma conceptual:

```text
arn:partition:service:region:account-id:resource
```

Ejemplos varían por servicio.

Debes poder reconocer que IAM `Resource` suele apuntar a ARN(s).

---

## 14. 🧱 MFA

Multi-Factor Authentication agrega un factor adicional al autenticarse.

Prioridad alta para:

- root;
- identidades humanas privilegiadas;
- acciones administrativas sensibles.

---

## 15. 🧭 IAM Identity Center — idea base

Servicio para workforce access/federación y acceso centralizado a cuentas y aplicaciones.

En organizaciones modernas evita administrar cientos de IAM users independientes por cuenta.

Mentalidad:

```text
Human workforce → federation / Identity Center
Workload        → IAM Role
```

---

## 16. 🧱 Cognito — User Pools e Identity Pools

Cognito resuelve identidad para *usuarios finales* de una aplicación, no para que un servicio AWS actúe sobre otro — eso ya es IAM Role.

```text
IAM Role → "esta ECS Task puede leer este bucket"
Cognito  → "este usuario final puede iniciar sesión y usar mi API"
```

### User Pools

Directorio de usuarios administrado: sign-up/sign-in, MFA, verificación de email/teléfono, y emisión de tokens JWT tras autenticar.

```text
User
  │ sign-in
  ▼
Cognito User Pool
  │ emite
  ▼
ID token / Access token / Refresh token (JWT)
```

### Identity Pools

Otorgan credenciales temporales de AWS (vía STS) a usuarios autenticados —o incluso no autenticados, con guest access— para que puedan invocar servicios AWS directamente.

```text
User autenticado en User Pool
       │
       ▼
Identity Pool
       │ AssumeRoleWithWebIdentity
       ▼
credenciales temporales STS
       │
       ▼
llamada directa a S3/DynamoDB con permisos del IAM Role asociado
```

Regla:

```text
User Pool     → quién es el usuario (autenticación)
Identity Pool → qué credenciales de AWS recibe ese usuario (autorización hacia AWS)
```

No digas "Cognito es solo un login gratis". Mejor:

> Cognito separa la autenticación de usuario final (User Pool) de la obtención de credenciales temporales de AWS (Identity Pool); un backend puede usar solo el primero y validar el JWT él mismo.

---

## 17. 🧱 JWT Authorizers en API Gateway

Un JWT authorizer permite que API Gateway valide el token antes de invocar el backend, sin que cada Lambda/servicio reimplemente esa validación.

```text
Client
  │ Authorization: Bearer <JWT>
  ▼
API Gateway
  │ valida firma/issuer/audience/expiración
  ├── inválido → 401 sin invocar backend
  └── válido  → invoca integration (Lambda/HTTP)
```

Tipos de authorizer relevantes en API Gateway:

- **JWT authorizer** (nativo en HTTP APIs): valida tokens emitidos por un issuer OIDC compatible (por ejemplo, un Cognito User Pool) sin código propio.
- **Lambda authorizer**: código propio que decide autorización a partir del request completo — más flexible, más responsabilidad propia.

| Necesidad | JWT authorizer | Lambda authorizer |
|---|---:|---:|
| Validar JWT estándar (issuer/audience/exp) | ✅ | ✅ (a mano) |
| Lógica de autorización custom (roles, claims propios, llamadas externas) | | ✅ |
| Menor código propio | ✅ | |
| Reutilizar en varias rutas | ✅ | ✅ |

No confundir con IAM authorization de API Gateway (`AWS_IAM`), que autoriza llamadas firmadas con SigV4 de principals IAM — otro mecanismo, para otro tipo de consumidor (servicio a servicio, no usuario final típico).

---

## 18. 🧱 OAuth2/OIDC — patrones de autenticación de API

Vocabulario mínimo que un entrevistador espera reconocer, aunque el curso no cubra OAuth2 a fondo como especificación:

```text
Resource Owner        → el usuario
Client                → la aplicación que pide acceso
Authorization Server  → emite tokens (un Cognito User Pool puede cumplir este rol)
Resource Server       → tu API, que valida el token
```

OIDC (OpenID Connect) es una capa de identidad sobre OAuth2: agrega el **ID token** (JWT que identifica al usuario) sobre el **access token** (que autoriza llamadas a recursos).

```text
OAuth2 → autorización ("puede hacer X")
OIDC   → identidad sobre OAuth2 ("es el usuario Y")
```

Flujo típico backend/SPA con Cognito como Authorization Server:

```text
SPA
 │ redirige a login
 ▼
Cognito Hosted UI (Authorization Server)
 │ usuario autentica
 ▼
SPA recibe ID token + access token
 │ Authorization: Bearer <access token>
 ▼
API Gateway (JWT authorizer) → backend
```

Regla de entrevista:

```text
No repitas OAuth2 = login.
OAuth2 es un framework de autorización delegada; el login es solo una parte del flujo.
```

---

# Parte II — Cifrado, secretos y gobierno

## 19. ⚖ Encryption at rest vs in transit

### At rest

Datos almacenados cifrados.

Ejemplos:

- S3 encryption;
- EBS encrypted volumes;
- RDS encryption;
- DynamoDB encryption.

### In transit

Datos cifrados mientras viajan.

Ejemplo:

```text
HTTPS/TLS
```

No son sustitutos: normalmente quieres ambos según sensibilidad.

---

## 20. 🧱 KMS — Key Management Service

Servicio administrado para crear/controlar claves criptográficas y realizar operaciones criptográficas integradas con servicios AWS.

Modelo:

```text
Data
 │
 ▼
AWS service/app
 │
 ▼
KMS key authorization + cryptographic operation
```

Conceptos:

- KMS key;
- key policy;
- IAM policy;
- grants;
- aliases;
- rotation/configuration según key type;
- encryption context.

---

## 21. 🧱 KMS Key Policy

Cada KMS key tiene una **key policy**, y es el caso donde la regla general de IAM no
aplica igual: en el resto de servicios basta con que la identity-based policy conceda el
permiso, pero una KMS key **empieza denegando a todo el mundo salvo a quien su key policy
nombre**, sin importar lo que digan las policies de la identidad.

Punto importante:

> En KMS no basta con memorizar “IAM policy”. La key policy es fundamental y determina
> cómo pueden participar IAM policies y principals.

De ahí sale un fallo muy típico y desconcertante: un rol con `AdministratorAccess` que no
puede descifrar un objeto de S3. La policy del rol lo permite todo, pero la key policy no
lo nombra, y en KMS eso equivale a un no. La comprobación correcta es mirar los dos
documentos, no solo el del rol.

> ⚠️ El reverso también muerde: una key policy que solo nombra a un usuario que después
> se elimina deja la clave **inaccesible de forma permanente** —ni siquiera el root de la
> cuenta puede recuperarla—, y con ella todo lo que estuviera cifrado. Por eso la key
> policy por defecto delega en el root de la cuenta: no es descuido, es la salida de
> emergencia.

AWS recomienda least privilege también para administración y uso de keys, y ahí la
distinción que importa es entre quién **administra** la clave (rotarla, cambiar su
policy, programar su borrado) y quién solo la **usa** para cifrar y descifrar. Son
conjuntos distintos de personas y casi nunca deberían coincidir.

---

## 22. 🧱 Envelope Encryption — concepto

Hay un motivo por el que no cifras tus datos llamando a KMS directamente: la API de KMS
acepta como mucho unos pocos kilobytes por llamada, y aunque aceptara más, mandar cada
archivo por la red a un servicio externo para cifrarlo sería lento, caro y un punto único
de fallo en el camino de tus datos. El **envelope encryption** es la solución a ese
problema.

Patrón:

```text
KMS key
   │ protege
   ▼
Data key
   │ cifra
   ▼
Bulk data
```

Funciona así: pides a KMS una data key y te la devuelve dos veces, en claro y cifrada.
Cifras tus gigabytes localmente con la copia en claro, la borras de memoria, y guardas la
versión cifrada al lado de los datos. Para descifrar, mandas a KMS solo esa data key
—unos bytes— y con lo que te devuelve descifras localmente.

Lo que compras con ese rodeo es lo que hace que valga la pena: los datos nunca viajan a
KMS, el cifrado va a velocidad local, y aun así el control de acceso sigue centralizado
en la key policy — porque sin poder descifrar la data key, tener el archivo cifrado no
sirve de nada. Es también lo que permite el borrado criptográfico: destruir la KMS key
vuelve ilegibles todos los datos que dependían de ella, sin tocar un solo archivo.

Servicios y SDKs de AWS hacen esto por debajo sin que lo pidas: es lo que ocurre cuando
marcas "cifrado con KMS" en un bucket de S3 o en un volumen EBS.

---

## 23. 🧱 Secrets Manager

Servicio para almacenar, recuperar y rotar secretos.

Ejemplos:

- DB password;
- API key;
- third-party credential.

Patrón:

```text
Application
    │ IAM Role
    ▼
Secrets Manager
    │
    ▼
secret value
```

No hardcodear secretos en:

- source code;
- Dockerfile;
- AMI;
- CloudFormation plaintext parameters;
- repositorio Git.

---

## 24. ⚖ Secrets Manager vs Parameter Store

Ambos pueden almacenar configuración sensible, pero mentalmente:

### Secrets Manager

- secret lifecycle;
- rotación integrada para casos compatibles;
- recursos/policies específicos de secretos;
- diseñado explícitamente para secrets.

### Systems Manager Parameter Store

- parámetros/configuración jerárquica;
- `String`, `StringList`, `SecureString`;
- útil para configuración centralizada.

No memorices “uno siempre es mejor”; escoge según rotación, lifecycle, costo, integración
y necesidades. En la práctica hay dos criterios que resuelven casi todos los casos.

El primero es la **rotación**. Si el secreto tiene que cambiar solo cada N días —y sobre
todo si además hay que actualizar la contraseña en la base de datos al mismo tiempo—,
Secrets Manager trae ese mecanismo hecho, con integración nativa para RDS. Parameter
Store guarda el valor cifrado igual de bien, pero rotarlo es código tuyo.

El segundo es el **costo**, que decide más discusiones de las que parece: los parámetros
estándar de Parameter Store no tienen cargo, mientras que Secrets Manager cobra por
secreto y mes más las llamadas a la API. Para un puñado de credenciales de producción es
irrelevante; para trescientos parámetros de configuración de veinte servicios, no. De ahí
la regla práctica del laboratorio de este curso: **Parameter Store por defecto, Secrets
Manager cuando la rotación automática justifica su precio** — el razonamiento económico
completo está en
[`A02` §4](a02-costos-trampas-y-recursos-huerfanos.md#4--lo-que-cobra-por-almacenar).

> ⚠️ Un `SecureString` de Parameter Store se cifra con KMS igual que un secreto, así que
> la diferencia entre ambos **no es la seguridad del almacenamiento**. Responder "uso
> Secrets Manager porque Parameter Store no cifra" es incorrecto.

---

## 25. 🧱 Security Groups también son seguridad

IAM controla principalmente autorización de API/recursos.

Security Groups controlan networking.

No confundir:

```text
IAM → “¿puede esta Lambda llamar s3:GetObject?”
SG  → “¿puede este origen abrir TCP 5432 hacia RDS?”
```

Una arquitectura segura necesita ambas capas.

---

## 26. 🧱 WAF y Shield — bases

### AWS WAF

Filtrado Layer 7 para tráfico web compatible.

Casos:

- reglas por IP;
- patrones de request;
- managed rules;
- mitigación de ataques web comunes.

### AWS Shield

Protección DDoS. Shield Standard viene integrado para recursos AWS soportados; Shield Advanced agrega capacidades/servicios superiores para escenarios que lo requieran.

No reemplazan Security Groups/IAM.

---

## 27. 🧱 Organizations, SCP y estrategia multi-cuenta

### Por qué múltiples cuentas

Antes de llegar a SCP, la pregunta de entrevista real suele ser "¿por qué no todo en una sola cuenta?". Razones típicas:

```text
Blast radius  → un incidente/compromiso en una cuenta no se propaga automáticamente a otras
Billing       → separar costo por equipo/producto/ambiente sin tagging heroico
Compliance    → aislar datos/cargas reguladas en cuentas con controles propios
Autonomía     → cada equipo administra su cuenta sin pisar límites de otros
```

No es "una cuenta por microservicio" ni "una cuenta para toda la empresa": el diseño típico separa al menos por ambiente (`prod`/`non-prod`) y por dominio de riesgo/compliance.

### AWS Organizations

Permite administrar múltiples cuentas AWS de forma centralizada: creación de cuentas, agrupación en Organizational Units (OU), políticas aplicadas por OU, consolidated billing.

```text
Organization
├── OU Security
│   └── cuenta de logging/audit
├── OU Workloads
│   ├── cuenta prod
│   └── cuenta non-prod
└── OU Sandbox
    └── cuentas de desarrollo individual
```

### Service Control Policies — SCP

Service Control Policies pueden limitar el máximo conjunto de permisos disponible para cuentas/OUs afectadas.

Regla importante:

> Un SCP **no otorga permisos por sí solo**; establece guardrails/límites. La identidad todavía necesita un Allow aplicable dentro de la cuenta.

### Control Tower y landing zone — idea base

AWS Control Tower automatiza el establecimiento de una **landing zone**: una estructura multi-cuenta con OUs, SCP base y cuentas de log archive/audit preconfiguradas, en vez de construirla manualmente con Organizations.

```text
Organizations → primitiva de administración multi-cuenta
Control Tower → capa de automatización sobre Organizations para levantar una landing zone
```

No reemplaza el diseño de SCP/OU específico del negocio; da un punto de partida gobernado.

---

## 🧠 Preguntas rápidas

1. ¿IAM User vs Role?
2. ¿Trust policy vs permission policy?
3. ¿Por qué preferir temporary credentials?
4. ¿Qué significa default deny?
5. ¿Qué ocurre con explicit deny?
6. ¿Identity-based vs resource-based policy?
7. ¿Qué es least privilege?
8. ¿IAM vs Security Group?
9. ¿KMS key policy vs IAM policy?
10. ¿Qué es envelope encryption?
11. ¿Qué resuelve Secrets Manager que no resuelve un secreto escrito en el código?
12. ¿SCP concede permisos?
13. ¿Qué diferencia a un Cognito User Pool de un Identity Pool?
14. ¿Un JWT authorizer de API Gateway reemplaza a IAM authorization (`AWS_IAM`)?
15. ¿Qué agrega OIDC sobre OAuth2?
16. ¿Por qué usar múltiples cuentas AWS en vez de una sola?
17. ¿Control Tower reemplaza a Organizations?

---

## 📚 Referencias oficiales

- IAM: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html
- IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Least privilege: https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started-reduce-permissions.html
- Policy evaluation: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- IAM Roles: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
- Credenciales temporales y STS: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html
- KMS: https://docs.aws.amazon.com/kms/latest/developerguide/overview.html
- KMS least privilege: https://docs.aws.amazon.com/kms/latest/developerguide/least-privilege.html
- Secrets Manager: https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html
- Secrets Manager IAM: https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_iam-policies.html
- Parameter Store: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html
- WAF: https://docs.aws.amazon.com/waf/latest/developerguide/what-is-aws-waf.html
- Shield: https://docs.aws.amazon.com/waf/latest/developerguide/shield-chapter.html
- Organizations SCP: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
- Cognito User Pools: https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools.html
- Cognito Identity Pools: https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-identity.html
- API Gateway JWT authorizers: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html
- API Gateway Lambda authorizers: https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html
- AWS Organizations: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html
- AWS Control Tower: https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html
- Formato de un ARN: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference-arns.html
- STS AssumeRole: https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
- Conceptos de KMS y envelope encryption: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html
- Rotación de secretos: https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html
