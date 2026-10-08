# A03 — Catálogo de errores y diagnóstico

> **Objetivo:** poner nombre a los errores de GCP que vas a encontrar en los labs, y para cada
> uno el comando que **confirma o descarta** la causa. No es una lista de soluciones: es un
> método para no arreglar a ciegas.
> **Se asume leído:** nada. Se apoya en [`A01`](a01-gcloud-de-supervivencia.md) para la mecánica
> de `gcloud`, pero cada sección es autosuficiente.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [El método](#1--el-método-una-variable-a-la-vez) ·
[`SERVICE_DISABLED`](#2--service_disabled-la-api-está-apagada) ·
[`PERMISSION_DENIED`](#3--permission_denied-el-error-más-ambiguo-de-gcp) ·
[403 en una entrega push](#4--403-en-una-entrega-push-de-pubsub) ·
[Service agents](#5--el-service-agent-que-no-existía-todavía) ·
[Cloud Run que no arranca](#6--cloud-run-el-contenedor-no-escuchó-en-port) ·
[Firestore y el índice](#7--firestore-failed_precondition-y-el-índice-que-falta) ·
[Terraform](#8--terraform-lo-que-falla-en-plan-apply-y-destroy) ·
[Cuotas](#9--cuota-agotada-y-límites-de-tasa) ·
[Red](#10--red-cuando-no-hay-error-solo-silencio) ·
[Tabla de un vistazo](#11--tabla-de-un-vistazo) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 El método: una variable a la vez

Antes del catálogo, el método. Los errores de nube tienen una propiedad incómoda: casi todos
pueden venir de tres o cuatro causas distintas, y el mensaje rara vez las distingue. Si cambias
tres cosas y funciona, no aprendiste nada — y en la siguiente entrevista no vas a poder explicar
qué pasaba.

> 🧭 **Dos reglas que atraviesan toda la serie práctica: reproducir antes de reparar, y una
> variable a la vez.** Provoca el error a propósito, confirma la hipótesis con un comando que
> devuelva un dato, y solo entonces corrige.

El orden en que conviene sospechar, porque va de lo más barato de comprobar a lo más caro:

```text
1. ¿Estoy en el proyecto/región correctos?   gcloud config list
2. ¿La API está habilitada?                  gcloud services list --enabled
3. ¿Quién soy yo ahora mismo?                gcloud auth list
4. ¿Tengo el permiso, y en QUÉ recurso?      get-iam-policy del recurso, no del proyecto
5. ¿El recurso existe y en qué estado está?  describe --format=json
6. ¿Qué dice la API en crudo?                --log-http
```

Los cuatro primeros son treinta segundos y resuelven la mayoría. El quinto y el sexto son para
cuando el error es de verdad.

> ⚠️ **El anti-patrón que hay que nombrar sin piedad:** conceder `roles/owner` o
> `roles/editor` "para salir del paso". Funciona siempre, no enseña nada, y convierte el lab en
> exactamente lo contrario de lo que pretendía enseñar. Si un `PERMISSION_DENIED` se arregla con
> `roles/owner`, no lo arreglaste: lo tapaste.

---

## 2. 🩺 `SERVICE_DISABLED`: la API está apagada

**El síntoma.** Un comando perfectamente correcto falla con un texto largo que menciona una API
y un enlace para habilitarla:

```text
ERROR: (gcloud.pubsub.topics.create) FAILED_PRECONDITION: Cloud Pub/Sub API has not been
used in project inv-lab-472913 before or it is disabled. Enable it by visiting
https://console.developers.google.com/apis/api/pubsub.googleapis.com/overview?project=inv-lab-472913
then retry. If you enabled this API recently, wait a few minutes for the action to propagate
to our systems and retry.
```

**Qué lo provoca.** En GCP un proyecto nuevo trae casi todas las APIs apagadas. No es un fallo
de permisos: es que el servicio no está activado en ese proyecto. Y es, con diferencia, el
primer error que encuentra cualquiera que empieza.

**Cómo se confirma.**

```bash
gcloud services list --enabled --filter='config.name:pubsub'
```

Si no devuelve nada, ya está confirmado. `--enabled` restringe al catálogo habilitado (sin él,
lista todas las APIs *disponibles*, que son cientos) y el `--filter` busca por nombre de
servicio.

**La corrección.**

```bash
gcloud services enable pubsub.googleapis.com
```

**Lo que hay que saber además**, y es lo que distingue una respuesta buena de una regular en
entrevista:

- El propio mensaje de error te lo dice: **hay retardo de propagación**. Habilitar la API y
  lanzar el comando acto seguido puede fallar igual. Espera y reintenta antes de dudar de tu
  IAM.
- Habilitar una API **no crea nada ni cobra nada** por sí mismo, pero sí puede crear el
  *service agent* de ese servicio (§5).
- Ojo con el mensaje: dice `FAILED_PRECONDITION`, no `PERMISSION_DENIED`. Ese código es la pista
  que separa este caso del siguiente.

---

## 3. 🩺 `PERMISSION_DENIED`: el error más ambiguo de GCP

**El síntoma.**

```text
ERROR: (gcloud.storage.buckets.describe) HTTPError 403: inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
does not have storage.buckets.get access to the Google Cloud Storage bucket.
Permission 'storage.buckets.get' denied on resource (or it may not exist).
```

Fíjate en el paréntesis final —*"or it may not exist"*— porque no es un adorno: **GCP devuelve el
mismo 403 cuando no tienes permiso y cuando el recurso no existe**, deliberadamente, para no
filtrar la existencia de recursos ajenos. Es la primera bifurcación del diagnóstico.

**Las cuatro causas, en orden de frecuencia:**

1. El binding está **en el recurso equivocado**: se lo diste en el proyecto y el permiso se
   evalúa en el bucket, o al revés.
2. **No eres quien crees ser**: la configuración activa apunta a otra cuenta, o estás
   impersonando sin querer (o sin poder).
3. El rol **no contiene ese permiso**. `roles/storage.objectViewer` no incluye
   `storage.buckets.get`; parecen lo mismo y no lo son.
4. El recurso **no existe**, y el 403 te lo está ocultando.

**Cómo se confirma, en cuatro comandos.**

```bash
# 1. ¿Quién soy?
gcloud auth list

# 2. ¿Qué roles tengo EN EL PROYECTO?
gcloud projects get-iam-policy inv-lab-472913 \
  --flatten='bindings[].members[]' \
  --filter='bindings.members:inv-api-sa' \
  --format='value(bindings.role)'

# 3. ¿Y EN EL RECURSO concreto? (aquí es donde aparece el 90 % de los casos)
gcloud storage buckets get-iam-policy gs://inv-lab-data-472913 \
  --format=json

# 4. ¿El recurso existe siquiera, visto por alguien que sí puede?
gcloud storage buckets describe gs://inv-lab-data-472913
```

`--flatten` y `--filter` están explicados en [`A01` §8–§9](a01-gcloud-de-supervivencia.md#8----filter-filtra-en-el-servidor-no-con-grep);
la idea es sacar una fila por par (rol, miembro) para poder buscar por miembro.

**La herramienta que evita adivinar.** GCP tiene un servicio dedicado a responder exactamente
esta pregunta:

```bash
gcloud policy-troubleshoot iam projects/inv-lab-472913 \
  --principal-email=inv-api-sa@inv-lab-472913.iam.gserviceaccount.com \
  --permission=storage.buckets.get \
  --resource=//storage.googleapis.com/projects/_/buckets/inv-lab-data-472913
```

- `--principal-email` es quién intenta la acción.
- `--permission` es el permiso atómico —`storage.buckets.get`, no el rol—. El permiso exacto
  sale del mensaje de error, que siempre lo nombra.
- `--resource` es el nombre completo del recurso en formato de Cloud Asset Inventory. Es la
  parte incómoda de escribir y la que hace útil el comando: obliga a decir **sobre qué recurso**
  se evalúa.

La respuesta no es un sí o un no: es el detalle de **qué política se evaluó en cada nivel de la
jerarquía** y por qué el resultado fue el que fue. Eso es lo que convierte el diagnóstico en
explicación.

> 🧠 **Modelo mental.** Las allow policies de GCP son **aditivas y se heredan hacia abajo**:
> Organization → Folder → Project → recurso. Lo que tienes en un recurso es la unión de todo lo
> que te concedieron en él y por encima de él. **No hay deny implícito ni explícito dentro de una
> allow policy** — para denegar existen las IAM Deny policies, que son otro objeto y se evalúan
> antes.

---

## 4. 🩺 403 en una entrega push de Pub/Sub

**El síntoma.** Nada falla en tu terminal. Publicas un mensaje, el comando devuelve un ID
felizmente, y el servicio de destino no se entera. Los mensajes se acumulan y, si hay
dead-letter configurado, acaban ahí. En los logs de la subscription aparece un 403.

Este es el error más instructivo de toda la serie, porque **ningún emulador lo reproduce** y
porque la cadena tiene cuatro eslabones y cualquiera puede estar roto.

**La cadena completa.**

```text
Pub/Sub  ──(1)──►  firma un OIDC token con la SA que le indicaste en la subscription
         ──(2)──►  llama al endpoint push del servicio de Cloud Run
Cloud Run ─(3)──►  valida el token y comprueba roles/run.invoker para ESA identidad
         ──(4)──►  tu código responde 2xx (ack) o cualquier otra cosa (reintento)
```

Las causas por eslabón:

1. La subscription se creó **sin** `--push-auth-service-account`: no hay token, Cloud Run
   rechaza la llamada como anónima.
2. La service account de Pub/Sub existe pero **el service agent de Pub/Sub no puede crear
   tokens en su nombre** — le falta `roles/iam.serviceAccountTokenCreator` (§5).
3. Esa identidad **no tiene `roles/run.invoker` sobre el servicio de destino**. Es el caso más
   común, y el binding tiene que estar **en el servicio**, no en el proyecto.
4. Tu código responde 500 y todo lo anterior estaba bien. El 403 no aparece; aparecen
   reintentos.

**Cómo se confirma.**

```bash
# ¿Con qué identidad firma Pub/Sub?
gcloud pubsub subscriptions describe inv-events-push \
  --format='value(pushConfig.pushEndpoint, pushConfig.oidcToken.serviceAccountEmail)'

# ¿Quién puede invocar el servicio de destino?
gcloud run services get-iam-policy inv-projector \
  --region us-central1 \
  --flatten='bindings[].members[]' \
  --filter='bindings.role:roles/run.invoker' \
  --format='value(bindings.members)'

# ¿Qué está pasando de verdad en la entrega?
gcloud logging read \
  'resource.type="cloud_run_revision" AND httpRequest.status=403' \
  --limit=10 --freshness=1h \
  --format='table(timestamp, httpRequest.status, protoPayload.authenticationInfo.principalEmail)'
```

- `logging read` acepta la misma sintaxis de consulta que la consola de Cloud Logging.
- `--freshness=1h` limita la ventana temporal; sin él, la consulta barre demasiado.
- `--limit` corta el número de entradas. Sin él te llenas la terminal.

**La corrección**, en el orden en que hay que probarla:

```bash
gcloud run services add-iam-policy-binding inv-projector \
  --region us-central1 \
  --member=serviceAccount:inv-pubsub-sa@inv-lab-472913.iam.gserviceaccount.com \
  --role=roles/run.invoker
```

- `add-iam-policy-binding` **sobre el servicio** —`gcloud run services`— es la clave. El mismo
  binding a nivel proyecto también funcionaría, pero le da a esa identidad permiso de invocar
  **todos** los servicios de Cloud Run del proyecto, hoy y en el futuro. Es la diferencia entre
  un lab que enseña privilegio mínimo y uno que solo consigue que el `curl` deje de fallar.

> 💡 **Truco.** Antes de sospechar de IAM, comprueba que el endpoint es el correcto: un
> `pushEndpoint` apuntando a la URL de otro servicio, o con la ruta equivocada, produce un 404
> que en la subscription se ve casi igual de mudo.

---

## 5. 🩺 El service agent que no existía todavía

**El síntoma.** Un binding que acabas de crear "no se aplica", o un comando falla diciendo que
una cuenta con pinta rara —`service-472913@gcp-sa-pubsub.iam.gserviceaccount.com`— no tiene
permiso. Tú nunca creaste esa cuenta.

**Qué es.** Un **service agent** es una service account que Google crea y administra para que un
servicio actúe en tu proyecto en tu nombre. Pub/Sub necesita una para firmar tokens OIDC;
Eventarc, otra para entregar eventos; Cloud Storage, otra para publicar notificaciones. Tienen
una forma reconocible:

```text
service-<PROJECT_NUMBER>@gcp-sa-<servicio>.iam.gserviceaccount.com
```

Fíjate en que llevan el **projectNumber**, no el projectId. Es una de las pocas veces que
necesitas ese número, y por eso [`A01` §12](a01-gcloud-de-supervivencia.md#12--apis-proyectos-y-cuotas-desde-la-cli)
insiste en la distinción.

**Qué lo provoca.** Dos cosas, y las dos son de tiempo:

1. **El service agent no existe hasta que el servicio se usa por primera vez** (o hasta que se
   fuerza su creación). Un binding que lo nombra antes de que exista falla.
2. **Google lo crea, pero no le concede automáticamente todo lo que necesitará.** El caso
   canónico es el dead-letter de Pub/Sub: el service agent necesita poder publicar en el topic
   de DLQ y consumir de la subscription, y esos dos bindings los tienes que poner tú.

**Cómo se confirma.**

```bash
# el projectNumber, que es lo que va en el nombre del agent
gcloud projects describe inv-lab-472913 --format='value(projectNumber)'

# ¿existe el agent y qué tiene concedido en el proyecto?
gcloud projects get-iam-policy inv-lab-472913 \
  --flatten='bindings[].members[]' \
  --filter='bindings.members:gcp-sa-pubsub' \
  --format='table(bindings.role, bindings.members)'
```

**La corrección para el caso del dead-letter**, que es el que aparece en [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md):

```bash
PROJECT_NUMBER=$(gcloud projects describe inv-lab-472913 --format='value(projectNumber)')
PUBSUB_AGENT="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com"

gcloud pubsub topics add-iam-policy-binding inv-events-dlq \
  --member="$PUBSUB_AGENT" --role=roles/pubsub.publisher

gcloud pubsub subscriptions add-iam-policy-binding inv-events-push \
  --member="$PUBSUB_AGENT" --role=roles/pubsub.subscriber
```

- El primer binding le permite **escribir** el mensaje envenenado en el DLQ.
- El segundo le permite **confirmar** (ack) el mensaje en la subscription original una vez
  reenviado. Sin este, el mensaje se reenvía al DLQ *y además* se sigue reintentando: un bucle
  que se nota en la factura de logs antes que en ningún otro sitio.

> 📝 **Contexto.** Que Google cree la cuenta pero no le dé los permisos parece un descuido y es
> deliberado: concederlos automáticamente significaría que habilitar una API te modifica la
> allow policy del proyecto sin que lo pidas. El precio de esa coherencia es este error.

---

## 6. 🩺 Cloud Run: "el contenedor no escuchó en `PORT`"

**El síntoma.** El despliegue falla al final, después de subir la imagen:

```text
ERROR: (gcloud.run.deploy) Revision 'inv-api-00001-abc' is not ready and cannot serve traffic.
The user-provided container failed to start and listen on the port defined provided by the PORT=8080
environment variable within the allocated timeout.
```

**Qué lo provoca.** El contrato de plataforma de Cloud Run, que tiene tres cláusulas y se
incumplen en este orden de frecuencia:

1. Tu proceso escucha en un puerto **fijo** (el 5000 de Flask, el 3000 de Express) en vez de leer
   la variable de entorno `PORT`.
2. Escucha en `127.0.0.1` en vez de en `0.0.0.0`. Desde fuera del contenedor, eso es no escuchar.
3. Tarda demasiado en arrancar, o revienta antes de llegar a escuchar — y entonces el mensaje
   miente un poco: el problema no es el puerto, es el crash.

**Cómo se confirma.** El mensaje del `deploy` es un resumen; el error real está en los logs de la
revisión:

```bash
gcloud run services logs read inv-api --region us-central1 --limit=50
```

Si ahí ves un stack trace, es el caso 3. Si no ves nada más que el arranque de tu framework
anunciando un puerto que no es el de `PORT`, es el caso 1 o el 2.

**La corrección, del lado del código** (Python, que es el lenguaje del curso):

```python
import os
port = int(os.environ.get("PORT", 8080))   # PORT lo inyecta Cloud Run; el 8080 es el default local
app.run(host="0.0.0.0", port=port)         # 0.0.0.0, nunca 127.0.0.1
```

> 🧠 **Modelo mental.** Cloud Run no ejecuta "tu aplicación": ejecuta **tu contenedor**, le
> inyecta `PORT` y espera que algo escuche ahí en `0.0.0.0` dentro del timeout de arranque. Todo
> lo demás —qué lenguaje, qué framework, qué base— le da igual. Ese es exactamente el contrato
> que ningún `docker run` local te obliga a cumplir, y por eso es materia de nube y no de
> contenedores.

---

## 7. 🩺 Firestore: `FAILED_PRECONDITION` y el índice que falta

**El síntoma.** Una consulta que funcionaba perfectamente contra el emulador falla contra el
servicio:

```text
google.api_core.exceptions.FailedPrecondition: 400 The query requires an index.
You can create it here: https://console.firebase.google.com/project/inv-lab-472913/firestore/indexes?create_composite=...
```

**Qué lo provoca.** Firestore indexa automáticamente cada campo por separado, pero **una consulta
que combina un filtro de igualdad con un ordenamiento por otro campo, o dos rangos, necesita un
índice compuesto declarado**. El emulador no lo exige; el servicio sí. Es el ejemplo canónico de
"lo que te mintió el emulador", y por eso [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) lo provoca a propósito.

**Cómo se confirma.**

```bash
gcloud firestore indexes composite list --format='table(name, fields)'
```

**La corrección.** El enlace del error crea el índice por ti, y está bien para desbloquear hoy.
La solución que uno hace con calma es declararlo en Terraform, junto al resto de la
infraestructura, para que el índice viva en el mismo sitio que la base:

```hcl
resource "google_firestore_index" "events_by_store_and_time" {
  project    = var.project_id
  database   = "(default)"
  collection = "events"

  fields {
    field_path = "store_id"
    order      = "ASCENDING"
  }
  fields {
    field_path = "created_at"
    order      = "DESCENDING"
  }
}
```

- `collection` es el nombre de la colección, no su ruta completa.
- Cada bloque `fields` es una columna del índice, **en el orden en que la consulta las usa**. El
  orden importa: un índice `(store_id, created_at)` no sirve para una consulta que ordena por
  `store_id` dentro de un filtro sobre `created_at`.
- La creación de un índice **tarda** —es una operación de larga duración— y mientras tanto la
  consulta sigue fallando igual.

**El otro `FAILED_PRECONDITION` de Firestore**, que no tiene nada que ver: intentar borrar una
base con `deletion_protection` activo. Ese caso va en §8.

---

## 8. 🩺 Terraform: lo que falla en `plan`, `apply` y `destroy`

Cinco fallos, agrupados por la fase en que aparecen.

**En `init`: el backend no es accesible.**

```text
Error: Failed to get existing workspaces: querying Cloud Storage failed: storage: bucket doesn't exist
```

El bucket del state tiene que existir **antes** del primer `init`, y no puede crearlo el mismo
Terraform que lo va a usar como backend. Es un problema del huevo y la gallina que se resuelve
creando el bucket con `gcloud` una sola vez, que es lo que hace [`L03`](l03-terraform-desde-la-cli.md).

**En `plan`: `must be replaced`.**

```text
  # google_firestore_database.default must be replaced
-/+ resource "google_firestore_database" "default" {
      ~ location_id = "nam5" -> "us-central1" # forces replacement
```

No es un error: es la información más importante que da Terraform. `# forces replacement` marca
un atributo **inmutable**: cambiarlo obliga a destruir y recrear. Leerlo antes de aplicar es lo
que separa un cambio de configuración de una pérdida de datos.

> 🧭 **Regla de método.** Nunca se aplica un plan que dice `must be replaced` sin haber leído
> qué recurso y qué atributo lo fuerzan. Es la misma frontera que verás desde el otro lado en la
> rutina de [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md), cuando un `update` de la API
> rechace un campo inmutable.

**En `plan`: drift.** Alguien tocó en la consola algo que Terraform administra, y el plan
propone deshacerlo. La corrección no es aplicar a ciegas: es decidir cuál de las dos verdades
gana, y si gana la consola, llevar el cambio al HCL. La prevención es la regla de siempre:
**lo que administra Terraform no se toca en la consola**.

**En `apply`: `PERMISSION_DENIED`.** Terraform usa las ADC (§3 de
[`A01`](a01-gcloud-de-supervivencia.md#5--autenticación-dos-credenciales-distintas-que-todos-confunden)),
no tu credencial de `gcloud`. Es literalmente el caso "`gcloud` funciona y Terraform no", y se
resuelve con `gcloud auth application-default login`, no con más roles.

**En `destroy`: el bucket no vacío.**

```text
Error: Error trying to delete bucket inv-lab-data-472913 containing objects without force_destroy set to true
```

Terraform se niega a borrar un bucket con contenido salvo que lo autorices explícitamente:

```hcl
resource "google_storage_bucket" "data" {
  name          = "inv-lab-data-472913"
  location      = "US"
  force_destroy = true   # en un lab, sí; en producción, esto es una bomba
}
```

**En `destroy`: `deletion_protection`.** Firestore y varios recursos más traen una protección
activada **por defecto** que hace fallar el borrado. La secuencia correcta es ponerla en `false`,
aplicar ese cambio, y solo entonces destruir:

```hcl
resource "google_firestore_database" "default" {
  name                = "(default)"
  location_id         = "nam5"
  type                = "FIRESTORE_NATIVE"
  deletion_policy     = "DELETE"     # sin esto, el destroy no borra la base
}
```

> ⚠️ **Un `terraform destroy` que termina con éxito no demuestra que el proyecto quedó limpio.**
> Solo borra lo que está en el state. Lo que creaste a mano, lo que creó un service agent y lo
> que quedó de un `apply` a medias es invisible para él. El barrido de verificación está en
> [`A02` §7](a02-costos-trampas-y-recursos-huerfanos.md#7--el-barrido-de-verificación).

---

## 9. 🩺 Cuota agotada y límites de tasa

**El síntoma.** Dos códigos distintos que la gente confunde:

```text
ERROR: RESOURCE_EXHAUSTED: Quota exceeded for quota metric 'Write requests' and limit
'Write requests per minute' of service 'firestore.googleapis.com'
```

```text
HTTP 429 Too Many Requests
```

**La distinción que importa**, y que es una buena pregunta de entrevista: una **cuota** es un
límite administrativo por proyecto y por API, y muchas son ampliables pidiéndolo; un **límite de
tasa** (429) es un control de flujo del servicio y la respuesta correcta no es pedir más, es
**reintentar con backoff exponencial y jitter**.

**Cómo se confirma.**

```bash
gcloud services quota list \
  --service=firestore.googleapis.com \
  --consumer=projects/inv-lab-472913 \
  --format='table(metric, quotaBuckets[0].effectiveLimit)'
```

**Lo que hay que responder cuando te lo pregunten:** que reintentar inmediatamente empeora el
problema, que el backoff debe tener jitter para no sincronizar a todos los clientes en el mismo
instante, y que en Pub/Sub esa política de reintentos es configurable en la subscription —con
`--min-retry-delay` y `--max-retry-delay`— en vez de escribirla a mano.

---

## 10. 🩺 Red: cuando no hay error, solo silencio

El caso más incómodo: nada devuelve un error, la conexión simplemente no ocurre. Un `curl` que
se queda colgado hasta el timeout no te dice si el problema es firewall, ruta, DNS o que el
destino no escucha.

**El orden de sospecha en una VPC de GCP:**

```text
1. ¿Hay una firewall rule que lo permita?    Las reglas de INGRESS deniegan por defecto
2. ¿Se aplica a esta instancia?              Las rules van por target tags o por SA, no por instancia
3. ¿Qué prioridad gana?                      Número MÁS BAJO gana; el default es 1000
4. ¿Hay ruta hacia el destino?               Longest prefix match
5. ¿El destino escucha de verdad?            Eso ya no es problema de red
```

**El comando que responde casi todo eso de un golpe** — y es la herramienta que conviene conocer,
porque casi nadie la nombra en una entrevista:

```bash
gcloud network-management connectivity-tests create test-subnet-a-googleapis \
  --source-ip-address=10.10.0.5 \
  --source-network=projects/inv-lab-472913/global/networks/inv-lab-vpc \
  --destination-ip-address=199.36.153.8 \
  --destination-port=443 \
  --protocol=TCP

gcloud network-management connectivity-tests describe test-subnet-a-googleapis \
  --format='value(reachabilityDetails.result)'
```

- **`--source-ip-address` es una IP dentro de tu subnet, y no hace falta que exista nada en ella**:
  el análisis es sobre la configuración de red, no sobre un host. Por eso el laboratorio puede
  diagnosticar su VPC sin levantar una sola máquina — ver
  [`L04` §9](l04-red-vpc-firewall-y-diagnostico.md#9--diagnóstico-sin-paquetes-connectivity-tests).
- **Connectivity Tests hace un análisis de configuración, no envía paquetes**: simula el camino
  contra las reglas y rutas reales y te dice en qué salto se cae y por qué regla. Funciona
  aunque la máquina esté apagada, o no exista.
- El resultado es `REACHABLE`, `UNREACHABLE` o `AMBIGUOUS`, y el detalle nombra la regla
  concreta que dropeó el tráfico.
- Los tests son recursos: se listan, y **se borran al terminar**.

**El caso específico del lab.** Una VM sin IP externa que necesita hablar con las APIs de Google
no necesita Cloud NAT: necesita **Private Google Access activado en la subnet**. Se comprueba
así:

```bash
gcloud compute networks subnets describe inv-lab-subnet \
  --region us-central1 \
  --format='value(privateIpGoogleAccess)'
```

Si devuelve `False`, ahí está el silencio.

---

## 11. 📋 Tabla de un vistazo

| Síntoma | Causa más probable | Comando que lo confirma |
|---|---|---|
| `SERVICE_DISABLED` / `FAILED_PRECONDITION` con enlace a una API | API apagada en el proyecto | `gcloud services list --enabled --filter=...` |
| `PERMISSION_DENIED` / 403 en `gcloud` | Binding en el recurso equivocado | `get-iam-policy` **del recurso** + `policy-troubleshoot` |
| Mensajes publicados que nunca llegan | Falta `roles/run.invoker` en el servicio | `gcloud run services get-iam-policy` |
| Mensajes que se reintentan sin fin | Service agent de Pub/Sub sin permiso en el DLQ | `get-iam-policy` filtrado por `gcp-sa-pubsub` |
| "failed to start and listen on PORT" | El proceso no lee `PORT` o escucha en `127.0.0.1` | `gcloud run services logs read` |
| "The query requires an index" | Falta un índice compuesto | `gcloud firestore indexes composite list` |
| `must be replaced` en un plan | Atributo inmutable modificado | Leer el `# forces replacement` del propio plan |
| `destroy` que falla en un bucket | Bucket con objetos y sin `force_destroy` | El propio mensaje |
| `destroy` que falla en Firestore | `deletion_protection` activo | `gcloud firestore databases describe` |
| `RESOURCE_EXHAUSTED` | Cuota del proyecto agotada | `gcloud services quota list` |
| 429 | Límite de tasa del servicio | Backoff con jitter, no pedir más cuota |
| Conexión colgada, sin error | Firewall, ruta o Private Google Access | `connectivity-tests` + `subnets describe` |

---

## 🧠 Preguntas rápidas

1. ¿Qué código de error devuelve GCP cuando la API no está habilitada, y en qué se distingue de un problema de permisos?
2. Acabas de habilitar una API y el comando sigue fallando igual. ¿Cuál es la primera hipótesis?
3. ¿Por qué un 403 de GCP puede significar "no tienes permiso" o "el recurso no existe", y por qué está hecho así?
4. ¿Cuál es la causa más frecuente de un `PERMISSION_DENIED` en esta serie, y qué comando la confirma?
5. ¿Qué te da `gcloud policy-troubleshoot iam` que no te dé un `get-iam-policy`?
6. Una push subscription no entrega nada. Nombra los cuatro eslabones de la cadena y qué puede fallar en cada uno.
7. ¿Por qué el binding de `roles/run.invoker` debe ir en el servicio y no en el proyecto?
8. ¿Qué es un service agent, cómo se reconoce su dirección y por qué lleva el `projectNumber`?
9. ¿Qué dos permisos necesita el service agent de Pub/Sub para que funcione un dead-letter topic, y qué pasa si falta el segundo?
10. Cloud Run dice que el contenedor no escuchó en `PORT`. ¿Cuáles son las tres causas posibles y cómo las distingues?
11. ¿Por qué una consulta de Firestore funciona en el emulador y falla en el servicio?
12. ¿Qué significa `# forces replacement` en un plan de Terraform y qué regla de método impone?
13. `gcloud` funciona y `terraform apply` da `PERMISSION_DENIED` con la misma persona. ¿Por qué?
14. ¿Qué diferencia hay entre `RESOURCE_EXHAUSTED` y un 429, y por qué la respuesta correcta no es la misma?
15. ¿Qué hace un Connectivity Test que no hace un `ping`, y por qué funciona con la VM apagada?
16. Una VM sin IP externa no alcanza las APIs de Google. ¿Qué compruebas antes de pensar en Cloud NAT?

---

## 📚 Referencias oficiales

- Códigos de error de las APIs de Google Cloud: https://cloud.google.com/apis/design/errors
- Habilitar y deshabilitar servicios: https://cloud.google.com/service-usage/docs/enable-disable
- Solución de problemas de IAM: https://cloud.google.com/iam/docs/troubleshooting-access
- Policy Troubleshooter: https://cloud.google.com/policy-intelligence/docs/troubleshoot-access
- Cómo se evalúan las allow policies: https://cloud.google.com/iam/docs/policies
- IAM Deny policies: https://cloud.google.com/iam/docs/deny-overview
- Service agents de Google Cloud: https://cloud.google.com/iam/docs/service-agents
- Autenticación de suscripciones push: https://cloud.google.com/pubsub/docs/authenticate-push-subscriptions
- Reenvío a temas de mensajes no entregados (dead-letter): https://cloud.google.com/pubsub/docs/handling-failures
- Contrato del contenedor de Cloud Run: https://cloud.google.com/run/docs/container-contract
- Solución de problemas de Cloud Run: https://cloud.google.com/run/docs/troubleshooting
- Autenticación de servicio a servicio en Cloud Run: https://cloud.google.com/run/docs/authenticating/service-to-service
- Tipos de índice en Firestore: https://cloud.google.com/firestore/docs/concepts/index-overview
- Gestionar índices en Firestore: https://cloud.google.com/firestore/docs/query-data/indexing
- `google_firestore_index` (provider de Terraform): https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_index
- `google_storage_bucket` y `force_destroy`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
- Backend de state en Cloud Storage: https://developer.hashicorp.com/terraform/language/backend/gcs
- Cuotas y límites de Google Cloud: https://cloud.google.com/docs/quotas
- Reintentos con backoff exponencial: https://cloud.google.com/storage/docs/retry-strategy
- Connectivity Tests: https://cloud.google.com/network-intelligence-center/docs/connectivity-tests/how-to/running-connectivity-tests
- Reglas de firewall de VPC: https://cloud.google.com/firewall/docs/firewalls
- Private Google Access: https://cloud.google.com/vpc/docs/private-google-access
- Cloud Logging: consultas: https://cloud.google.com/logging/docs/view/logging-query-language
