# L01 — Proyecto, jerarquía, `gcloud` y blindaje de costos

> **Objetivo:** dejar un proyecto dedicado, aislado, etiquetado y con un presupuesto que avise
> antes de que la factura sorprenda. Es el lab que se hace **antes** de crear el primer recurso
> que cobra, y el único cuyo entregable es una red de seguridad.
> **Se asume leído:** nada. Conviene tener a mano [`A01`](a01-gcloud-de-supervivencia.md) para
> la mecánica de `gcloud`.
> **Costo:** **$0.00**. Un proyecto, una configuración, unas APIs habilitadas, un topic de
> Pub/Sub y un presupuesto no cobran nada por existir.
> **Duración:** 60–90 minutos.
> **Prerrequisitos:** una cuenta de Google con acceso a una cuenta de facturación con método de
> pago válido, y el SDK de Google Cloud instalado.
> **Qué queda encendido al terminar:** el proyecto `inv-lab-472913`, la configuración `inv-lab`
> de `gcloud`, las APIs habilitadas, el topic `inv-lab-budget` y el presupuesto. Nada de eso
> factura. **Ningún recurso de cómputo, red ni almacenamiento.**
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Por qué este lab va primero](#1--por-qué-este-lab-va-primero) ·
[La jerarquía](#2--la-jerarquía-organization--folder--project) ·
[Autenticación](#3--autenticación-las-dos-credenciales) ·
[La configuración](#4--la-configuración-inv-lab) ·
[Crear el proyecto](#5--crear-el-proyecto-y-vincular-la-facturación) ·
[Labels](#6--labels-de-rastreo) ·
[APIs y `SERVICE_DISABLED`](#7--habilitar-apis-y-provocar-service_disabled-a-propósito) ·
[Cuotas](#8--cuotas-el-límite-que-no-sabías-que-tenías) ·
[Presupuesto](#9--el-presupuesto-y-lo-que-de-verdad-hace) ·
[Notificación a Pub/Sub](#10--notificación-programática-hasta-dónde-llega) ·
[Teardown](#11--teardown-de-este-lab) ·
[Checklist](#-checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 Por qué este lab va primero

El instinto dice empezar desplegando algo: un contenedor, un "hola mundo", cualquier cosa que se
vea. Y es exactamente el orden que produce los dos problemas más comunes de un laboratorio de
nube: recursos repartidos por un proyecto que ya usabas para otra cosa, y una factura que
descubres a los treinta días.

Este lab compra tres cosas, en este orden de importancia:

```text
1. Un contenedor de borrado    → todo el lab vive en UN proyecto que se puede borrar entero
2. Una etiqueta de gasto       → saber qué parte de la factura es del lab
3. Un aviso                    → enterarte en horas, no en semanas
```

> 🧠 **Modelo mental.** En GCP el **proyecto es la unidad de aislamiento, de facturación, de
> cuota y de borrado**, las cuatro cosas a la vez. Por eso el laboratorio crea uno dedicado en
> vez de reutilizar el que ya tienes: al final de la serie, borrar ese proyecto se lleva todo
> lo que hiciste, y solo lo que hiciste.

Esa analogía tiene fecha de caducidad, y conviene ponérsela ya: un proyecto **se parece** a una
carpeta donde guardas recursos, hasta que descubres que también decide quién paga, cuánta cuota
de API tienes, dónde se evalúa tu IAM y qué desaparece de golpe cuando lo borras. Es mucho más
que una carpeta.

---

## 2. 🧱 La jerarquía: Organization → Folder → Project

Antes de crear nada conviene saber dónde va a colgar, porque de eso depende cómo se hereda el
IAM más adelante.

```text
Organization        (existe solo si usas Cloud Identity o Google Workspace)
   │
   ├── Folder       (agrupación opcional: por equipo, por entorno, por unidad de negocio)
   │      │
   │      └── Project        inv-lab-472913
   │                │
   │                └── recursos: buckets, servicios, topics, VPCs…
   │
   └── Project      (un proyecto puede colgar directamente de la organización)
```

Lo que hay que llevarse de este diagrama es una sola frase, y es la que se pregunta en
entrevista:

> 🧠 **Modelo mental.** Las allow policies de IAM **se heredan hacia abajo y son aditivas**. Un
> rol concedido en la Organization se tiene en todos los folders y proyectos debajo. Un rol
> concedido en el proyecto no se "quita" desde abajo: lo que tienes en un recurso es la **unión**
> de todo lo que te dieron en él y por encima de él.

**Si tu cuenta es una cuenta personal de Gmail, no tienes Organization.** No es un problema ni
te falta nada: tus proyectos cuelgan de "No organization" y todo este lab funciona igual. Lo que
no vas a poder practicar es la herencia entre niveles ni las Organization Policies, y eso se dice
aquí en vez de fingir que las tienes.

Para ver qué te tocó:

```bash
gcloud organizations list
```

```text
Listed 0 items.
```

- Si devuelve cero, estás en el caso de cuenta personal. Sigue adelante sin más.
- Si devuelve una organización, anota su ID: te va a servir en [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) para ver la herencia de
  verdad, que es la parte buena.

---

## 3. 🧱 Autenticación: las dos credenciales

Esta es la primera fricción real del curso y conviene resolverla bien, porque vuelve en [`L03`](l03-terraform-desde-la-cli.md)
disfrazada de "Terraform no puede y `gcloud` sí".

```bash
gcloud auth login
```

Abre el navegador, te autentica y guarda un token **para la CLI**. Después de esto,
`gcloud projects list` funciona.

```bash
gcloud auth application-default login
```

Vuelve a abrir el navegador y guarda un archivo distinto, en la ruta estándar de las
**Application Default Credentials (ADC)**. Ese archivo es el que buscan Terraform y las
librerías `google-cloud-*`. Después de esto, tu código funciona.

> 🧠 **Modelo mental.** `gcloud auth login` es "yo, el humano, ante la CLI".
> `gcloud auth application-default login` es "yo, el humano, prestándole mi identidad al código
> que corre en esta máquina". Dos credenciales, dos archivos, dos revocaciones distintas. Que
> una funcione no dice nada sobre la otra.

Haz las dos ahora. Te vas a ahorrar una hora en [`L03`](l03-terraform-desde-la-cli.md).

```bash
gcloud auth list
```

```text
   Credentialed Accounts
ACTIVE  ACCOUNT
*       tu-cuenta@gmail.com
```

---

## 4. 🧱 La configuración `inv-lab`

El problema: si dejas el proyecto del lab como global, el día que trabajes en otra cosa vas a
desplegar en el sitio equivocado. Una **configuración** es un conjunto con nombre de propiedades
que se activa entero.

```bash
gcloud config configurations create inv-lab
```

```text
Created [inv-lab].
Activated [inv-lab].
```

- `configurations create` crea la configuración **y la activa**. El nombre `inv-lab` es el que
  fija el baseline del curso y no cambia en ningún lab.

Las propiedades se fijan después de crear el proyecto (§5), salvo la cuenta, que ya puedes poner:

```bash
gcloud config set account tu-cuenta@gmail.com
```

- `config set account` elige, de entre las credenciales que ya tienes, cuál usa esta
  configuración. No autentica nada.

> 💡 **Truco.** `gcloud config list` es lo primero que hay que mirar cuando un recurso "no
> existe". Nueve de cada diez veces existe y estás apuntando a otro proyecto. El detalle
> completo de configuraciones está en
> [`A01` §3](a01-gcloud-de-supervivencia.md#3--configuraciones-la-pieza-que-casi-nadie-usa-y-lo-arregla-todo).

---

## 5. 🧱 Crear el proyecto y vincular la facturación

**Teardown antes que nada** (regla del curso: ningún recurso se crea sin decir cómo se destruye).
Este proyecto se borra con `gcloud projects delete inv-lab-472913` **después** de deshabilitar
la facturación, y el borrado tarda 30 días en consumarse. El desarrollo completo está en §11 y
en [`L08`](l08-costos-y-destruccion-verificada.md).

```bash
gcloud projects create inv-lab-472913 \
  --name="Inventario Lab" \
  --labels=project=inv_lab
```

- El primer argumento es el **`projectId`**: único **en todo Google Cloud**, entre 6 y 30
  caracteres, minúsculas, números y guiones, y **inmutable**. Por eso todo el mundo le pega un
  sufijo numérico: `inv-lab` a secas está tomado hace años. Elige el tuyo y sostenlo — este
  documento usa `inv-lab-472913` en todas las salidas.
- `--name` es la etiqueta legible que ves en la consola. **Sí se puede cambiar** después. No es
  el identificador.
- `--labels` pone ya el label de rastreo. Ver §6.

Y el tercer identificador, el que no elegiste:

```bash
gcloud projects describe inv-lab-472913 \
  --format='table(projectId, name, projectNumber)'
```

```text
PROJECT_ID       NAME            PROJECT_NUMBER
inv-lab-472913   Inventario Lab  384756192043
```

> 📝 **Contexto.** El `projectNumber` lo asigna Google y no se elige. Parece un dato inútil hasta
> [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md): los **service agents** —las service accounts que Google crea para que sus servicios
> actúen en tu proyecto— llevan ese número en su dirección
> (`service-384756192043@gcp-sa-pubsub.iam.gserviceaccount.com`). Cuando aparezca en un error, ya
> sabes de dónde salió.

**Vincular la facturación.** Un proyecto sin cuenta de facturación no puede habilitar casi
ninguna API: es el segundo error del principiante, y se manifiesta como un fallo al habilitar
servicios que no menciona la facturación por ninguna parte.

```bash
gcloud billing accounts list
```

```text
ACCOUNT_ID            NAME                OPEN  MASTER_ACCOUNT_ID
01A2B3-C4D5E6-F7G8H9  Mi cuenta de pago   True
```

```bash
gcloud billing projects link inv-lab-472913 \
  --billing-account=01A2B3-C4D5E6-F7G8H9
```

- `billing projects link` asocia el proyecto a la cuenta que va a pagar. Es una relación
  **externa al proyecto**: la cuenta de facturación vive en la jerarquía de facturación, no
  dentro del proyecto, y eso explica por qué el presupuesto de §9 sobrevive al borrado del
  proyecto.
- Necesitas ser `roles/billing.user` (o superior) sobre esa cuenta de facturación. Si te falla
  aquí y eres el dueño de la cuenta, casi seguro estás autenticado con otra identidad: `gcloud
  auth list`.

Ahora sí, termina de configurar:

```bash
gcloud config set project inv-lab-472913
gcloud config set compute/region us-central1
gcloud config set run/region us-central1
```

- `compute/region` y `run/region` son propiedades **de sección distintas**: fijar una no fija la
  otra, y ningún comando lee las dos. Es la causa número uno de "pero si ya puse la región".

---

## 6. 🧱 Labels de rastreo

```bash
gcloud projects update inv-lab-472913 --update-labels=project=inv_lab,env=lab
```

- `--update-labels` agrega o cambia labels sin tocar los demás. Para quitar uno,
  `--remove-labels=clave`.

> ⚠️ **Los labels de GCP no admiten mayúsculas ni la mayoría de los signos.** Clave y valor
> aceptan minúsculas, números, guiones y guiones bajos. Por eso el label del laboratorio es
> `project=inv_lab` y no `Project=inv-lab`: no es una preferencia de estilo, es lo que la API
> acepta. Si intentas la versión con mayúscula, el error es inmediato y explícito.

El label se pone en **cada recurso** que crees a lo largo de la serie, no solo en el proyecto.
Sirve para una cosa y conviene no confundirse sobre cuál:

```text
labels  →  ATRIBUIR GASTO en el informe de facturación
labels  →  NO demuestran que un teardown quedó limpio
```

La segunda línea es la diferencia más importante frente a un laboratorio equivalente en otra
nube, y está desarrollada en
[`A02` §6](a02-costos-trampas-y-recursos-huerfanos.md#6--por-qué-un-barrido-por-labels-no-demuestra-nada):
los recursos que un controlador crea en tu nombre no llevan tus labels, y hay tipos de recurso
que directamente no admiten labels.

---

## 7. 🩺 Habilitar APIs, y provocar `SERVICE_DISABLED` a propósito

Aquí está el primer error del curso, y se provoca antes de arreglarlo — que es el método de toda
la serie práctica. Intenta usar un servicio sin haberlo habilitado:

```bash
gcloud pubsub topics create inv-lab-budget
```

```text
ERROR: (gcloud.pubsub.topics.create) FAILED_PRECONDITION: Cloud Pub/Sub API has not been used
in project inv-lab-472913 before or it is disabled. Enable it by visiting
https://console.developers.google.com/apis/api/pubsub.googleapis.com/overview?project=inv-lab-472913
then retry. If you enabled this API recently, wait a few minutes for the action to propagate
to our systems and retry.
```

Léelo entero, porque hay tres cosas dentro:

- **El código es `FAILED_PRECONDITION`, no `PERMISSION_DENIED`.** Ese detalle te ahorra media
  hora de revisar IAM cuando el problema no era IAM. El catálogo completo de errores está en
  [`A03`](a03-catalogo-de-errores-y-diagnostico.md).
- **En GCP un proyecto nuevo trae casi todo apagado.** No es un fallo: es el modelo. Cada
  producto es una API que se activa explícitamente en cada proyecto.
- **El propio mensaje avisa del retardo de propagación.** Guárdalo para dentro de dos párrafos.

Confirma la hipótesis antes de corregir:

```bash
gcloud services list --enabled --filter='config.name:pubsub'
```

```text
Listed 0 items.
```

- `--enabled` restringe a lo habilitado en el proyecto activo. **Sin ese flag el comando lista el
  catálogo completo de APIs disponibles**, que son cientos y no responde a la pregunta.

Ahora sí, la corrección. Habilita de una vez todo lo que la serie va a necesitar:

```bash
gcloud services enable \
  pubsub.googleapis.com \
  run.googleapis.com \
  firestore.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  secretmanager.googleapis.com \
  compute.googleapis.com \
  cloudasset.googleapis.com \
  cloudbilling.googleapis.com \
  billingbudgets.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  networkmanagement.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com
```

- Acepta varias APIs en una sola invocación, y conviene: cada una es una operación de larga
  duración y hacerlo de golpe es mucho más rápido que una por una.
- **Habilitar una API no crea nada ni cobra nada por sí misma.** Lo que sí puede hacer es crear
  el *service agent* de ese servicio, que es una service account gestionada por Google. La verás
  aparecer sola en [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md).
- `compute.googleapis.com` habilita bastante más que las VMs: de ella cuelgan la VPC, las
  firewall rules y las direcciones IP. Sin ella, [`L04`](l04-red-vpc-firewall-y-diagnostico.md) no arranca.

Y ahora el detalle que el mensaje de error anticipaba:

```bash
gcloud pubsub topics create inv-lab-budget --labels=project=inv_lab
```

```text
ERROR: (gcloud.pubsub.topics.create) FAILED_PRECONDITION: Cloud Pub/Sub API has not been used
in project inv-lab-472913 before or it is disabled.
```

Otra vez. No te has equivocado: **la habilitación propaga con retardo**. Espera treinta segundos
y repite. Si a la tercera sigue fallando, ahí sí toca dudar de otra cosa.

```bash
gcloud pubsub topics create inv-lab-budget --labels=project=inv_lab
```

```text
Created topic [projects/inv-lab-472913/topics/inv-lab-budget].
```

> 🩺 **Diagnóstico.** La secuencia "habilito, falla, espero, funciona" es la que hay que
> reconocer sin pensar. Es responsable de una cantidad absurda de tiempo perdido revisando roles
> que estaban perfectos.

**Teardown de lo creado en esta sección:** `gcloud pubsub topics delete inv-lab-budget`. Las APIs
habilitadas se pueden deshabilitar con `gcloud services disable`, pero **no hace falta**: una API
habilitada no cobra nada.

---

## 8. 🧱 Cuotas: el límite que no sabías que tenías

Cada proyecto tiene límites por API, y son la explicación de varios fallos que parecen aleatorios
cuando aparecen: el `RESOURCE_EXHAUSTED` que corta un `apply` a la mitad en
[`L03`](l03-terraform-desde-la-cli.md) o una ráfaga de reintentos en
[`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md). El catálogo con el comando que
confirma cada caso está en
[`A03` §9](a03-catalogo-de-errores-y-diagnostico.md#9--cuota-agotada-y-límites-de-tasa).

```bash
gcloud services quota list \
  --service=run.googleapis.com \
  --consumer=projects/inv-lab-472913 \
  --format='table(metric, quotaBuckets[0].effectiveLimit)'
```

- `--consumer` usa el formato `projects/<projectId>`, no el ID a secas.
- `quotaBuckets[0].effectiveLimit` es el límite vigente. La respuesta cruda trae varios buckets
  —por región, por dimensión— y esta proyección se queda con el primero para que la tabla sea
  legible; el detalle real está en el `--format=json`.

Lo que hay que saber, más que el comando:

- Las cuotas son **por proyecto y por API**, y muchas son ampliables pidiéndolo.
- Superarlas devuelve `RESOURCE_EXHAUSTED`, que **no es lo mismo que un `429`**: el 429 es un
  límite de tasa del servicio y su respuesta correcta es reintentar con backoff exponencial y
  jitter, no pedir más cuota. Esa distinción es una buena pregunta de entrevista y está en
  [`A03` §9](a03-catalogo-de-errores-y-diagnostico.md#9--cuota-agotada-y-límites-de-tasa).
- Un proyecto en estado de borrado **sigue contando** para tu cuota de proyectos durante los 30
  días de recuperación.

---

## 9. 💰 El presupuesto, y lo que de verdad hace

Ahora la red de seguridad. Y empieza por lo que **no** es, porque responder mal a esto en una
entrevista se nota:

> ⚠️ **Un presupuesto de Cloud Billing no es un tope de gasto.** Te avisa cuando el gasto cruza
> un umbral. No detiene nada, no apaga nada y no impide que se siga facturando. "Pongo un
> presupuesto de $10 y así no gasto más" es una respuesta incorrecta.

Con eso claro, se crea así:

```bash
gcloud billing budgets create \
  --billing-account=01A2B3-C4D5E6-F7G8H9 \
  --display-name="inv-lab" \
  --budget-amount=10USD \
  --filter-projects=projects/384756192043 \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0 \
  --threshold-rule=percent=1.0,basis=forecasted-spend
```

Flag por flag, porque aquí cada uno decide algo:

- `--billing-account` es dónde vive el presupuesto. **No es un recurso del proyecto**: cuelga de
  la cuenta de facturación. Consecuencia directa: sobrevive al borrado del proyecto y hay que
  limpiarlo aparte en [`L08`](l08-costos-y-destruccion-verificada.md).
- `--budget-amount=10USD` es el importe de referencia. Diez dólares es generoso para una serie
  que cuesta menos de uno; lo que importa es que los umbrales disparen mucho antes de que el
  gasto sea un problema.
- `--filter-projects` restringe el presupuesto a **este** proyecto. Y ojo con el formato:
  `projects/<projectNumber>`, no el `projectId`. Es otro sitio donde ese número reaparece. Sin
  este filtro, el presupuesto vigila el gasto de toda la cuenta de facturación.
- `--threshold-rule=percent=0.5` dispara una alerta al 50 % del importe. Se pueden repetir tantas
  como quieras, y conviene tener varias: una sola al 100 % te avisa cuando ya pasó.
- `basis=forecasted-spend` es el umbral que de verdad sirve en un lab: dispara cuando la
  **proyección del mes** llega al 100 %, no el gasto acumulado. Un recurso olvidado que cobra por
  hora se detecta así en horas, no a fin de mes. Sin `basis`, el default es `current-spend`.

Verifica que quedó:

```bash
gcloud billing budgets list --billing-account=01A2B3-C4D5E6-F7G8H9 \
  --format='table(displayName, amount.specifiedAmount.units, budgetFilter.projects)'
```

**Teardown:** `gcloud billing budgets delete <BUDGET_ID> --billing-account=01A2B3-C4D5E6-F7G8H9`.
Anótalo, porque es lo que más gente se olvida: el presupuesto no está dentro del proyecto y por
lo tanto no muere con él.

> 💰 **Costo.** Un presupuesto y sus alertas no cuestan nada. Los datos de facturación en los que
> se basa **se consolidan con retraso**, del orden de horas, así que ninguna alerta es en tiempo
> real. Ese retraso es también la razón de que el `$0.00` final de [`L08`](l08-costos-y-destruccion-verificada.md) haya que confirmarlo a
> las 48 horas y no al terminar la sesión.

---

## 10. 🧱 Notificación programática: hasta dónde llega

Las alertas por correo están bien para un humano. Si quieres que ocurra *algo*, el presupuesto
tiene que publicar en un topic de Pub/Sub — el `inv-lab-budget` que creaste en §7.

```bash
gcloud billing budgets update <BUDGET_ID> \
  --billing-account=01A2B3-C4D5E6-F7G8H9 \
  --notifications-rule-pubsub-topic=projects/inv-lab-472913/topics/inv-lab-budget
```

- `--notifications-rule-pubsub-topic` acepta el **resource name completo** del topic, no el
  nombre corto. Es el mismo formato `projects/…/topics/…` que viste en la salida de la creación.
- A partir de aquí, el presupuesto publica un mensaje JSON **cada vez que evalúa el gasto**, no
  solo al cruzar un umbral. El mensaje trae el importe del presupuesto, el gasto acumulado y qué
  umbral se superó, si alguno.

El `<BUDGET_ID>` sale de:

```bash
gcloud billing budgets list --billing-account=01A2B3-C4D5E6-F7G8H9 \
  --format='value(name)'
```

```text
billingAccounts/01A2B3-C4D5E6-F7G8H9/budgets/8b2c1f4e-0a77-4c39-9a1e-2f6d5c3b7e10
```

El identificador que pide `update` es el UUID final.

**Hasta dónde llega esto.** El patrón que documenta Google para actuar sobre esa notificación
llega hasta **deshabilitar la facturación del proyecto** desde una función que consume el topic.
Funciona, y es drástico: apaga todo el proyecto, no solo lo caro, y recuperarlo después no es
inmediato. Este lab deja el topic listo y **no conecta el disparo**, por dos razones: porque un
lab que se autodestruye a mitad no enseña nada, y porque el mecanismo que de verdad va a mantener
tu factura en cero es el teardown de cada sesión, no un cortacircuitos.

> 🧠 **Modelo mental.** El presupuesto es el detector de humo, no el extintor. El extintor es
> `terraform destroy` más el barrido de
> [`L08`](l08-costos-y-destruccion-verificada.md), y se usa al final de cada sesión.

---

## 11. 🧹 Teardown de este lab

Lo que dejaste montado, y qué hacer con cada cosa:

| Recurso | ¿Cobra? | Qué hacer al terminar la serie |
|---|---|---|
| Proyecto `inv-lab-472913` | No | Deshabilitar facturación **y luego** borrarlo ([`L08`](l08-costos-y-destruccion-verificada.md)) |
| Configuración `inv-lab` de `gcloud` | No | `gcloud config configurations delete inv-lab` — es local, no está en GCP |
| APIs habilitadas | No | Nada. Se van con el proyecto |
| Topic `inv-lab-budget` | No | `gcloud pubsub topics delete inv-lab-budget` |
| Presupuesto | No | **Borrarlo aparte:** vive en la cuenta de facturación, no en el proyecto |

Como este lab no crea nada que facture, el teardown **no es urgente**: puedes dejarlo montado
toda la serie, que es justamente para lo que sirve. Lo que sí conviene verificar ya es que no se
te coló nada:

```bash
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --format='table(assetType, name)'
```

```text
ASSET_TYPE                    NAME
pubsub.googleapis.com/Topic   //pubsub.googleapis.com/projects/inv-lab-472913/topics/inv-lab-budget
```

Un solo recurso, y no cobra. Ese es el estado correcto al cerrar `L01`.

> ⚠️ **Y la letra pequeña del borrado de proyecto, que hay que conocer desde hoy aunque se use en
> [`L08`](l08-costos-y-destruccion-verificada.md):** el proyecto queda **30 días** en estado de recuperación antes de desaparecer y sigue
> contando para tu cuota; **borrarlo no corta la facturación al instante**, así que lo correcto es
> deshabilitar la facturación *antes*; y un **lien** sobre el proyecto bloquea el borrado hasta
> que lo quites.

---

## 📋 Checklist de salida

- [ ] `gcloud config configurations list` muestra `inv-lab` como activa.
- [ ] `gcloud config list` muestra el proyecto, la cuenta y las dos regiones (`compute/region` y `run/region`).
- [ ] `gcloud auth list` **y** el archivo de ADC existen: hiciste los dos `login`.
- [ ] `gcloud billing projects describe inv-lab-472913` confirma `billingEnabled: true`.
- [ ] `gcloud projects describe inv-lab-472913 --format='value(labels)'` devuelve el label `project=inv_lab`.
- [ ] Provocaste el `SERVICE_DISABLED` a propósito y sabes que su código es `FAILED_PRECONDITION`.
- [ ] `gcloud services list --enabled` incluye las dieciséis APIs de §7.
- [ ] `gcloud billing budgets list` devuelve el presupuesto, con al menos un umbral sobre `forecasted-spend`.
- [ ] El presupuesto publica en `inv-lab-budget` y anotaste su `BUDGET_ID` para poder borrarlo en [`L08`](l08-costos-y-destruccion-verificada.md).
- [ ] Anotaste el `projectNumber`: lo vas a necesitar en [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md).

## 🏁 La señal de que quedó bien

`gcloud asset search-all-resources --scope=projects/inv-lab-472913` devuelve **un solo recurso**
—el topic del presupuesto—, el informe de facturación del proyecto está en $0.00, y puedes
explicar por qué el presupuesto que acabas de crear no va a impedir que gastes.

---

## 🧠 Preguntas rápidas

1. ¿Qué cuatro cosas es un proyecto en GCP, a la vez?
2. ¿En qué se diferencian el `projectId`, el `name` y el `projectNumber`, y dónde te vas a topar con el tercero?
3. ¿Qué pasa si tu cuenta es una cuenta personal de Gmail? ¿Qué parte de la jerarquía no vas a poder practicar?
4. ¿En qué dirección se heredan las allow policies y qué significa que sean aditivas?
5. ¿Cuál de las dos credenciales de `gcloud auth` usa Terraform, y por qué eso produce el clásico "`gcloud` sí y Terraform no"?
6. ¿Por qué fijar `compute/region` no basta para los comandos de `gcloud run`?
7. ¿Qué código de error devuelve GCP cuando la API está apagada, y en qué se distingue de un problema de permisos?
8. Habilitaste la API y el siguiente comando falla igual. ¿Cuál es la primera hipótesis?
9. ¿Por qué el label del laboratorio es `project=inv_lab` y no `Project=inv-lab`?
10. ¿Para qué sirven los labels y para qué **no** sirven?
11. ¿Un presupuesto de Cloud Billing detiene el gasto? Si no, ¿qué hay que montar para que ocurra algo automáticamente?
12. ¿Por qué `--filter-projects` pide el `projectNumber` y no el `projectId`?
13. ¿Qué diferencia hay entre un umbral sobre `current-spend` y uno sobre `forecasted-spend`, y cuál sirve más en un lab?
14. ¿Dónde vive un presupuesto y por qué sobrevive al borrado del proyecto?
15. ¿Qué tres cosas hay que saber antes de usar `gcloud projects delete` como mecanismo de teardown?

---

## 📚 Referencias oficiales

- Crear y administrar proyectos: https://cloud.google.com/resource-manager/docs/creating-managing-projects
- Jerarquía de recursos de Google Cloud: https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy
- Crear y administrar carpetas: https://cloud.google.com/resource-manager/docs/creating-managing-folders
- Eliminar y restaurar proyectos: https://cloud.google.com/resource-manager/docs/creating-managing-projects
- Proteger proyectos con liens: https://cloud.google.com/resource-manager/docs/project-liens
- Descripción general de las labels: https://cloud.google.com/resource-manager/docs/labels-overview
- Configuraciones del SDK: https://cloud.google.com/sdk/docs/configurations
- `gcloud auth login`: https://cloud.google.com/sdk/gcloud/reference/auth/login
- `gcloud auth application-default login`: https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login
- Credenciales predeterminadas de la aplicación (ADC): https://cloud.google.com/docs/authentication/application-default-credentials
- Habilitar y deshabilitar servicios: https://cloud.google.com/service-usage/docs/enable-disable
- `gcloud services enable`: https://cloud.google.com/sdk/gcloud/reference/services/enable
- Cuotas y límites de Google Cloud: https://cloud.google.com/docs/quotas
- Modificar la cuenta de facturación de un proyecto: https://cloud.google.com/billing/docs/how-to/modify-project
- Control de acceso de Cloud Billing: https://cloud.google.com/billing/docs/how-to/billing-access
- Crear, editar o eliminar presupuestos y alertas: https://cloud.google.com/billing/docs/how-to/budgets
- Notificaciones programáticas de presupuesto: https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications
- Deshabilitar la facturación con notificaciones: https://cloud.google.com/billing/docs/how-to/disable-billing-with-notifications
- `gcloud billing budgets`: https://cloud.google.com/sdk/gcloud/reference/billing/budgets
- Service agents de Google Cloud: https://cloud.google.com/iam/docs/service-agents
- Buscar recursos con Cloud Asset Inventory: https://cloud.google.com/asset-inventory/docs/searching-resources
