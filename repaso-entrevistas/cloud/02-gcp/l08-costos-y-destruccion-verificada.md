# L08 — Costos y destrucción verificada

> **Objetivo:** cerrar la serie demostrando lo único que de verdad la mide: **que no queda nada
> encendido**. Leer la factura y atribuir el gasto por label, limpiar Artifact Registry, y ejecutar
> el teardown en tres capas — `terraform destroy`, barrido de verificación con Cloud Asset
> Inventory, y el proyecto entero como unidad de borrado.
> **Se asume leído:** toda la serie. Se apoya de principio a fin en
> [`A02`](a02-costos-trampas-y-recursos-huerfanos.md).
> **Costo:** **$0.00**. Este lab solo lee y borra.
> **Duración:** 2 horas, más una comprobación de cinco minutos a las 48 horas.
> **Prerrequisitos:** `L01`–`L07` completos, con el sistema entero desplegado. Este lab necesita
> tener algo que destruir.
> **Qué queda encendido al terminar:** **nada.** El proyecto vacío y verificado, y opcionalmente
> borrado.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Por qué un lab entero para esto](#1--por-qué-un-lab-entero-para-esto) ·
[Leer la factura](#2--leer-la-factura-y-atribuir-el-gasto) ·
[Artifact Registry](#3--artifact-registry-el-único-cargo-real) ·
[Capa 1: `terraform destroy`](#4--capa-1-terraform-destroy) ·
[Lo que sobrevivió](#5--lo-que-sobrevivió-al-destroy) ·
[Capa 2: el barrido](#6--capa-2-el-barrido-de-verificación) ·
[Lo que vive fuera del proyecto](#7--lo-que-vive-fuera-del-proyecto) ·
[Capa 3: borrar el proyecto](#8--capa-3-el-proyecto-como-unidad-de-borrado) ·
[Volver a levantarlo](#9--la-otra-mitad-volver-a-levantarlo) ·
[A las 48 horas](#10--la-comprobación-de-las-48-horas) ·
[Checklist](#-checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 Por qué un lab entero para esto

Podrías cerrar la serie con `gcloud projects delete` y ahorrarte dos horas. Funcionaría: el
proyecto se lleva todo lo de dentro, la factura se va a cero y no queda nada encendido.

Y no habrías aprendido nada.

> 🧠 **Modelo mental.** `terraform destroy` es **el ejercicio**; el barrido de Cloud Asset
> Inventory es **la verificación**; borrar el proyecto es **la red de seguridad**. Usar solo la red
> de seguridad te ahorra dinero y no te enseña nada — y en un trabajo real casi nunca vas a poder
> borrar el proyecto, porque hay otras cosas dentro.

La tesis de la serie, otra vez, ahora que se puede comprobar:

```text
El laboratorio no se mide por lo que despliegas.
Se mide por lo que destruyes y vuelves a levantar sin intervención manual.
```

Y hay una razón práctica, además de la pedagógica: **esta es la habilidad que se pregunta en
entrevista**. "¿Cómo te aseguras de que un entorno efímero no deja costos?" tiene una respuesta
mediocre —"borro el proyecto"— y una buena, que es la de este lab: destruyo con la herramienta que
administra, verifico con un inventario que ve lo que la herramienta no administra, reviso los tipos
de recurso que sé que se escapan, y confirmo contra la factura pasadas 48 horas.

---

## 2. 💰 Leer la factura y atribuir el gasto

Antes de borrar, mira qué costó. Es el único momento de la serie en que tienes datos reales.

El informe de facturación vive en la consola, y se lee con tres cortes. El que importa es el
tercero, y de ahí sale el detalle:

- **Por servicio (SKU).** El SKU es la granularidad útil: no "Compute Engine", sino
  *"External IP address reserved but unused"*. Ese nivel es el que convierte "me cobraron $3" en
  "me cobraron una IP olvidada".
- **Por proyecto.** Imprescindible si tienes más de uno bajo la misma cuenta de facturación.
- **Por label.** Aquí es donde paga el `project=inv_lab` que vienes poniendo desde [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md): filtras
  por él y sabes qué parte del gasto es del laboratorio.

> 💡 **Truco.** Si el gasto no cuadra con nada que recuerdes, ordena por SKU descendente y mira los
> tres primeros. En un proyecto de práctica el culpable está siempre en ese podio, y casi siempre es
> una forwarding rule, una IP reservada o un disco.

Y el recordatorio que hay que tener presente desde ya, porque condiciona §10:

> ⚠️ **Los datos de facturación se consolidan con retraso**, del orden de horas. El informe que
> miras ahora **no refleja lo que pasó en los últimos minutos**, y por eso el `$0.00` final no se
> puede confirmar hoy: se confirma a las 48 horas.

Para lo que este lab necesita —saber que el label está puesto en todo— basta con el inventario:

```bash
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --format='table(assetType, name, labels)'
```

Fíjate en cuántas filas tienen la columna `labels` vacía. **No están mal etiquetadas: es que ese
tipo de recurso no admite labels**, o lo creó un controlador en tu nombre. Esa observación es
exactamente el motivo de §6.

---

## 3. 💰 Artifact Registry: el único cargo real

De todo lo que montaste, esto es lo único que generó un cargo de verdad, y por acumulación.

```bash
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/inv-lab-472913/inv-lab \
  --include-tags \
  --format='table(package, version.basename():label=DIGEST, tags, createTime, imageSizeBytes)'
```

Suma la columna de tamaño. Entre `inv-api` y `inv-projector`, con sus versiones y la imagen rota de
[`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) §4, es fácil rondar o superar los **0,5 GB** de la cuota Always Free.

Bórralas todas, que el repositorio se va igual en §4 pero conviene ver el mecanismo:

```bash
gcloud artifacts docker images delete \
  us-central1-docker.pkg.dev/inv-lab-472913/inv-lab/inv-api \
  --delete-tags --quiet
```

- Sin tag, el comando borra **todas** las versiones de esa imagen.
- `--delete-tags` borra también los tags que apunten a esos digests; sin el flag, el comando se
  niega si hay alguno.

> 💡 **Truco.** Lo que hace un equipo para no llegar a este punto es una **política de limpieza** en
> el repositorio: reglas del tipo "conserva las 5 versiones más recientes, borra lo demás a los 30
> días". Se declara en el mismo `google_artifact_registry_repository` y evita exactamente este
> crecimiento silencioso. Este lab no la puso a propósito, para que vieras el problema con tus
> propios números.

---

## 4. 🧹 Capa 1: `terraform destroy`

Ahora el ejercicio. Y primero, el plan de destrucción, que se lee igual que cualquier otro:

```bash
terraform plan -destroy -var="projector_url=$PROJECTOR_URL"
```

```text
Plan: 0 to add, 0 to change, 17 to destroy.
```

Ese número es la primera cosa que hay que anotar: **17 recursos, que son los que Terraform cree
administrar**. Guárdalo, porque en §6 lo vas a comparar con la realidad.

```bash
terraform destroy -var="projector_url=$PROJECTOR_URL"
```

Y aquí conviene mirar **el orden**, en vez de esperar a que termine:

```text
google_eventarc_trigger.on_object: Destroying...
google_pubsub_subscription.events_push: Destroying...
google_pubsub_topic_iam_member.api_publishes: Destroying...
google_pubsub_topic.events: Destroying...
google_storage_bucket.data: Destroying...
google_firestore_database.default: Destroying...
```

> 🧠 **Modelo mental.** Terraform destruye **en orden inverso al grafo de dependencias**: primero lo
> que depende de otros, después aquello de lo que dependen. Nadie le dijo que la subscription va
> antes que el topic. Ese grafo es la segunda cosa que compras con Terraform y que un script de
> `gcloud` no te da: un script borra en el orden en que lo escribiste, y falla en cuanto alguien
> añade una dependencia y no reordena.

**Si el `destroy` falla**, el diagnóstico ya lo tienes de [`L03`](l03-terraform-desde-la-cli.md): la pregunta es siempre *¿el candado
lo pone Terraform o lo pone el servicio?*. En este proyecto quedan dos candados vivos, y los dos son
deliberados:

```hcl
# el bucket de datos tiene el objeto de L06 §9 dentro
resource "google_storage_bucket" "data" {
  force_destroy = true
}

# Firestore trae las dos protecciones puestas
resource "google_firestore_database" "default" {
  delete_protection_state = "DELETE_PROTECTION_DISABLED"   # 1. primero un apply
  deletion_policy         = "DELETE"                       # 2. y luego el destroy
}
```

Recuerda la secuencia de [`L03` §9](l03-terraform-desde-la-cli.md#9--los-dos-destroy-que-fallan-a-propósito):
**un `apply` para abrir el candado del servicio y un `destroy` para borrar**. Las dos cosas no caben
en la misma operación.

Los servicios de Cloud Run **no** los administra Terraform en esta serie, así que van a mano:

```bash
gcloud run services delete inv-api --region us-central1 --quiet
gcloud run services delete inv-projector --region us-central1 --quiet
```

> ⚠️ **Ese par de comandos es, en miniatura, el precio de la decisión de arquitectura del curso.**
> Desplegar con `gcloud` hizo [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) y [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) mucho más ágiles —ninguna revisión pasó por un
> `plan`/`apply`— y a cambio dejó dos recursos **fuera del state**, que es justo lo que
> `terraform destroy` no ve. No es un descuido: es el trade-off, y saber nombrarlo es la respuesta
> completa a "¿Terraform para todo o no?".

---

## 5. 🩺 Lo que sobrevivió al `destroy`

Terraform terminó y dijo `Destroy complete! 17 resources destroyed.` Ahora la pregunta de verdad:

```bash
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --format='table(assetType, name)'
```

La lista **no está vacía**, y eso es exactamente lo que este lab quería enseñarte. Lo que queda cae
en cuatro categorías:

| Qué sobrevivió | Por qué | De dónde salió |
|---|---|---|
| Las tres service accounts | Se crearon con `gcloud` | [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) |
| El topic `inv-lab-budget` | Se creó con `gcloud` | [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) |
| El bucket de state | **No puede estar en su propio state** | [`L03`](l03-terraform-desde-la-cli.md) §2 |
| Topic y subscription con nombres raros | Los creó **Eventarc** en tu nombre | [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) §9 |

La cuarta fila es la interesante. Búscalos:

```bash
gcloud pubsub topics list --format='table(name)'
gcloud pubsub subscriptions list --format='table(name, topic)'
```

Si el trigger se borró bien, sus recursos internos se fueron con él. Si aparece alguno huérfano
—con un nombre generado, apuntando a un topic que ya no existe—, acabas de ver de primera mano por
qué un `destroy` exitoso no es una demostración de nada.

Limpia lo que creaste con `gcloud`:

```bash
gcloud pubsub topics delete inv-lab-budget --quiet
gcloud iam service-accounts delete inv-api-sa@inv-lab-472913.iam.gserviceaccount.com --quiet
gcloud iam service-accounts delete inv-projector-sa@inv-lab-472913.iam.gserviceaccount.com --quiet
gcloud iam service-accounts delete inv-pubsub-sa@inv-lab-472913.iam.gserviceaccount.com --quiet
gcloud iam roles delete invLabPublisher --project=inv-lab-472913 --quiet
```

> 📝 **Contexto.** El borrado de un **rol personalizado es reversible durante 7 días**: queda
> deshabilitado antes de desaparecer, y su ID no se puede reutilizar hasta entonces. No es un
> problema, pero explica que `gcloud iam roles list` lo siga mostrando un rato.

Y el bucket de state, **el último de todos**, porque hasta este momento era la memoria de Terraform:

```bash
gcloud storage rm --recursive gs://inv-lab-tfstate-472913
```

---

## 6. 🩺 Capa 2: el barrido de verificación

Ya borraste todo lo que recuerdas. Esta capa existe para lo que **no** recuerdas, y se hace en dos
pasos porque una sola herramienta no basta.

**Paso 1 — el inventario completo.** Cloud Asset Inventory ve todos los tipos de recurso, lleven o
no labels:

```bash
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --format='table(assetType, name, location)'
```

```text
Listed 0 items.
```

> ⚠️ **El índice de Asset Inventory no es instantáneo.** Un recurso recién borrado puede seguir
> apareciendo unos minutos. Si algo sale en la lista y ya no existe, confírmalo con el `describe`
> del servicio antes de asustarte — y al revés: no des por bueno un inventario vacío consultado dos
> segundos después del `destroy`.

**Paso 2 — el barrido dirigido a los sospechosos.** Y aquí está la razón de ser de este paso:

> ⚠️ **Un barrido por labels no demuestra nada.** Los recursos que un controlador crea en tu
> nombre —las forwarding rules de un balanceador, sus reglas de firewall de health check, los
> NEGs— **no llevan tus labels**, y varios tipos de recurso no admiten labels en absoluto. Filtrar
> por `labels.project=inv_lab` pasa justo por encima de los huérfanos que buscas. Los labels sirven
> para **atribuir gasto**; para **demostrar que no quedó nada**, hace falta esto:

```bash
gcloud compute forwarding-rules list --format='table(name, region, IPAddress)'
gcloud compute addresses list        --format='table(name, region, status)'
gcloud compute disks list            --format='table(name, zone, users.list())'
gcloud compute snapshots list        --format='table(name, diskSizeGb)'
gcloud compute firewall-rules list   --format='table(name, network, direction)'
gcloud run services list             --format='table(metadata.name, region)'
gcloud artifacts repositories list   --format='table(name, format, sizeBytes)'
gcloud secrets list                  --format='table(name, createTime)'
```

Los ocho tienen que salir vacíos. Son los tipos que producen el 90 % de las facturas sorpresa, y se
consultan **uno a uno y sin filtro**, precisamente porque el filtro es el que te haría perderlos.

En `addresses`, mira la columna `status`: `RESERVED` significa reservada y **no adjunta**, que es la
tarifa **más cara** que la de una en uso. Es la trampa número dos de
[`A02` §10](a02-costos-trampas-y-recursos-huerfanos.md#10--las-diez-trampas-en-una-tabla).

**Paso 3 — los recommenders, como red final.** Google mantiene detectores de recursos ociosos que
ven cosas que tú no vas a mirar:

```bash
gcloud recommender recommendations list \
  --project=inv-lab-472913 \
  --location=us-central1-a \
  --recommender=google.compute.address.IdleResourceRecommender \
  --format='table(name, primaryImpact.category, description)'
```

- `--recommender` selecciona el detector: hay uno para direcciones IP ociosas, otro para discos,
  otro para VMs infrautilizadas.
- `--location` es zonal o regional según el recommender, y hay que iterarla. Es incómodo, y por eso
  esta capa es la última y no la primera.

---

## 7. 🩺 Lo que vive fuera del proyecto

La parte que casi todo el mundo olvida, y la que sigue cobrando —o quedando— después de borrar el
proyecto entero.

**El presupuesto de [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md).** Cuelga de la **cuenta de facturación**, no del proyecto:

```bash
gcloud billing budgets list --billing-account=01A2B3-C4D5E6-F7G8H9 \
  --format='table(name, displayName)'

gcloud billing budgets delete <BUDGET_ID> \
  --billing-account=01A2B3-C4D5E6-F7G8H9
```

No cobra nada, pero un presupuesto huérfano que apunta a un proyecto inexistente es basura que se
queda ahí para siempre y que ensucia la vista de facturación.

**Las Organization Policies**, si llegaste a crear alguna en [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) §10, cuelgan de la jerarquía y
tampoco mueren con el proyecto.

**La configuración de `gcloud`**, que no está en GCP sino en tu máquina:

```bash
gcloud config configurations activate default
gcloud config configurations delete inv-lab
```

**Y tus credenciales**, que conviene revocar si trabajaste en una máquina compartida:

```bash
gcloud auth application-default revoke
gcloud auth revoke tu-cuenta@gmail.com
```

Recuerda de [`A01`](a01-gcloud-de-supervivencia.md) que son **dos credenciales distintas**: revocar una deja la otra viva.

---

## 8. 🧹 Capa 3: el proyecto como unidad de borrado

La red de seguridad. Y tiene letra pequeña que hay que conocer **antes** de usarla.

> ⚠️ **Deshabilita la facturación primero.** Borrar el proyecto **no corta la facturación al
> instante**: puede seguir acumulando cargos hasta el cierre del ciclo. El orden correcto no es
> negociable.

```bash
gcloud billing projects unlink inv-lab-472913
gcloud billing projects describe inv-lab-472913 --format='value(billingEnabled)'
```

```text
False
```

Comprueba que no hay un **lien** bloqueando el borrado —un lien es una protección explícita contra
el borrado accidental, y este lab no puso ninguno, pero es lo primero que falla cuando alguien
hereda un proyecto ajeno:

```bash
gcloud resource-manager liens list --project=inv-lab-472913
```

Y ahora sí:

```bash
gcloud projects delete inv-lab-472913
```

```text
Your project will be deleted.
Do you want to continue (Y/n)?  Y
Deleted [https://cloudresourcemanager.googleapis.com/v1/projects/inv-lab-472913].
You can undo this operation for a limited period by running the command below.
    $ gcloud projects undelete inv-lab-472913
See https://cloud.google.com/resource-manager/docs/creating-managing-projects for information on shutting down projects.
```

Las tres cosas que hay que saber, y que ese mensaje solo insinúa:

1. **El borrado no es inmediato.** El proyecto queda **30 días** en estado de recuperación antes de
   desaparecer, y durante ese tiempo **sigue contando para tu cuota de proyectos**. Si te quedas sin
   cuota justo después de "limpiar", ya sabes por qué.
2. **`gcloud projects undelete`** lo recupera durante esa ventana. Es una red y también un riesgo:
   un proyecto "borrado" no está borrado.
3. **El `projectId` no se puede reutilizar** nunca, ni después de los 30 días. Es global y es para
   siempre.

> 🧭 **Regla de método.** El borrado del proyecto se usa **después** de que el barrido de §6 haya
> salido vacío, no en lugar de él. Si lo usas antes, funciona igual y no sabes qué había dentro —
> que es precisamente lo que te iban a preguntar.

---

## 9. 🧪 La otra mitad: volver a levantarlo

Destruir es media prueba. La otra media es que se pueda reconstruir, y sin ella el laboratorio es
de un solo uso.

Si no borraste el proyecto, la reconstrucción es corta y conviene hacerla una vez:

```bash
gcloud storage buckets create gs://inv-lab-tfstate-472913 --location=US \
  --uniform-bucket-level-access --public-access-prevention
gcloud storage buckets update gs://inv-lab-tfstate-472913 --versioning

terraform init
terraform plan -out=tfplan -var="projector_url=https://placeholder.invalid"
terraform apply tfplan
```

- El bucket de state se recrea **con `gcloud`**, por la misma razón del huevo y la gallina de
  [`L03`](l03-terraform-desde-la-cli.md) §2.
- El `projector_url` de relleno permite el primer `apply`; después despliegas los servicios con
  `gcloud`, tomas la URL real y vuelves a aplicar. Esa doble pasada es la consecuencia visible del
  reparto Terraform/`gcloud` que eligió la serie, y merece la pena verla una vez.

> 🏁 **Lo que demuestra este ciclo.** Que el HCL versionado en git es suficiente para reconstruir la
> infraestructura desde cero, sin ningún paso manual recordado de memoria. Eso —y no el despliegue—
> es lo que se pregunta cuando alguien dice "tenemos infraestructura como código".

---

## 10. 💰 La comprobación de las 48 horas

El último paso, y el único que no se puede hacer hoy.

Los datos de facturación se consolidan con retraso, del orden de horas. Un recurso que estuvo
encendido veinte minutos esta tarde puede no aparecer todavía en ningún informe. Por eso el cierre
de verdad de la serie es una comprobación diferida:

**A las 48 horas**, abre el informe de facturación filtrado por el label `project=inv_lab` y por el
proyecto, y confirma **$0.00** en el día posterior al teardown. Si aparece cualquier cargo:

1. Ordena por SKU descendente y mira el primero. El nombre del SKU **te dice el recurso exacto**.
2. Cruza ese SKU con la tabla de [`A02` §3](a02-costos-trampas-y-recursos-huerfanos.md#3--el-catálogo-de-lo-que-cobra-por-existir).
3. Vuelve al barrido de §6, esta vez sabiendo qué buscas.

> 🩺 **Diagnóstico.** Un cargo residual después de un teardown correcto tiene tres explicaciones
> típicas, en orden: es de **antes** del teardown y solo se consolidó ahora; el proyecto se borró
> **sin** deshabilitar la facturación primero; o hay algo en **otro proyecto** de la misma cuenta de
> facturación que llevas semanas sin mirar. La tercera es la más frecuente en la vida real.

---

## 📋 Checklist de salida

- [ ] Miraste el informe de facturación por SKU y por label antes de borrar nada.
- [ ] Anotaste cuántos recursos decía destruir `terraform plan -destroy`.
- [ ] Observaste el **orden** en que Terraform destruyó, y sabes por qué es el inverso al grafo.
- [ ] Borraste a mano los servicios de Cloud Run, y sabes por qué no estaban en el state.
- [ ] Sumaste el tamaño de las imágenes de Artifact Registry antes de borrarlas.
- [ ] Después del `destroy`, listaste lo que sobrevivió y supiste clasificar cada superviviente.
- [ ] El bucket de state se borró **el último**.
- [ ] `gcloud asset search-all-resources` devuelve `Listed 0 items.`
- [ ] Los ocho comandos del barrido dirigido salen vacíos, y los ejecutaste **sin filtrar por label**.
- [ ] Borraste el presupuesto, que vive en la cuenta de facturación y no en el proyecto.
- [ ] Deshabilitaste la facturación **antes** de borrar el proyecto, y lo verificaste.
- [ ] Sabes que el proyecto sigue 30 días en recuperación y que su ID no se reutiliza nunca.
- [ ] Reconstruiste la infraestructura desde el HCL al menos una vez.
- [ ] Tienes anotado revisar el informe de facturación **a las 48 horas**.

## 🏁 La señal de que quedó bien

`gcloud asset search-all-resources --scope=projects/inv-lab-472913` no devuelve un solo recurso
facturable, los ocho comandos del barrido dirigido salen vacíos, no queda ningún presupuesto
huérfano en la cuenta de facturación, y el informe de facturación confirma **$0.00** a las 48
horas — que es lo que tarda en consolidarse.

Y la parte que no sale en ningún comando: puedes explicarle a alguien, en tres frases, por qué un
`terraform destroy` exitoso no demuestra nada, qué herramienta lo demuestra y por qué borrar el
proyecto es la red de seguridad y no el ejercicio.

---

## 🧠 Preguntas rápidas

1. ¿Por qué no basta con borrar el proyecto para cerrar la serie?
2. ¿Qué papel tiene cada una de las tres capas del teardown?
3. ¿Cuál es la granularidad útil para leer un cargo en la factura, y por qué no basta con el nombre del producto?
4. ¿Por qué el `$0.00` final no se puede confirmar el mismo día?
5. ¿En qué orden destruye Terraform y quién le dice ese orden?
6. ¿Por qué los servicios de Cloud Run hubo que borrarlos a mano, y qué trade-off refleja eso?
7. Nombra las cuatro categorías de recursos que sobreviven a un `terraform destroy` de este laboratorio.
8. ¿Por qué el bucket de state no puede estar en su propio state, y cuándo se borra?
9. ¿Por qué un barrido por `labels.project=inv_lab` no demuestra que el proyecto quedó limpio?
10. ¿Qué te dice la columna `status` de `gcloud compute addresses list` y cuál de sus valores es el caro?
11. ¿Por qué el inventario de Cloud Asset Inventory puede mentirte justo después de un borrado?
12. ¿Qué queda fuera del proyecto y por lo tanto le sobrevive?
13. ¿En qué orden hay que deshabilitar la facturación y borrar el proyecto, y por qué importa?
14. ¿Qué es un lien y cuándo te lo vas a encontrar?
15. ¿Qué pasa durante los 30 días posteriores a borrar un proyecto, y qué no se puede reutilizar nunca?
16. ¿Qué demuestra volver a levantar la infraestructura desde el HCL, más allá de que funcione?
17. Aparece un cargo 48 horas después de un teardown correcto. ¿Cuáles son las tres explicaciones típicas?

---

## 📚 Referencias oficiales

- Informes de facturación de Cloud: https://cloud.google.com/billing/docs/how-to/reports
- Ver el desglose de costos por SKU: https://cloud.google.com/billing/docs/how-to/cost-table
- Export de datos de facturación a BigQuery: https://cloud.google.com/billing/docs/how-to/export-data-bigquery
- Descripción general de las labels: https://cloud.google.com/resource-manager/docs/labels-overview
- Crear, editar o eliminar presupuestos y alertas: https://cloud.google.com/billing/docs/how-to/budgets
- Deshabilitar la facturación de un proyecto: https://cloud.google.com/billing/docs/how-to/modify-project
- Crear, cerrar y restablecer proyectos: https://cloud.google.com/resource-manager/docs/creating-managing-projects
- Proteger proyectos con liens: https://cloud.google.com/resource-manager/docs/project-liens
- Cloud Asset Inventory: https://cloud.google.com/asset-inventory/docs
- Buscar recursos con Cloud Asset Inventory: https://cloud.google.com/asset-inventory/docs/searching-resources
- `gcloud asset search-all-resources`: https://cloud.google.com/sdk/gcloud/reference/asset/search-all-resources
- Catálogo de recommenders de Active Assist: https://cloud.google.com/recommender/docs/recommenders
- Recomendaciones de recursos ociosos: https://cloud.google.com/compute/docs/viewing-and-applying-idle-resources-recommendations
- Precios de red de VPC (IP externas): https://cloud.google.com/vpc/network-pricing
- Administrar imágenes en Artifact Registry: https://cloud.google.com/artifact-registry/docs/docker/manage-images
- Políticas de limpieza de Artifact Registry: https://cloud.google.com/artifact-registry/docs/repositories/cleanup-policy
- `terraform destroy`: https://developer.hashicorp.com/terraform/cli/commands/destroy
- Grafo de dependencias de Terraform: https://developer.hashicorp.com/terraform/internals/graph
- Eliminar service accounts: https://cloud.google.com/iam/docs/service-accounts-delete-undelete
- Eliminar roles personalizados: https://cloud.google.com/iam/docs/creating-custom-roles
