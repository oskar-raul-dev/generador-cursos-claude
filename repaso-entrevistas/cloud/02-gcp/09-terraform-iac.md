# 09 — Terraform e Infrastructure as Code

> **Objetivo:** manejar el vocabulario de Terraform aplicado a GCP —state, plan, drift,
> replacement, módulos— y poder defender por qué es el estándar de facto aquí.
> **Se asume leído:** [`01`](01-infraestructura-global-y-redes.md) y
> [`03`](03-almacenamiento-y-bases-sql.md), de donde salen los recursos de los ejemplos.
> **Se toca sobre todo con:** [`12` — orquestación y CI/CD](12-orquestacion-y-cicd.md) y
> [`05` — IAM y jerarquía](05-seguridad-iam-jerarquia-kms-secretos.md).
> **Dónde se practica:** [`L03` — Terraform desde la CLI](l03-terraform-desde-la-cli.md), con state
> remoto, drift provocado y dos `destroy` que fallan a propósito.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Infrastructure as Code](#1--infrastructure-as-code) · [Por qué Terraform](#2--por-qué-este-capítulo-usa-terraform-y-no-deployment-manager) · [Conceptos base](#3--conceptos-base) ·
[Resources](#5--resources) · [Lifecycle de recursos](#12--lifecycle-de-recursos) · [Plan y Apply](#13--plan-y-apply) ·
[Replacement](#14--replacement) · [Drift Detection](#16--drift-detection) · [Módulos](#17--módulos) ·
[Ejemplo integrado](#19--ejemplo-integrado) · [Comparación](#20--comparación-introductoria) · [Preguntas rápidas](#-preguntas-rápidas)

## 1. 🧭 Infrastructure as Code

**Infrastructure as Code (IaC)** describe la infraestructura deseada como
código versionado, en lugar de crearla manualmente en la consola. El
código se convierte en la fuente de verdad, permite revisión (pull
request), repetibilidad entre ambientes y auditoría de cambios vía
control de versiones.

## 2. ⚖ Por qué este capítulo usa Terraform y no Deployment Manager

**Deployment Manager** fue la herramienta de IaC nativa de Google, pero
**está en baja** y prácticamente no se usa en proyectos nuevos.
**Terraform**, con el provider `hashicorp/google`, es el **estándar de
facto** en equipos GCP reales y el que se pregunta en entrevistas de
arquitectura.

> 📝 **Contexto.** La respuesta completa tiene un giro que conviene
> conocer, porque es reciente y las fuentes viejas no lo traen: la opción
> nativa hoy es **Infrastructure Manager**, un servicio administrado de
> Google que ejecuta… Terraform. Es decir, incluso el camino "nativo" pasa
> por HCL. Por eso este capítulo enseña Terraform y no una alternativa
> propietaria, y por eso [`L03`](l03-terraform-desde-la-cli.md) usa
> Terraform local con el state en Cloud Storage, que es el denominador
> común de las dos rutas.

> Este es un punto que conviene señalar explícitamente en una entrevista,
> no dar por sobreentendido: si alguien pregunta "¿por qué no Deployment
> Manager?", la respuesta correcta nombra que fue la herramienta nativa,
> que el ecosistema real migró a Terraform como estándar de facto, y que
> la propia opción nativa actual ejecuta Terraform por debajo.

## 3. 🧱 Conceptos base

| Concepto | Descripción |
|---|---|
| Configuration (`.tf` files) | Archivos donde se declara la infraestructura deseada |
| Provider | Plugin que traduce la configuración a llamadas a la API de una plataforma (`google`, `google-beta`, etc.) |
| Resource | La unidad central: un recurso concreto a crear/administrar |
| State | El registro de qué recursos reales corresponden a qué bloques de configuración |
| HCL | HashiCorp Configuration Language, el lenguaje declarativo de los archivos `.tf` |

---

# Parte I — Bloques fundamentales

## 4. 🧱 Los cuatro bloques base

```hcl
terraform {}
provider "google" {}
resource "..." "..." {}
variable "..." {}
output "..." {}
```

```text
resource
```

es el bloque central y **obligatorio** para definir infraestructura: sin
al menos un `resource`, un módulo de Terraform no crea nada.

## 5. 🧱 Resources

```hcl
resource "google_storage_bucket" "example" {
  name     = "example-app-bucket"
  location = "US"
}
```

- **Resource type** (`google_storage_bucket`): qué tipo de recurso GCP se
  crea.
- **Resource local name** (`example`): el identificador dentro de la
  configuración de Terraform, usado para referenciarlo (no es el nombre
  del recurso en GCP).
- **Arguments/Properties** (`name`, `location`): la configuración
  concreta del recurso.

## 6. 🧱 Variables

```hcl
variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment debe ser dev, test o prod."
  }
}
```

Las variables parametrizan la configuración para reutilizarla entre
ambientes (dev/test/prod) sin duplicar código, con validaciones
opcionales que fallan rápido ante un valor inválido.

## 7. 🧱 Outputs

```hcl
output "bucket_name" {
  value = google_storage_bucket.example.name
}
```

Sirven para:

- mostrar resultados al finalizar `apply`;
- exponer valores para otros módulos o consumidores del state (por
  ejemplo, vía `terraform_remote_state`, a nivel introductorio, cuando un
  módulo necesita un valor calculado por otro).

---

# Parte II — Expresiones, datos y condicionales

## 8. 🧱 Expresiones e interpolación

```text
${...} interpolation
count
for_each
Conditional expressions (a ? b : c)
Referencia entre recursos (google_compute_network.vpc.id)
```

```hcl
resource "google_storage_bucket" "app" {
  name = "${var.environment}-app-bucket"
}
```

## 9. 🧱 Variables predefinidas del provider

Los bloques `data` consultan información que ya existe (no la crean),
como el proyecto actual o la configuración de la cuenta activa:

```hcl
data "google_project" "current" {}
data "google_client_config" "current" {}
```

```hcl
resource "google_storage_bucket" "app" {
  name = "${data.google_project.current.project_id}-app-bucket"
}
```

## 10. 🧱 Conditionals con count/for_each

Terraform no tiene un bloque `Conditions` dedicado como algunos sistemas
declarativos: la creación condicional de un recurso se resuelve con
`count`/`for_each` y expresiones.

```hcl
resource "google_project_iam_member" "prod_only" {
  count   = var.environment == "prod" ? 1 : 0
  project = var.project_id
  role    = "roles/viewer"
  member  = "group:sre@example.com"
}
```

Con `count = 0`, el recurso simplemente no se crea.

## 11. 🧱 depends_on

- **Dependencias implícitas**: cuando un recurso referencia un atributo
  de otro (`google_compute_network.vpc.id`), Terraform infiere el orden
  automáticamente.
- **Dependencias explícitas** (`depends_on`): necesarias solo cuando una
  dependencia real **no** queda reflejada por ninguna referencia de
  atributo entre recursos.

> Evita usar `depends_on` como reflejo por defecto. Si Terraform ya puede
> inferir el orden por una referencia de atributo, `depends_on`
> adicional solo agrega ruido y acopla el grafo de dependencias sin
> necesidad real.

---

# Parte III — Ciclo de vida y operación

## 12. 🧱 Lifecycle de recursos

```hcl
lifecycle {
  prevent_destroy        = true
  create_before_destroy  = true
  ignore_changes         = [...]
}
```

| Argumento | Efecto |
|---|---|
| `prevent_destroy` | Bloquea un `destroy`/replacement accidental de ese recurso |
| `create_before_destroy` | Crea el recurso de reemplazo antes de destruir el anterior, reduciendo downtime |
| `ignore_changes` | Ignora cambios detectados en los atributos listados, útil cuando algo externo los modifica legítimamente |

```hcl
lifecycle {
  prevent_destroy = true
}
```

Riesgos al destruir recursos con estado: bases de datos, buckets con
datos, discos con datos persistentes — un `terraform destroy` o un
cambio que fuerza `replacement` (ver §14) puede borrar datos
irrecuperables si el recurso no tiene protección (`prevent_destroy`,
`DeletionPolicy` equivalente vía el proveedor, o snapshot previo).

## 13. 🩺 Plan y Apply

```text
Configuración modificada
      │
      ▼
terraform plan
      │
      ▼
Revisión
      │
      ▼
terraform apply
```

`terraform plan` permite revisar los cambios propuestos antes de
aplicarlos — el equivalente conceptual a un change set: una
previsualización, no una garantía de que la ejecución tendrá éxito.

## 14. 🩺 Replacement

Algunos cambios de propiedad de un recurso no se pueden aplicar como
actualización in situ y **fuerzan un replacement**: Terraform destruye
el recurso existente y crea uno nuevo. Esto puede implicar downtime,
cambio de identificador/endpoint, o pérdida de datos según el recurso —
`terraform plan` señala explícitamente cuándo un cambio implica
replacement.

## 15. 🩺 Errores y rollback

Si `apply` falla a mitad de camino, el **state queda reflejando lo que
realmente se aplicó** — Terraform no hace rollback automático como una
transacción de base de datos. Corregir un apply fallido requiere una
nueva ejecución (o intervención manual sobre el state), no una reversión
automática.

> Un remote state con locking (por ejemplo, backend `gcs` con locking) es
> importante precisamente por esto: sin locking, dos ejecuciones
> concurrentes de `apply` pueden corromper el state al escribir sobre él
> al mismo tiempo.

## 16. 🩺 Drift Detection

Cuando alguien modifica un recurso manualmente fuera de Terraform:

```text
Terraform state:
firewall rule permite puerto 443

Cambio manual en la consola:
puerto 22 añadido
```

Al correr `terraform plan`:

```text
DRIFT DETECTADO — Terraform propone revertir el cambio manual
```

Mezclar IaC con cambios manuales dificulta la administración: Terraform
no "aprende" el cambio manual, lo trata como una desviación a corregir en
el próximo `apply`. Para incorporar un recurso creado manualmente al
control de Terraform sin recrearlo, se usa `terraform import`.

---

# Parte IV — Composición

## 17. 🧱 Módulos

Los **módulos** permiten componer y reutilizar configuración de
Terraform, encapsulando un conjunto de recursos relacionados (por
ejemplo, "una VPC con sus subnets estándar") detrás de una interfaz de
variables/outputs.

## 18. 🧱 Workspaces

Los **workspaces** permiten manejar múltiples instancias del mismo
módulo (por ejemplo, dev/test/prod) con el mismo código, cada una con su
propio state.

No es necesario profundizar más allá de esto para un repaso de
entrevista: basta con reconocer para qué sirve cada uno y no confundirlos
con "ambientes completamente distintos con código distinto".

---

# Parte V — Ejemplo completo

## 19. 🧱 Ejemplo integrado

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"   # versión exacta: un rango haría que el mismo HCL
    }                        # produzca planes distintos en días distintos
  }
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_id" {
  type = string
}

resource "google_compute_network" "vpc" {
  name                    = "app-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app" {
  name          = "app-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_firestore_database" "app" {
  project     = var.project_id
  name        = "(default)"
  location_id = "us-central1"
  type        = "FIRESTORE_NATIVE"
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.app.id
}
```

Bloque por bloque, de forma concisa:

- `terraform { required_providers { ... } }`: fija qué provider y qué
  versión usa esta configuración.
- `variable "environment"` / `variable "project_id"`: parametrizan la
  configuración.
- `google_compute_network "vpc"`: crea la VPC en modo custom
  (`auto_create_subnetworks = false`).
- `google_compute_subnetwork "app"`: crea la subnet regional dentro de
  esa VPC, referenciándola por `google_compute_network.vpc.id`
  (dependencia implícita).
- `google_compute_firewall "allow_https"`: permite tráfico HTTPS entrante
  hacia la VPC.
- `google_firestore_database "app"`: crea la base Firestore en modo
  Native.
- Los `output` exponen los IDs de VPC y subnet creados.

---

# Parte VI — Terraform vs Deployment Manager

## 20. ⚖ Comparación introductoria

| Terraform | Deployment Manager |
|---|---|
| Multi-cloud | GCP-nativo |
| HCL | YAML/Jinja2/Python templates |
| State propio (local o remoto) | Estado administrado por Google |
| Estándar de facto en equipos GCP reales | Modo mantenimiento, poco usado en proyectos nuevos |

```text
Terraform vs Deployment Manager
```

Esta comparación es intencionalmente introductoria — el resto del
capítulo no es, ni pretende ser, un tutorial de Deployment Manager.

---

## 🧠 Preguntas rápidas

1. ¿Por qué este curso usa Terraform y no Deployment Manager como herramienta principal de IaC?
2. ¿Qué bloque es obligatorio para definir infraestructura en Terraform?
3. ¿Qué diferencia al resource type del resource local name?
4. ¿Para qué sirve un bloque `output` más allá de mostrar resultados en pantalla?
5. ¿Cómo se logra crear un recurso de forma condicional en Terraform sin un bloque `Conditions` dedicado?
6. ¿Cuándo es realmente necesario `depends_on`?
7. ¿Qué hace `prevent_destroy` dentro de un bloque `lifecycle`?
8. ¿Qué permite revisar `terraform plan` antes de `terraform apply`?
9. ¿Qué implica que un cambio de propiedad fuerce un replacement?
10. ¿Terraform hace rollback automático si `apply` falla a mitad de camino?
11. ¿Por qué es importante un remote state con locking?
12. ¿Qué reporta `terraform plan` cuando detecta drift?
13. ¿Qué comando permite incorporar un recurso creado manualmente al control de Terraform?
14. ¿Qué diferencia a un módulo de un workspace?

---

## 📚 Referencias oficiales

- Terraform Google Cloud provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Terraform Google Cloud provider — getting started: https://cloud.google.com/docs/terraform/get-started-with-terraform
- Terraform state: https://developer.hashicorp.com/terraform/language/state
- Terraform meta-arguments (count, for_each, depends_on, lifecycle): https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on
- Terraform import: https://developer.hashicorp.com/terraform/cli/import
- Terraform modules: https://developer.hashicorp.com/terraform/language/modules
- Terraform workspaces: https://developer.hashicorp.com/terraform/language/state/workspaces
- Deployment Manager overview: https://cloud.google.com/deployment-manager/docs
- Baja de Deployment Manager: https://cloud.google.com/deployment-manager/docs/deprecations
- Infrastructure Manager y Terraform: https://cloud.google.com/infrastructure-manager/docs/terraform
- El archivo de bloqueo de dependencias de Terraform: https://developer.hashicorp.com/terraform/language/files/dependency-lock
