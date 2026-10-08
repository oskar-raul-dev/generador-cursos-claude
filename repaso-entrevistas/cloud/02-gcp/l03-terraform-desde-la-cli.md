# L03 — Terraform desde la CLI

> **Objetivo:** administrar infraestructura de GCP con Terraform de verdad: state remoto,
> provider pinneado, un plan que sepas leer, drift provocado a mano y dos `destroy` que fallan a
> propósito. Al terminar tienes que poder decir **qué administra Terraform y qué no**, que es lo
> que decide si un teardown es de fiar.
> **Se asume leído:** [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md). Rinde
> mucho más con [`09`](09-terraform-iac.md) leído.
> **Costo:** **$0.00**. Dos buckets vacíos y una base de Firestore vacía caben de sobra en el
> Always Free (5 GiB-mes de Cloud Storage en regiones de EE. UU., 1 GiB de Firestore).
> **Duración:** 2–3 horas.
> **Prerrequisitos:** [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) y [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) completos, y **Terraform instalado**
> (`terraform version`). Las ADC puestas: `gcloud auth application-default login`.
> **Qué queda encendido al terminar:** el bucket de state `inv-lab-tfstate-472913`, el bucket de
> datos `inv-lab-data-472913` y la base de Firestore `(default)` vacía. Nada de eso factura.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Qué compra Terraform aquí](#1--qué-compra-terraform-aquí-y-qué-no) ·
[El huevo y la gallina del state](#2--el-huevo-y-la-gallina-el-bucket-del-state) ·
[Provider pinneado](#3--el-provider-pinneado-y-el-lock-file) ·
[El primer `plan`](#4--el-primer-plan-leerlo-antes-de-aplicarlo) ·
[Qué hay dentro del state](#5--qué-hay-dentro-del-state-y-por-qué-no-se-toca) ·
[`must be replaced`](#6--must-be-replaced-la-frontera-inmutable) ·
[Drift](#7--drift-provocado-a-mano) ·
[Firestore](#8--firestore-y-la-protección-que-viene-puesta) ·
[Los dos `destroy` que fallan](#9--los-dos-destroy-que-fallan-a-propósito) ·
[Lo que Terraform no ve](#10--lo-que-terraform-no-ve) ·
[Teardown](#11--teardown-de-este-lab) ·
[Checklist](#-checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 Qué compra Terraform aquí, y qué no

En [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) y [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) creaste todo con `gcloud`, y funcionó perfectamente. La pregunta honesta es
entonces qué añade Terraform, porque "es infraestructura como código" no es una respuesta: es un
eslogan.

Lo que compra, en concreto:

```text
Un archivo de state    → sabe qué existe, y por tanto qué hay que borrar
Un plan                → te enseña qué va a pasar ANTES de que pase
Un grafo de dependencias → borra en el orden correcto sin que se lo digas
Detección de drift     → te avisa cuando alguien tocó algo por fuera
```

De los cuatro, el que justifica el lab entero es el primero, y por una razón que tiene poco que
ver con la elegancia:

> 🧠 **Modelo mental.** Un script de `gcloud` sabe **crear**. Terraform sabe **qué creó**, que es
> lo único que permite destruir con certeza. La tesis de esta serie —"el laboratorio no se mide
> por lo que despliegas, sino por lo que destruyes y vuelves a levantar"— necesita esa segunda
> capacidad.

Y lo que **no** compra, dicho ahora para que no sorprenda en [`L08`](l08-costos-y-destruccion-verificada.md):

> ⚠️ **`terraform destroy` no es un teardown.** Solo borra lo que está en su state. Lo que
> creaste a mano, lo que creó un service agent en tu nombre y lo que quedó de un `apply` a medias
> le es invisible. Esto se desarrolla en §10 y es el motivo de que [`L08`](l08-costos-y-destruccion-verificada.md) exista.

**Por qué Terraform y no Deployment Manager.** Es una pregunta de entrevista con trampa temporal:
Deployment Manager fue la herramienta nativa de IaC de GCP y **está en baja**. La opción nativa
hoy es **Infrastructure Manager**, que es un servicio administrado que ejecuta… Terraform. Es
decir: incluso la respuesta "nativa" pasa por HCL. Por eso el curso enseña Terraform local con
state en Cloud Storage, que es el denominador común.

---

## 2. 🧱 El huevo y la gallina: el bucket del state

El state tiene que vivir en algún sitio compartido y versionado. En GCP ese sitio es un bucket de
Cloud Storage. Y aquí aparece el primer problema conceptual del lab:

> 🧭 **El bucket del state no lo puede crear el Terraform que lo va a usar como backend.** Para
> escribir el state necesita el bucket; para crear el bucket necesitaría escribir el state.
> Alguien tiene que romper el ciclo, y ese alguien es `gcloud`, una sola vez.

**Teardown antes de crear:** este bucket se borra con `gcloud storage rm --recursive gs://inv-lab-tfstate-472913`
al final de la serie, y **no antes**: mientras contenga el state, borrarlo deja a Terraform sin
memoria de lo que administra. El desarrollo está en [`L08`](l08-costos-y-destruccion-verificada.md).

```bash
gcloud storage buckets create gs://inv-lab-tfstate-472913 \
  --location=US \
  --uniform-bucket-level-access \
  --public-access-prevention
```

- El nombre de un bucket es **único en todo Google Cloud** y por eso lleva el sufijo del
  proyecto. Es inmutable: renombrarlo significa crear otro y copiar.
- `--location=US` es una **multi-región** de Estados Unidos, que es lo que cubre la cuota de
  5 GiB-mes del Always Free. Poner aquí `southamerica-east1` te saca de la cuota gratuita sin
  avisar de nada.
- `--uniform-bucket-level-access` desactiva las ACL por objeto y deja **solo IAM** como control
  de acceso. Sin este flag conviven dos sistemas de permisos sobre el mismo bucket, que es una
  fuente clásica de "tiene permiso y no puede". Es además requisito de varias políticas de
  seguridad.
- `--public-access-prevention` impide que alguien pueda hacer público este bucket aunque tenga
  permiso para intentarlo. En un bucket que contiene el state —donde hay nombres de recursos, IPs
  y a veces más— no es opcional.

Ahora el versioning, que es lo que convierte el bucket en una red de seguridad:

```bash
gcloud storage buckets update gs://inv-lab-tfstate-472913 --versioning
```

- `--versioning` hace que cada escritura conserve la versión anterior del objeto. Como Terraform
  reescribe el state entero en cada `apply`, esto te da el historial completo y la posibilidad de
  volver atrás si un `apply` deja el state corrupto. **Es la única protección real contra un
  state roto**, y cuesta lo que ocupen las versiones: unos kilobytes.

---

## 3. 🧱 El provider pinneado y el lock file

Crea un directorio para el HCL del lab —fuera del bucket, en tu máquina— y el primer archivo:

```hcl
# versions.tf — qué versiones se usan y dónde vive el state

terraform {
  required_version = "~> 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"     # versión EXACTA, sin ~> ni >=
    }
  }

  backend "gcs" {
    bucket = "inv-lab-tfstate-472913"
    prefix = "lab/state"
  }
}

provider "google" {
  project = "inv-lab-472913"
  region  = "us-central1"
}
```

Línea por línea, porque cada una decide algo:

- **`required_version`** es la versión de la CLI de Terraform, no del provider. Aquí sí se admite
  un rango, porque la CLI rompe compatibilidad muy despacio.
- **`version = "6.12.0"`** es el provider de Google, **pinneado a una versión exacta**. Un
  `~> 6.0` deja que mañana entre una versión distinta y que el mismo HCL produzca un plan
  distinto: destruye exactamente la reproducibilidad que el lab quiere enseñar. Usa la versión que
  tengas hoy; lo innegociable es que sea exacta y que esté escrita.
- **`backend "gcs"`** dice dónde vive el state. `prefix` es la "carpeta" dentro del bucket: varios
  proyectos pueden compartir bucket con prefijos distintos.
- **Fíjate en lo que no hay en el backend: credenciales.** El backend usa las mismas ADC que el
  provider. Es la razón de que `terraform init` falle con `PERMISSION_DENIED` aunque `gcloud`
  funcione perfectamente — el clásico de
  [`A03` §8](a03-catalogo-de-errores-y-diagnostico.md#8--terraform-lo-que-falla-en-plan-apply-y-destroy).
- **`provider "google"`** fija proyecto y región por defecto para todos los recursos. Cada recurso
  puede sobrescribirlos.

```bash
terraform init
```

```text
Initializing the backend...
Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Installing hashicorp/google v6.12.0...
- Installed hashicorp/google v6.12.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above.
```

Ese archivo del final es más importante que el pin:

> 🧠 **Modelo mental.** El `version =` del HCL es una **restricción**; `.terraform.lock.hcl` es el
> **resultado**, con la versión exacta y los hashes de los binarios. El pin dice qué se puede
> instalar; el lock dice qué se instaló. **El lock se versiona en git**, igual que un
> `package-lock.json`. Sin él, dos personas con el mismo HCL pueden tener providers distintos.

---

## 4. 🧱 El primer `plan`: leerlo antes de aplicarlo

Añade el bucket de datos del laboratorio:

```hcl
# storage.tf — el bucket de datos del lab

resource "google_storage_bucket" "data" {
  name                        = "inv-lab-data-472913"
  location                    = "US"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = {
    project = "inv_lab"   # el label de rastreo; minúsculas y guion bajo, como pide la API
  }
}
```

- `google_storage_bucket` es el tipo; `data` es el **nombre local** con el que te refieres a él en
  el HCL (`google_storage_bucket.data.name`). No aparece en GCP.
- No hay `force_destroy`, y es deliberado: §9 lo necesita para fallar.

```bash
terraform plan
```

```text
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_storage_bucket.data will be created
  + resource "google_storage_bucket" "data" {
      + force_destroy               = false
      + id                          = (known after apply)
      + location                    = "US"
      + name                        = "inv-lab-data-472913"
      + project                     = (known after apply)
      + public_access_prevention    = "enforced"
      + storage_class               = "STANDARD"
      + uniform_bucket_level_access = true
      + labels                      = {
          + "project" = "inv_lab"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Tres cosas que leer aquí y que se repiten en todos los planes del curso:

- **`(known after apply)`** son valores que el servidor asigna: no los sabe nadie hasta crear el
  recurso. Cuando un plan tiene demasiados de estos, es señal de que hay dependencias encadenadas.
- **Aparecen campos que no escribiste** (`storage_class`, `force_destroy`). Son defaults del
  provider, y verlos aquí es la forma más rápida de descubrir qué está decidiendo por ti.
- **La última línea es el resumen que hay que leer siempre**: `1 to add, 0 to change, 0 to
  destroy`. Un `to destroy` inesperado se detecta ahí, no leyendo el diff entero.

```bash
terraform apply
```

Escribe `yes` cuando pregunte. Y ahora la variante que se usa en cualquier equipo serio:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

- `-out=tfplan` guarda el plan en un archivo binario, y `apply tfplan` aplica **exactamente ese**
  plan, sin volver a calcular y **sin preguntar**. Es la única forma de garantizar que lo que
  revisaste es lo que se aplica: sin `-out`, entre tu `plan` y tu `apply` el mundo pudo cambiar.

---

## 5. 🩺 Qué hay dentro del state, y por qué no se toca

```bash
terraform state list
```

```text
google_storage_bucket.data
```

```bash
terraform state show google_storage_bucket.data
```

Ahí está el recurso entero **tal como lo devolvió la API**, no como lo escribiste. Es la misma
información que te daría un `gcloud storage buckets describe --format=json`, y por eso el hábito
de [`A04` §5](a04-rutina-de-recurso-cli-api-y-destruccion.md#5--paso-2-inspeccionar-con---formatjson)
sirve igual aquí.

Y el archivo en sí:

```bash
gcloud storage ls -r gs://inv-lab-tfstate-472913
```

```text
gs://inv-lab-tfstate-472913/lab/state/default.tfstate
```

> ⚠️ **El state no se edita a mano y no se comparte por chat.** Contiene el inventario completo de
> lo que administras y, en varios recursos, **valores sensibles en claro** —el contenido de un
> secreto, una clave generada, una contraseña—. Terraform no los cifra: cifrado en reposo lo pone
> Cloud Storage, y el control de acceso lo pone el IAM del bucket. Por eso §2 puso
> `--public-access-prevention` sin discutirlo.

Para las correcciones legítimas existen comandos, y conviene saber que existen aunque este lab no
los necesite: `terraform state rm` (deja de administrar un recurso sin borrarlo),
`terraform import` (adopta un recurso que ya existía) y `terraform state mv` (renombra la
referencia local). Todos operan sobre el state, no sobre GCP.

---

## 6. 🩺 `must be replaced`: la frontera inmutable

Este es el experimento que hay que provocar, porque es la información más importante que da un
plan y la que más caro sale ignorar.

Cambia la ubicación del bucket en `storage.tf`:

```hcl
  location = "EU"     # antes: "US"
```

```bash
terraform plan
```

```text
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # google_storage_bucket.data must be replaced
-/+ resource "google_storage_bucket" "data" {
      ~ id       = "inv-lab-data-472913" -> (known after apply)
      ~ location = "US" -> "EU" # forces replacement
        name     = "inv-lab-data-472913"
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

Léelo entero antes de tocar nada:

- **`-/+ destroy and then create replacement`** significa que Terraform va a **borrar** el bucket
  y crear otro. Si tuviera objetos dentro, se irían con él.
- **`# forces replacement`** marca el atributo culpable. Un solo comentario, al final de una línea,
  y es la diferencia entre un cambio de configuración y una pérdida de datos.
- **`1 to add, 0 to change, 1 to destroy`**: el resumen ya lo decía.

> 🧭 **Regla de método.** Nunca se aplica un plan que dice `must be replaced` sin haber leído qué
> recurso y qué atributo lo fuerzan. Es exactamente la misma frontera que encontraste en
> [`A04` §6](a04-rutina-de-recurso-cli-api-y-destruccion.md#6--paso-3-modificar-y-encontrar-la-frontera-inmutable)
> cuando la API rechazó un `update` sobre un campo inmutable: los dos lados de la misma línea.

Deshaz el cambio (`location = "US"`) y confirma que el plan vuelve a estar limpio:

```bash
terraform plan
```

```text
No changes. Your infrastructure matches the configuration.
```

---

## 7. 🩺 Drift provocado a mano

El segundo experimento. Alguien —tú, dentro de un minuto— toca por fuera algo que Terraform
administra.

```bash
gcloud storage buckets update gs://inv-lab-data-472913 \
  --update-labels=owner=alguien_de_paso
```

```bash
terraform plan
```

```text
Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the
last "terraform apply" which may have affected this plan:

  # google_storage_bucket.data has been changed
  ~ resource "google_storage_bucket" "data" {
      ~ labels = {
          + "owner"   = "alguien_de_paso"
            "project" = "inv_lab"
        }
    }

Terraform will perform the following actions:

  # google_storage_bucket.data will be updated in-place
  ~ resource "google_storage_bucket" "data" {
      ~ labels = {
          - "owner"   = "alguien_de_paso" -> null
            "project" = "inv_lab"
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Hay dos bloques y conviene no confundirlos: el primero es **lo que Terraform descubrió** al
refrescar (`has been changed`); el segundo es **lo que propone hacer** (`will be updated
in-place`), que es deshacerlo.

> 🧠 **Modelo mental.** Terraform no pregunta quién tiene razón: asume que **el HCL es la
> verdad** y propone devolver el mundo a él. Aplicar a ciegas borra el cambio de otra persona;
> ignorarlo deja el HCL mintiendo. La decisión —¿el cambio era legítimo y hay que llevarlo al
> código, o era un parche que hay que revertir?— es tuya, y es la conversación que de verdad
> ocurre en un equipo.

La prevención es una sola regla, y no admite excepciones cómodas:

> 🧭 **Lo que administra Terraform no se toca en la consola.** Ni "solo para probar", ni "solo
> este label". Si hay que tocarlo, se toca en el HCL.

Deshaz el drift aplicando:

```bash
terraform apply
```

---

## 8. 🧱 Firestore, y la protección que viene puesta

Ahora el recurso que [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) va a necesitar, y que trae de fábrica el obstáculo más didáctico del
lab.

```hcl
# firestore.tf — la base del lab

resource "google_firestore_database" "default" {
  project     = "inv-lab-472913"
  name        = "(default)"
  location_id = "nam5"
  type        = "FIRESTORE_NATIVE"

  # protección del lado de la API: impide borrar la base desde cualquier cliente
  delete_protection_state = "DELETE_PROTECTION_ENABLED"

  # qué hace Terraform al destruir: ABANDON la deja viva, DELETE la borra
  deletion_policy = "ABANDON"
}
```

- **`name = "(default)"`** es literal, con paréntesis incluidos. Un proyecto puede tener varias
  bases de Firestore, y la primera se llama así. No es un placeholder.
- **`location_id = "nam5"`** es una **multi-región** de Norteamérica. Es donde vive la cuota
  Always Free de Firestore (1 GiB de almacenamiento; 50.000 lecturas, 20.000 escrituras y 20.000
  borrados **al día**), y es un campo **inmutable**: cambiarlo obliga a recrear la base, es decir,
  a perder los datos.
- **`type = "FIRESTORE_NATIVE"`** frente a `DATASTORE_MODE`. Native es el modo que se usa desde
  aplicaciones modernas y el que asume [`04`](04-firestore-bigtable-nosql.md). También inmutable.
- **`delete_protection_state`** es una protección **del servicio**: mientras esté activada,
  ninguna llamada a la API puede borrar la base, venga de Terraform, de `gcloud` o de la consola.
- **`deletion_policy`** es una instrucción **para Terraform**: `ABANDON` significa "sácala del
  state pero no la borres"; `DELETE` significa "bórrala de verdad". Son dos cosas distintas y se
  confunden constantemente.

> ⚠️ **Dos candados, dos llaves distintas.** `delete_protection_state` lo pone el servicio;
> `deletion_policy` lo pone Terraform. Para borrar la base de verdad hay que abrir **los dos**, y
> en ese orden: primero desactivar la protección y aplicar, y solo entonces cambiar la política y
> destruir. §9 lo hace fallar primero, que es como se aprende.

```bash
terraform apply
gcloud firestore databases describe --database='(default)' \
  --format='value(name, locationId, type, deleteProtectionState)'
```

---

## 9. 🩺 Los dos `destroy` que fallan a propósito

El corazón del lab, y la razón de que este documento vaya antes que [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) y no después.

**Fallo 1 — el bucket con contenido.** Pon algo dentro:

```bash
echo '{"sku":"ABC-1","qty":42}' > /tmp/seed.json
gcloud storage cp /tmp/seed.json gs://inv-lab-data-472913/seed.json
```

```bash
terraform destroy
```

```text
google_storage_bucket.data: Destroying... [id=inv-lab-data-472913]

Error: Error trying to delete bucket inv-lab-data-472913 containing objects without
`force_destroy` set to true
```

No es un bug: es una salvaguarda. Terraform se niega a borrar un bucket con contenido salvo que lo
autorices explícitamente, porque el caso normal de "el bucket tiene objetos que no esperabas" es
que alguien esté a punto de perder datos.

```hcl
resource "google_storage_bucket" "data" {
  # …
  force_destroy = true   # en un lab, sí; en producción, esto es una bomba con temporizador
}
```

> ⚠️ **`force_destroy = true` en un bucket de producción es la línea de HCL que más datos ha
> borrado.** Un `terraform destroy` mal dirigido, o un `must be replaced` que nadie leyó, se
> lleva el contenido sin preguntar. En este lab está bien porque el contenido es un JSON de
> juguete; fuera de aquí, es una decisión que se discute.

**Fallo 2 — Firestore protegida.** Quita el `ABANDON` para intentar borrarla de verdad:

```hcl
  deletion_policy = "DELETE"
```

```bash
terraform apply     # aplica el cambio de política
terraform destroy
```

```text
Error: Error when reading or editing Database: googleapi: Error 400: The database is
protected from deletion. Please disable delete protection before deleting the database.
```

Ahí está el segundo candado, y esta vez lo pone el servicio, no Terraform. La secuencia correcta
es de tres pasos y en este orden:

```hcl
  delete_protection_state = "DELETE_PROTECTION_DISABLED"
  deletion_policy         = "DELETE"
```

```bash
terraform apply     # 1. desactiva la protección del servicio (el destroy todavía no)
terraform destroy   # 2. ahora sí
```

Un `apply` para abrir el candado y un `destroy` para borrar. **Intentar hacer las dos cosas en el
mismo `destroy` no funciona**, porque Terraform no puede modificar y borrar el mismo recurso en
una sola operación.

> 🩺 **Diagnóstico.** Cuando un `destroy` falla, la pregunta es siempre la misma: *¿el candado lo
> pone Terraform o lo pone el servicio?* El primero se abre en el HCL; el segundo se abre con un
> `apply` previo. El mensaje de error lo dice: si menciona un atributo del provider
> (`force_destroy`), es Terraform; si viene con un código de la API (`Error 400: The database is
> protected`), es el servicio.

**Vuelve a dejar la base montada**, porque [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) la necesita:

```hcl
  delete_protection_state = "DELETE_PROTECTION_ENABLED"
  deletion_policy         = "ABANDON"
```

```bash
terraform apply
```

---

## 10. ⚖ Lo que Terraform no ve

Última pieza, y la que conecta con [`L08`](l08-costos-y-destruccion-verificada.md). Crea algo a mano, como si estuvieras probando:

```bash
gcloud storage buckets create gs://inv-lab-huerfano-472913 --location=US
```

```bash
terraform plan
```

```text
No changes. Your infrastructure matches the configuration.
```

**Terraform dice que todo está en orden y acabas de dejar un bucket suelto.** No miente: dice que
el mundo coincide con *su* configuración, y ese bucket nunca estuvo en ella.

```text
lo que Terraform administra   ⊂   lo que existe en el proyecto
       (el state)                     (Cloud Asset Inventory)
```

Esa relación de subconjunto es la idea central del teardown de esta serie:

> 🧠 **Modelo mental.** `terraform destroy` es **el ejercicio**; el barrido de Cloud Asset
> Inventory es **la verificación**; borrar el proyecto es **la red de seguridad**. Usar solo la
> red de seguridad te ahorra dinero y no te enseña nada.

Las tres categorías que se escapan sistemáticamente, y conviene tenerlas nombradas:

1. **Lo creado a mano** para probar algo, como el bucket de arriba.
2. **Lo creado por un service agent en tu nombre** — en [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) vas a ver a Eventarc y a Pub/Sub
   crear cosas que tú no pediste.
3. **Lo que quedó de un `apply` a medias**: si un `apply` falla en el recurso siete de diez, los
   seis primeros existen y están en el state, pero tu HCL describe otra cosa.

Limpia el huérfano ahora mismo, que para eso lo creaste:

```bash
gcloud storage rm --recursive gs://inv-lab-huerfano-472913
```

---

## 11. 🧹 Teardown de este lab

| Recurso | ¿Cobra? | Qué hacer |
|---|---|---|
| Bucket de state `inv-lab-tfstate-472913` | No (vacío o casi) | **Se queda.** Es la memoria de Terraform; se borra el último, en [`L08`](l08-costos-y-destruccion-verificada.md) |
| Bucket de datos `inv-lab-data-472913` | No dentro de 5 GiB-mes | Se queda: [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) lo usa para el trigger de Eventarc |
| Firestore `(default)` vacía | No dentro de la cuota | Se queda: [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) escribe en ella |
| Bucket `inv-lab-huerfano-472913` | No | **Borrado ya** en §10 |
| Objeto `seed.json` | No | Se va con el bucket, o `gcloud storage rm gs://…/seed.json` |

Este lab no deja nada que facture, así que el teardown completo espera a [`L08`](l08-costos-y-destruccion-verificada.md). Lo que sí toca es
verificar que el inventario es exactamente el que crees:

```bash
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --format='table(assetType, name)'
```

```text
ASSET_TYPE                            NAME
storage.googleapis.com/Bucket         //storage.googleapis.com/inv-lab-tfstate-472913
storage.googleapis.com/Bucket         //storage.googleapis.com/inv-lab-data-472913
firestore.googleapis.com/Database     //firestore.googleapis.com/projects/inv-lab-472913/databases/(default)
pubsub.googleapis.com/Topic           //pubsub.googleapis.com/projects/inv-lab-472913/topics/inv-lab-budget
iam.googleapis.com/ServiceAccount     …inv-api-sa@…
iam.googleapis.com/ServiceAccount     …inv-projector-sa@…
iam.googleapis.com/ServiceAccount     …inv-pubsub-sa@…
```

Siete recursos, ninguno factura, y **el huérfano de §10 no está**. Ese es el estado correcto al
cerrar `L03`.

> 💡 **Truco.** Guarda el directorio de HCL en git desde hoy, con `.terraform.lock.hcl` dentro y
> `.terraform/` fuera (es caché de binarios, pesa y se regenera con `terraform init`). El state
> tampoco va a git: vive en el bucket, que para eso lo creaste.

---

## 📋 Checklist de salida

- [ ] `terraform init` conectó el backend `gcs` y creó `.terraform.lock.hcl`.
- [ ] El provider está pinneado a una **versión exacta** en `versions.tf`, y sabes cuál.
- [ ] El bucket de state tiene versioning, acceso uniforme y prevención de acceso público.
- [ ] Aplicaste al menos una vez con `terraform plan -out=tfplan` + `terraform apply tfplan`.
- [ ] Provocaste un `must be replaced` y puedes decir qué atributo lo forzó.
- [ ] Provocaste drift desde `gcloud` y leíste los **dos** bloques del plan resultante.
- [ ] Los dos `destroy` fallaron a propósito, y distingues cuál candado lo puso Terraform y cuál el servicio.
- [ ] Firestore `(default)` existe, vacía, con `delete_protection_state` activado otra vez.
- [ ] Creaste un bucket a mano, comprobaste que `terraform plan` decía "No changes", y lo borraste.
- [ ] `gcloud asset search-all-resources` devuelve exactamente siete recursos y ninguno factura.

## 🏁 La señal de que quedó bien

`terraform plan` dice `No changes`, el inventario del proyecto tiene siete recursos que puedes
nombrar uno a uno, y puedes explicar en una frase por qué un `terraform destroy` que termina con
éxito todavía no demuestra que el proyecto quedó limpio.

---

## 🧠 Preguntas rápidas

1. ¿Qué es lo único que Terraform te da y un script de `gcloud` no, y por qué decide el diseño de esta serie?
2. ¿Por qué el bucket del state no lo puede crear el mismo Terraform que lo usa como backend?
3. ¿Qué aporta el versioning en el bucket del state y contra qué te protege exactamente?
4. ¿Qué diferencia hay entre el `version =` del HCL y `.terraform.lock.hcl`, y cuál de los dos se versiona en git?
5. ¿Por qué pinnear el provider con `~> 6.0` en vez de una versión exacta rompe lo que el lab quiere enseñar?
6. ¿Qué significa `(known after apply)` en un plan?
7. ¿Qué añade `terraform plan -out=tfplan` seguido de `terraform apply tfplan` frente a un `apply` a secas?
8. ¿Qué marca `# forces replacement` y qué regla de método impone antes de aplicar?
9. Un plan muestra dos bloques: `has been changed` y `will be updated in-place`. ¿Qué dice cada uno?
10. ¿Terraform decide quién tiene razón cuando hay drift? ¿Qué asume?
11. ¿Por qué el state no se edita a mano ni se comparte, más allá de la comodidad?
12. ¿En qué se diferencian `delete_protection_state` y `deletion_policy` en Firestore?
13. ¿Por qué hace falta un `apply` antes del `destroy` para borrar una base protegida?
14. ¿Cuándo un `destroy` que falla es culpa de Terraform y cuándo del servicio? ¿Cómo lo distingues en el mensaje?
15. Creaste un bucket con `gcloud` y `terraform plan` dice "No changes". ¿Miente? ¿Qué tres categorías de recursos se le escapan?

---

## 📚 Referencias oficiales

- Documentación de Terraform (CLI y lenguaje): https://developer.hashicorp.com/terraform/docs
- Provider de Terraform para Google Cloud: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Backend de state en Cloud Storage: https://developer.hashicorp.com/terraform/language/backend/gcs
- El archivo de bloqueo de dependencias: https://developer.hashicorp.com/terraform/language/files/dependency-lock
- Restricciones de versión de providers: https://developer.hashicorp.com/terraform/language/providers/requirements
- `terraform plan`: https://developer.hashicorp.com/terraform/cli/commands/plan
- `terraform apply`: https://developer.hashicorp.com/terraform/cli/commands/apply
- `terraform destroy`: https://developer.hashicorp.com/terraform/cli/commands/destroy
- Comandos de state: https://developer.hashicorp.com/terraform/cli/commands/state
- Advertencias sobre datos sensibles en el state: https://developer.hashicorp.com/terraform/language/state/sensitive-data
- `google_storage_bucket`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
- `google_firestore_database`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_database
- Terraform en Google Cloud (guía oficial): https://cloud.google.com/docs/terraform
- Buenas prácticas de Terraform en Google Cloud: https://cloud.google.com/docs/terraform/best-practices-for-terraform
- Acceso uniforme a nivel de bucket: https://cloud.google.com/storage/docs/uniform-bucket-level-access
- Prevención del acceso público: https://cloud.google.com/storage/docs/public-access-prevention
- Control de versiones de objetos en Cloud Storage: https://cloud.google.com/storage/docs/object-versioning
- Ubicaciones de Firestore: https://cloud.google.com/firestore/docs/locations
- Modo Native frente a modo Datastore: https://cloud.google.com/datastore/docs/firestore-or-datastore
- Infrastructure Manager y Terraform: https://cloud.google.com/infrastructure-manager/docs/terraform
- Baja de Deployment Manager: https://cloud.google.com/deployment-manager/docs/deprecations
- Buscar recursos con Cloud Asset Inventory: https://cloud.google.com/asset-inventory/docs/searching-resources
