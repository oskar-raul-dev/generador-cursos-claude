# 05 — Seguridad, IAM, jerarquía, KMS y secretos

> **Objetivo:** entender cómo se evalúa un permiso en GCP —dónde vive el binding, cómo se hereda,
> qué contiene un rol— y el vocabulario de cifrado, secretos y gobierno que lo rodea.
> **Se asume leído:** [`01` — infraestructura global y redes](01-infraestructura-global-y-redes.md).
> **Se toca sobre todo con:** [`01`](01-infraestructura-global-y-redes.md) y
> [`08` — observabilidad, auditoría y gobierno](08-observabilidad-auditoria-gobierno.md).
> **Dónde se practica:** [`L02` — IAM: allow policies, service accounts e impersonation](l02-iam-allow-policies-service-accounts-e-impersonation.md),
> que provoca un `PERMISSION_DENIED` a propósito y lo resuelve con Policy Troubleshooter.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Jerarquía de recursos](#2--jerarquía-de-recursos) · [Cloud IAM](#3--cloud-iam--conceptos-base) · [Cloud KMS](#4--cloud-kms) ·
[Envelope encryption](#6--envelope-encryption) · [Secret Manager](#10--secret-manager) · [Rotación de credenciales](#12--rotación-de-credenciales) ·
[Cloud Armor](#15--cloud-armor) · [Resource Manager](#18--resource-manager) · [Organization Policies](#19--organization-policies) ·
[Centralización](#21--centralización-de-seguridad) · [Preguntas rápidas](#-preguntas-rápidas)

## 1. 🧭 Shared Fate

Google Cloud describe su modelo de seguridad como **shared fate**, un
paso adelante respecto a un modelo de responsabilidad compartida
puramente delimitador. En shared fate, Google no solo traza la línea de
"esto es tuyo, esto es mío": asume compromisos activos para que la
configuración por defecto sea segura, ofrece guardrails (Organization
Policies, blueprints, landing zones) y apoyo para operar de forma segura,
en lugar de limitarse a documentar dónde termina su responsabilidad.

```text
Shared responsibility clásico → línea divisoria de responsabilidad
Shared fate                   → Google además ayuda activamente a que tu configuración sea segura por defecto
```

---

# Parte I — Jerarquía de recursos y Cloud IAM

## 2. 🧱 Jerarquía de recursos

```text
Organization
└── Folder (ej. "Production")
    └── Project (ej. "backend-prod")
        └── Resources (Compute Engine, Cloud Storage, ...)
```

- **Organization**: raíz de la jerarquía, asociada normalmente a un
  dominio.
- **Folder**: agrupa Projects (y otros Folders), típicamente por equipo,
  ambiente o unidad de negocio.
- **Project**: unidad de facturación, cuotas, APIs habilitadas y límite
  de la mayoría de los recursos.
- **Resource**: los recursos concretos (VMs, buckets, bases de datos...)
  dentro de un Project.

### Herencia de políticas

Tanto las **allow policies** de IAM como las **Organization Policies**
heredan hacia abajo en la jerarquía: una política aplicada en Organization
o Folder afecta a todo lo que está debajo, salvo que una política más
específica la modifique según las reglas de cada tipo de política.

> Casi todo en GCP vive dentro de un Project: facturación, cuotas y APIs
> habilitadas se administran a ese nivel. No se puede desplegar un
> recurso "suelto" fuera de un Project.

## 3. 🧱 Cloud IAM — conceptos base

### Members

Quién puede actuar: usuarios individuales, grupos, Service Accounts,
dominios completos.

### Roles

| Tipo | Descripción |
|---|---|
| Primitive | `Owner`, `Editor`, `Viewer` — muy amplios, heredados de versiones tempranas de GCP |
| Predefined | Roles curados por Google para un servicio/caso de uso específico (ej. `roles/storage.objectViewer`) |
| Custom | Definidos por el proyecto/organización, combinando exactamente los permisos necesarios |

```text
Primitive role vs Predefined role vs Custom role
```

> Evita primitive roles en producción. `Editor` otorga permisos de
> escritura sobre prácticamente todos los recursos del proyecto — mucho
> más de lo que necesita, por ejemplo, un pipeline de CI que solo debe
> poder desplegar en Cloud Run.

### Permissions

La unidad más granular (ej. `storage.objects.get`). Un rol es un conjunto
de permissions.

### Allow policies

Un **allow policy** es el conjunto de bindings `member + role` aplicados
sobre un recurso. Las allow policies son **aditivas**: si dos bindings
distintos (en el mismo recurso o heredados desde arriba en la jerarquía)
otorgan permisos a un member, ese member tiene la unión de ambos. No
existe, dentro de una allow policy, un mecanismo para negar
explícitamente lo que otro binding ya concedió.

```text
Allow policy vs Deny policy
```

### IAM Conditions

Permiten condicionar un binding — por ejemplo, que solo aplique antes de
una fecha, sobre un subconjunto de recursos, o cuando un tag específico
esté presente.

### Service Accounts

Identidad no humana usada por aplicaciones y cargas de trabajo. Una
aplicación en Compute Engine, GKE o Cloud Run debe preferir una **Service
Account adjunta** al recurso, en lugar de descargar y almacenar:

```text
service-account-key.json
```

en código, repositorios o imágenes de contenedor. Una key descargada es
una credencial de larga vida que, si se filtra, queda expuesta hasta que
alguien la rote o revoque manualmente.

### Workload Identity Federation y Workload Identity

| | Workload Identity Federation | Workload Identity (GKE) |
|---|---|---|
| Para qué | Cargas **fuera** de GCP (otra nube, on-premises, CI/CD externo) que necesitan actuar como una identidad de GCP sin key descargada | Pods dentro de GKE que necesitan actuar como una Service Account de GCP sin montar una key como Secret |
| Mecanismo | Federa una identidad externa (ej. OIDC de un proveedor de CI) con permisos de GCP | Asocia una Kubernetes Service Account con una Service Account de GCP |

```text
Service Account vs usuario humano
Workload Identity Federation vs llave de Service Account descargada
```

### Principle of Least Privilege

Otorgar exactamente los permisos necesarios, ni más — el criterio rector
al elegir entre primitive, predefined y custom roles.

### IAM Deny policies

Las allow policies son aditivas y no tienen "deny explícito" propio. Para
negar de forma explícita, existe un mecanismo separado: **IAM Deny
policies**, evaluadas **antes** que cualquier allow policy — un deny
policy aplicable bloquea el acceso sin importar qué allow policy lo
permitiría.

```text
Regla de entrevista:
Un allow policy nunca "quita" lo que otro allow policy concedió.
Solo una IAM Deny policy puede bloquear explícitamente.
```

---

# Parte II — KMS y cifrado

## 4. 🧱 Cloud KMS

**Cloud KMS** administra claves criptográficas y las operaciones que las
usan (cifrar, descifrar, firmar).

- **Key rings**: agrupan keys, típicamente por región/proyecto/equipo.
- **Keys**: simétricas (para cifrar/descifrar) o asimétricas (para
  firmar/verificar, o cifrar/descifrar con par público/privado).

## 5. 🧱 Encryption at rest y in transit

```text
Encryption at Rest
vs
Encryption in Transit
```

| | At rest | In transit |
|---|---|---|
| Qué protege | Datos almacenados (disco, bucket, base de datos) | Datos moviéndose entre cliente/servicio o servicio/servicio |
| Mecanismo típico | Cifrado por defecto en todos los servicios de almacenamiento de GCP | TLS |

Todos los servicios de almacenamiento de GCP cifran datos en reposo **por
defecto**, sin configuración adicional.

## 6. 🧱 Envelope encryption

Patrón donde una clave de KMS (la **key encryption key**) cifra una clave
de datos (**data encryption key**) más pequeña, y es esa data key la que
cifra el volumen real de datos — en lugar de mandar cada byte de datos
directamente a KMS.

```text
Datos ── cifrados por ──► Data Encryption Key ── cifrada por ──► Cloud KMS key
```

## 7. 🧱 CMEK y CSEK

| | CMEK | CSEK |
|---|---|---|
| Quién controla la key | Tú, administrada dentro de Cloud KMS | Tú, la aportas directamente en cada operación |
| Nivel de integración | Alta (rotación, IAM sobre la key, auditoría vía KMS) | Introductorio: la responsabilidad de gestionar la key recae casi completamente en el cliente |

**Customer-Managed Encryption Keys (CMEK)** es la opción recomendada para
la mayoría de casos que requieren control sobre las claves de cifrado.
**Customer-Supplied Encryption Keys (CSEK)** se cubre solo a nivel
introductorio: es un mecanismo más antiguo y de menor integración.

## 8. 🧱 Key rotation y key policies

- **Key rotation**: Cloud KMS puede rotar automáticamente una key según
  un período configurado, manteniendo versiones anteriores disponibles
  para descifrar datos ya cifrados con ellas.
- **Key policies**: son, en la práctica, allow policies de IAM aplicadas
  sobre la key — determinan quién puede usarla, administrarla o
  rotarla.

## 9. 🧱 Integración con otros servicios

Cloud KMS integra con Cloud Storage, Persistent Disk, Cloud SQL,
Firestore y Secret Manager mediante CMEK, permitiendo reemplazar el
cifrado por defecto administrado por Google con claves que tú controlas.

```text
Cloud KMS
vs
Secret Manager
```

KMS administra **claves y operaciones criptográficas**; no está pensado
para almacenar directamente un secreto legible como una contraseña o un
token — para eso existe Secret Manager (ver Parte III), que además usa
KMS por debajo para cifrar lo que almacena.

---

# Parte III — Secretos y configuración

## 10. 🧱 Secret Manager

**Secret Manager** almacena secretos (contraseñas, tokens, claves de
API) de forma centralizada, con control de acceso vía IAM y cifrado
automático (opcionalmente con CMEK).

## 11. 🧱 Secret versions

Cada actualización de un secreto crea una nueva **version**. Las
aplicaciones pueden referenciar una versión específica o "latest",
facilitando rotación sin cambiar la referencia en el código si se usa
"latest" de forma controlada.

## 12. 🧱 Rotación de credenciales

Secret Manager admite configurar rotación (notificaciones o
automatización vía integración con Cloud Functions/Pub/Sub) para
credenciales que deben cambiar periódicamente.

## 13. 🧱 Acceso mediante IAM

El acceso a un secreto se controla con roles de IAM sobre el recurso
secreto (ej. `roles/secretmanager.secretAccessor`), igual que cualquier
otro recurso de GCP — no hay un mecanismo de acceso separado.

## 14. 🧱 Runtime Configurator / variables de entorno gestionadas

A nivel introductorio: además de secretos, una aplicación suele necesitar
configuración no sensible (feature flags, parámetros de entorno). GCP
ofrece mecanismos de configuración gestionada para eso, distintos de
Secret Manager, que está reservado para datos sensibles.

```text
Secret Manager vs variables de entorno planas
```

> No guardes un secreto como variable de entorno plana en la definición
> del servicio (visible en la consola, en logs de despliegue, o en el
> historial de Terraform state) cuando puedes referenciarlo desde Secret
> Manager con acceso controlado por IAM.

---

# Parte IV — Seguridad perimetral

## 15. 🧱 Cloud Armor

**Cloud Armor** aplica reglas de seguridad tipo WAF y rate limiting en el
borde de **Cloud Load Balancing**, antes de que el tráfico llegue a tus
backends.

```text
Firewall rule vs Cloud Armor
```

| | Firewall rule (VPC) | Cloud Armor |
|---|---|---|
| Nivel | Red VPC (IP/puerto/protocolo) | Borde de Cloud Load Balancing (HTTP, capa de aplicación) |
| Capacidades | Allow/deny por IP/rango, puerto, protocolo | Reglas WAF (OWASP), rate limiting, geo-blocking |
| Protege | Tráfico que llega a la VPC | Tráfico HTTP antes de llegar a los backends |

## 16. 🧱 Protección DDoS

La red de Google incluye protección DDoS **por defecto** en su
infraestructura de borde. **Cloud Armor Managed Protection** ofrece una
capa adicional avanzada (a nivel avanzado, no imprescindible para el
repaso base).

## 17. 🧱 Cloud CDN

**Cloud CDN** cachea contenido en el edge de Google, integrado con Cloud
Load Balancing, reduciendo latencia y carga sobre el backend de origen
para contenido cacheable.

```text
Cloud Armor vs Cloud CDN
```

Cloud Armor **filtra/protege** tráfico; Cloud CDN **cachea** tráfico
cacheable. Ambos se configuran sobre el mismo backend service de Cloud
Load Balancing y son complementarios, no alternativos.

---

# Parte V — Gobierno organizacional

## 18. 🧱 Resource Manager

**Resource Manager** es la API/servicio que administra la jerarquía
Organization/Folder/Project en sí — crear, mover y organizar esos
contenedores.

## 19. 🧱 Organization Policies

Una **Organization Policy** es una restricción de **configuración**
aplicada a nivel de la jerarquía (Organization/Folder/Project), no un
permiso otorgado a un member.

```text
IAM allow policy (qué puede hacer un member)
vs
Organization Policy (qué configuraciones están permitidas en un recurso)
```

Ejemplo: una Organization Policy puede prohibir que cualquier VM del
proyecto tenga IP externa, sin importar qué IAM roles tenga el usuario
que intenta crearla — es una restricción de configuración, no de
identidad.

## 20. 🧱 Separación de proyectos por ambiente

Un patrón habitual: proyectos separados para `dev`/`test`/`prod` (a veces
agrupados en Folders separados), lo que permite aplicar Organization
Policies e IAM distintos por ambiente y limitar el blast radius de un
error o incidente en un ambiente no productivo.

## 21. 🧱 Centralización de seguridad

Aplicar IAM, Organization Policies y hierarchical firewall policies (ver
documento [`01`](01-infraestructura-global-y-redes.md)) a nivel Organization/Folder centraliza guardrails de
seguridad que ningún equipo de proyecto individual puede desactivar
libremente, mientras cada equipo conserva autonomía operativa dentro de
esos límites.

---

## 🧠 Preguntas rápidas

1. ¿Qué unidad concentra la facturación y las APIs habilitadas en GCP?
2. ¿Por qué evitar primitive roles en producción?
3. ¿Las allow policies de IAM son aditivas o pueden negar lo que otro binding concedió?
4. ¿Cómo se niega explícitamente un acceso en IAM si las allow policies no pueden hacerlo?
5. ¿Qué debería usar una app en Cloud Run en lugar de una key de Service Account descargada?
6. ¿Qué resuelve Workload Identity Federation que una key de Service Account no resuelve de forma segura?
7. ¿Qué diferencia el cifrado at rest del cifrado in transit?
8. ¿Qué es envelope encryption?
9. ¿Cloud KMS reemplaza a Secret Manager?
10. ¿Por qué preferir Secret Manager sobre una variable de entorno plana para un dato sensible?
11. ¿Qué diferencia a Cloud Armor de una firewall rule de VPC?
12. ¿Cloud Armor y Cloud CDN resuelven el mismo problema?
13. ¿Una Organization Policy otorga permisos a un member?
14. ¿Qué diferencia una Organization Policy de una IAM allow policy?
15. ¿Por qué separar proyectos por ambiente (dev/test/prod)?

---

## 📚 Referencias oficiales

- Shared fate: https://cloud.google.com/security/shared-responsibility-shared-fate
- Resource hierarchy: https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy
- IAM overview: https://cloud.google.com/iam/docs/overview
- IAM roles overview: https://cloud.google.com/iam/docs/understanding-roles
- Policy evaluation: https://cloud.google.com/iam/docs/policies
- IAM Conditions: https://cloud.google.com/iam/docs/conditions-overview
- Service Accounts: https://cloud.google.com/iam/docs/service-account-overview
- Workload Identity Federation: https://cloud.google.com/iam/docs/workload-identity-federation
- Workload Identity in GKE: https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity
- IAM Deny policies: https://cloud.google.com/iam/docs/deny-overview
- Cloud KMS overview: https://cloud.google.com/kms/docs/overview
- Envelope encryption: https://cloud.google.com/kms/docs/envelope-encryption
- CMEK overview: https://cloud.google.com/kms/docs/cmek
- CSEK overview: https://cloud.google.com/storage/docs/encryption/customer-supplied-keys
- Secret Manager overview: https://cloud.google.com/secret-manager/docs/overview
- Secret Manager rotation: https://cloud.google.com/secret-manager/docs/secret-rotation
- Cloud Armor overview: https://cloud.google.com/armor/docs/cloud-armor-overview
- Cloud CDN overview: https://cloud.google.com/cdn/docs/overview
- Resource Manager overview: https://cloud.google.com/resource-manager/docs/overview
- Organization Policy overview: https://cloud.google.com/resource-manager/docs/organization-policy/overview
