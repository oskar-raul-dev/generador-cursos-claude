# L06 — Datos y eventos: Firestore, Pub/Sub y Eventarc

> **Objetivo:** cerrar el sistema del laboratorio: `inv-api` escribe en Firestore de forma
> idempotente y publica en Pub/Sub; una push subscription con token OIDC invoca a `inv-projector`,
> que actualiza el stock en una transacción; un mensaje envenenado acaba en el dead-letter topic; y
> un trigger de Eventarc cierra el cuadro. Es el lab de los errores que ningún emulador reproduce.
> **Se asume leído:** [`L03`](l03-terraform-desde-la-cli.md) —la infraestructura es suya— y
> [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md). Rinde mucho más con
> [`04`](04-firestore-bigtable-nosql.md) y [`07`](07-pubsub-eventarc-integracion.md) leídos.
> **Costo:** **centavos.** El tráfico del lab cabe en las cuotas Always Free de Firestore (1 GiB;
> 50.000 lecturas, 20.000 escrituras y 20.000 borrados **al día**), Pub/Sub (10 GiB de mensajes) y
> Cloud Run. El único cargo acumulativo sigue siendo Artifact Registry.
> **Duración:** 3–4 horas.
> **Prerrequisitos:** `L01`–`L05` completos. Firestore `(default)` creada en [`L03`](l03-terraform-desde-la-cli.md), `inv-api`
> desplegado en [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md), las tres service accounts de [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md).
> **Qué queda encendido al terminar:** el sistema completo — dos servicios de Cloud Run con
> escalado a cero, el topic, la push subscription, el dead-letter topic y el trigger de Eventarc.
> Sin tráfico, todo eso cuesta $0.00.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Lo que vas a montar](#1--lo-que-vas-a-montar) ·
[La infraestructura en HCL](#2--la-infraestructura-en-hcl) ·
[Escritura idempotente](#3--escritura-idempotente-y-la-transacción) ·
[El índice que el emulador no exige](#4--el-índice-que-el-emulador-no-te-exige) ·
[La push subscription](#5--la-push-subscription-con-token-oidc) ·
[Provocar el 403](#6--provocar-el-403-de-la-entrega-push) ·
[Reintentos](#7--reintentos-ack-deadline-y-at-least-once) ·
[El mensaje envenenado](#8--el-mensaje-envenenado-y-el-dead-letter) ·
[Eventarc](#9--eventarc-y-el-service-agent-que-nadie-recuerda) ·
[Qué mintió el emulador](#10--qué-te-mintió-el-emulador) ·
[Teardown](#11--teardown-de-este-lab) ·
[Checklist](#-checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 Lo que vas a montar

```text
  curl  (con identity token)
    │
    ▼
  inv-api (Cloud Run, sin acceso anónimo)
    │
    ├──►  Firestore  ── colección events   (escritura idempotente por event_id)
    │
    └──►  Pub/Sub topic  inv-events
                 │   push subscription, token OIDC firmado con inv-pubsub-sa
                 ▼
           inv-projector (Cloud Run)  ──►  Firestore ── colección stock  (transacción)
                 │   tras 5 intentos fallidos
                 ▼
           dead-letter topic  inv-events-dlq

  bucket inv-lab-data ──► trigger de Eventarc ──► inv-projector
```

Es deliberadamente pequeño, y cada pieza está por un motivo que **solo se aprende contra el
servicio real**:

- **La escritura idempotente** responde a la pregunta de entrevista más frecuente sobre
  procesamiento asíncrono: *"tu consumidor recibe el mismo mensaje dos veces, ¿qué pasa?"*.
- **La push subscription con OIDC** es puro GCP: Pub/Sub firma un token con la identidad que le
  indicaste, Cloud Run lo valida, y la entrega falla con 403 si un binding no está exactamente
  donde tiene que estar. Ningún emulador reproduce eso.
- **El dead-letter topic** te deja provocar un mensaje envenenado y ver a dónde va — y tropezar con
  el permiso que todo el mundo olvida.
- **El trigger de Eventarc** cierra el cuadro de integración sin añadir infraestructura que cobre, y
  trae su propia lección sobre service agents.

> 🧠 **Modelo mental.** [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) te enseñó el contrato de **una** caja. Este lab enseña el contrato
> **entre** cajas: quién invoca a quién, con qué identidad, cuántas veces y qué pasa cuando falla.
> Por eso son dos labs y no uno: cuando algo se rompa, tienes que poder decir si el problema es del
> contenedor o de la entrega.

---

## 2. 🧱 La infraestructura en HCL

Todo lo de esta sección lo administra Terraform y se destruye con `terraform destroy` — que es lo
que [`L08`](l08-costos-y-destruccion-verificada.md) va a verificar. **Ninguno de estos recursos cobra por existir**: los topics y las
subscriptions cobran por volumen de mensajes, y la base de Firestore por almacenamiento y
operaciones.

```hcl
# events.tf — el topic, su dead-letter y la push subscription

resource "google_pubsub_topic" "events" {
  name   = "inv-events"
  labels = { project = "inv_lab" }

  message_retention_duration = "86400s"   # 1 día de retención en el topic
}

resource "google_pubsub_topic" "dlq" {
  name   = "inv-events-dlq"
  labels = { project = "inv_lab" }
}

resource "google_pubsub_subscription" "events_push" {
  name  = "inv-events-push"
  topic = google_pubsub_topic.events.id

  push_config {
    # la URL de inv-projector entra como variable: ver el aviso de abajo
    push_endpoint = "${var.projector_url}/events"

    oidc_token {
      service_account_email = "inv-pubsub-sa@inv-lab-472913.iam.gserviceaccount.com"
    }
  }

  ack_deadline_seconds = 30

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq.id
    max_delivery_attempts = 5
  }
}
```

> ⚠️ **`push_endpoint` necesita la URL de `inv-projector`, que todavía no existe.** Es la
> dependencia incómoda del reparto que eligió esta serie —Terraform administra la infraestructura,
> `gcloud` despliega los servicios—, y se resuelve del modo más simple: se declara como variable,
> se despliega primero `inv-projector` (§3) y se aplica el HCL pasándole su URL. Escribir el
> endpoint a mano funcionaría; declararlo como variable es lo que hace que el `apply` sea
> repetible y que un `terraform destroy` seguido de un `apply` reconstruya lo mismo.

```hcl
# variables.tf
variable "projector_url" {
  type        = string
  description = "URL del servicio inv-projector, obtenida tras su primer despliegue"
}
```

Los campos que deciden el comportamiento, uno a uno:

- **`ack_deadline_seconds = 30`**: cuánto espera Pub/Sub tu confirmación antes de dar la entrega
  por fallida y reintentar. Para una push subscription, **es el tiempo que tiene tu endpoint para
  devolver un 2xx**. Si tu handler tarda 45 segundos, Pub/Sub ya reintentó a los 30 — y ahí nace un
  duplicado que no es culpa de la red.
- **`retry_policy`**: backoff exponencial entre reintentos, de 10 a 600 segundos. Sin política
  explícita, Pub/Sub reintenta inmediatamente, lo que en un endpoint caído es un martillazo.
- **`dead_letter_policy`**: tras `max_delivery_attempts = 5` entregas fallidas, el mensaje se
  reenvía al topic de DLQ en lugar de reintentarse para siempre. El mínimo que acepta el servicio
  es 5; ponerlo bajo es lo correcto en un lab, donde quieres ver el DLQ hoy y no mañana.

Y los permisos, que son la mitad del lab:

```hcl
# iam-events.tf

# inv-api publica en el topic — binding EN EL TOPIC, no en el proyecto
resource "google_pubsub_topic_iam_member" "api_publishes" {
  topic  = google_pubsub_topic.events.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com"
}

# Pub/Sub invoca a inv-projector con la identidad inv-pubsub-sa
resource "google_cloud_run_service_iam_member" "pubsub_invokes_projector" {
  location = "us-central1"
  service  = "inv-projector"
  role     = "roles/run.invoker"
  member   = "serviceAccount:inv-pubsub-sa@inv-lab-472913.iam.gserviceaccount.com"
}

# los dos servicios escriben en Firestore
resource "google_project_iam_member" "api_firestore" {
  project = "inv-lab-472913"
  role    = "roles/datastore.user"
  member  = "serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "projector_firestore" {
  project = "inv-lab-472913"
  role    = "roles/datastore.user"
  member  = "serviceAccount:inv-projector-sa@inv-lab-472913.iam.gserviceaccount.com"
}
```

> 📝 **Contexto: por qué Firestore sí va a nivel proyecto.** Los dos primeros bindings van en el
> recurso concreto, siguiendo la regla de
> [`L02` §5](l02-iam-allow-policies-service-accounts-e-impersonation.md#5--el-experimento-central-el-binding-en-el-recurso-equivocado).
> Los de Firestore van en el proyecto, y no es una inconsistencia: **Firestore no expone allow
> policies por colección ni por documento** —el control fino se hace con Security Rules, que son
> otro sistema y sirven para clientes no confiables—. Cuando el recurso no tiene policy propia, el
> proyecto es el nivel más específico disponible, y eso se dice en vez de fingir que se eligió.

---

## 3. 🧱 Escritura idempotente, y la transacción

Ahora el código. `inv-api` gana dos responsabilidades: registrar el evento y publicarlo.

```python
# app.py — inv-api (fragmento nuevo)

import json, os, uuid
from flask import Flask, request
from google.cloud import firestore, pubsub_v1

app = Flask(__name__)
db = firestore.Client()                      # usa ADC: la SA del servicio, sin ninguna key
publisher = pubsub_v1.PublisherClient()
TOPIC = publisher.topic_path(os.environ["GOOGLE_CLOUD_PROJECT"], "inv-events")

@app.post("/movements")
def movements():
    body = request.get_json(silent=True) or {}
    if "sku" not in body or "delta" not in body:
        return {"error": "sku y delta son obligatorios"}, 400

    # el cliente manda el id; si no, lo generamos. Es la clave de la idempotencia.
    event_id = body.get("event_id") or str(uuid.uuid4())

    doc = db.collection("events").document(event_id)
    # create() falla si el documento ya existe; set() lo pisaría en silencio
    try:
        doc.create({
            "sku": body["sku"],
            "delta": int(body["delta"]),
            "store_id": body.get("store_id", "s1"),
            "created_at": firestore.SERVER_TIMESTAMP,
            "processed": False,
        })
    except Exception as exc:
        if type(exc).__name__ == "AlreadyExists":
            # reintento del cliente: no es un error, es exactamente lo que queríamos
            return {"accepted": True, "event_id": event_id, "duplicate": True}, 202
        raise

    publisher.publish(TOPIC, json.dumps({"event_id": event_id}).encode("utf-8"),
                      event_id=event_id)          # atributo del mensaje, no del cuerpo
    return {"accepted": True, "event_id": event_id}, 202
```

Cuatro decisiones que hay que poder justificar:

- **`firestore.Client()` sin credenciales.** Encuentra la identidad del servicio por la cadena de
  ADC, a través del metadata server. Dentro de Cloud Run no hay ningún archivo de claves, y esa es
  la respuesta correcta a "cómo se autentica tu código en GCP".
- **`document(event_id)` en vez de `add()`.** Al elegir tú el ID, el mismo evento produce **el
  mismo documento** por muchas veces que llegue. `add()` genera un ID nuevo cada vez y convierte
  cada reintento en un registro duplicado.
- **`create()` en vez de `set()`.** `create()` **falla** si el documento existe; `set()` lo
  sobrescribe en silencio. La diferencia es que con `create()` te enteras del duplicado y puedes
  responder 202 sin volver a publicar.
- **`event_id` como atributo del mensaje**, además de en el cuerpo. Los atributos se pueden filtrar
  en la subscription sin deserializar el payload, y aparecen en los logs de entrega.

> 🧠 **Modelo mental.** Pub/Sub garantiza **at-least-once**, no exactly-once: en condiciones
> normales entrega una vez, y ante cualquier duda entrega otra. "Pub/Sub garantiza exactly-once" es
> la sobregeneralización más común sobre este producto; el servicio ofrece un modo de exactly-once
> con condiciones y alcance acotados, y **la respuesta de arquitectura sigue siendo la misma: haz
> el consumidor idempotente**. Lo que hace correcto a un sistema asíncrono no es la promesa del
> broker, es que procesar dos veces dé el mismo resultado que procesar una.

Y el consumidor, donde vive la transacción:

```python
# projector.py — inv-projector

import base64, json, os
from flask import Flask, request
from google.cloud import firestore

app = Flask(__name__)
db = firestore.Client()

@app.post("/events")
def events():
    envelope = request.get_json(silent=True) or {}
    # el mensaje viene envuelto y en base64; el cuerpo del POST no es tu payload
    raw = base64.b64decode(envelope["message"]["data"]).decode("utf-8")
    event_id = json.loads(raw)["event_id"]

    event_ref = db.collection("events").document(event_id)

    @firestore.transactional
    def apply_movement(tx):
        snap = event_ref.get(transaction=tx)
        if not snap.exists:
            return "missing"
        data = snap.to_dict()
        if data.get("processed"):
            return "already"          # idempotencia del lado del consumidor

        if data["delta"] == 0:        # el "veneno" de §8: se rechaza siempre
            raise ValueError("delta 0 no es un movimiento válido")

        stock_ref = db.collection("stock").document(data["sku"])
        stock = stock_ref.get(transaction=tx)
        actual = stock.to_dict()["qty"] if stock.exists else 0

        tx.set(stock_ref, {"sku": data["sku"], "qty": actual + data["delta"]})
        tx.update(event_ref, {"processed": True})
        return "applied"

    try:
        result = apply_movement(db.transaction())
    except ValueError as exc:
        print(json.dumps({"severity": "ERROR", "message": str(exc), "event_id": event_id}))
        return {"error": str(exc)}, 400      # 4xx: no reintentar, mándalo al DLQ

    return {"result": result}, 200           # 2xx: ack
```

- **El envoltorio del push.** Pub/Sub no manda tu JSON tal cual: manda un sobre
  `{"message": {"data": "<base64>", "attributes": {...}, "messageId": "..."}, "subscription": "..."}`.
  Decodificar `data` desde base64 es obligatorio, y olvidarlo es el primer error de todo el mundo.
- **`@firestore.transactional`** hace que la lectura del stock y las dos escrituras sean atómicas:
  si otro proceso toca el mismo documento en medio, la transacción se reintenta sola. Sin ella, dos
  entregas simultáneas del mismo evento —o de dos eventos sobre el mismo SKU— se pisan y el stock
  queda mal.
- **`processed`** es la idempotencia del consumidor, y es la que de verdad protege: aunque el mismo
  evento llegue cinco veces, el stock se mueve una.
- **El código de respuesta es el protocolo entero**: un **2xx es un ack** —no me lo mandes más—; un
  **4xx o 5xx cuenta como entrega fallida** y dispara el reintento. Devolver 200 cuando algo falló
  hace desaparecer el mensaje para siempre, y es el bug más silencioso de esta arquitectura.

Despliega los dos servicios como en [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md), con imagen preconstruida y su service account:

```bash
gcloud run deploy inv-projector \
  --image us-central1-docker.pkg.dev/inv-lab-472913/inv-lab/inv-projector:v1 \
  --region us-central1 \
  --service-account inv-projector-sa@inv-lab-472913.iam.gserviceaccount.com \
  --no-allow-unauthenticated \
  --max-instances 3 \
  --labels project=inv_lab
```

Toma su URL y pásasela a Terraform, que es la dependencia que anunciaba §2:

```bash
PROJECTOR_URL=$(gcloud run services describe inv-projector --region us-central1 \
  --format='value(status.url)')
terraform apply -var="projector_url=$PROJECTOR_URL"
```

---

## 4. 🩺 El índice que el emulador no te exige

El experimento más didáctico sobre "qué te miente un emulador". Añade a `inv-api` una consulta
perfectamente razonable: los últimos movimientos de una tienda.

```python
@app.get("/movements/<store_id>")
def by_store(store_id):
    q = (db.collection("events")
           .where("store_id", "==", store_id)
           .order_by("created_at", direction=firestore.Query.DESCENDING)
           .limit(20))
    return {"items": [d.id for d in q.stream()]}
```

Contra el emulador local funciona a la primera. Contra el servicio:

```text
google.api_core.exceptions.FailedPrecondition: 400 The query requires an index.
You can create it here: https://console.firebase.google.com/project/inv-lab-472913/firestore/indexes?create_composite=…
```

**Por qué.** Firestore indexa automáticamente **cada campo por separado**. Una consulta que combina
un filtro de igualdad sobre un campo con un **ordenamiento por otro** necesita un **índice
compuesto**, y hay que declararlo. El emulador no lo exige; el servicio sí.

El enlace del error crea el índice por ti, y está bien para desbloquear hoy. La solución que uno
hace con calma es declararlo donde vive el resto de la infraestructura:

```hcl
# firestore-indexes.tf

resource "google_firestore_index" "events_by_store_and_time" {
  project    = "inv-lab-472913"
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

- **El orden de los bloques `fields` importa** y debe coincidir con el de la consulta: primero el
  campo de igualdad, después el de ordenamiento. Un índice `(created_at, store_id)` **no** sirve
  para esta consulta.
- **La creación tarda** —es una operación de larga duración— y mientras tanto la consulta sigue
  fallando exactamente igual. No es que el índice no funcione: es que todavía no está.

```bash
terraform apply -var="projector_url=$PROJECTOR_URL"
gcloud firestore indexes composite list --format='table(name, queryScope, fields)'
```

> 🧠 **Modelo mental.** El índice compuesto no es una optimización opcional: **es un requisito de
> la consulta**. Firestore no hace escaneos completos, así que una consulta sin índice no es lenta:
> no existe. Esa es la diferencia de fondo con una base relacional, y es la respuesta a "¿por qué
> mi consulta funciona en local y falla en producción?".

---

## 5. 🧱 La push subscription con token OIDC

La pieza más específica de GCP de toda la serie. Qué ocurre exactamente cuando llega un mensaje:

```text
1. Pub/Sub toma la identidad de push_config.oidc_token.service_account_email   (inv-pubsub-sa)
2. Pide un ID token firmado en nombre de esa identidad
3. POSTea el sobre a push_endpoint con  Authorization: Bearer <ID token>
4. Cloud Run valida el token y comprueba roles/run.invoker para ESA identidad
5. Tu handler responde 2xx (ack) o cualquier otra cosa (reintento)
```

Cinco pasos, cinco sitios donde se puede romper. Comprueba primero la configuración:

```bash
gcloud pubsub subscriptions describe inv-events-push \
  --format='value(pushConfig.pushEndpoint, pushConfig.oidcToken.serviceAccountEmail, ackDeadlineSeconds)'
```

```text
https://inv-projector-384756192043.us-central1.run.app/events	inv-pubsub-sa@inv-lab-472913.iam.gserviceaccount.com	30
```

Y ahora el camino completo, de extremo a extremo:

```bash
URL=$(gcloud run services describe inv-api --region us-central1 --format='value(status.url)')
curl -s -X POST "$URL/movements" \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H 'Content-Type: application/json' \
  -d '{"event_id":"ev-001","sku":"ABC-1","delta":-3,"store_id":"s1"}'
```

```text
{"accepted":true,"event_id":"ev-001"}
```

```bash
gcloud firestore documents describe --database='(default)' \
  --collection-ids=stock 2>/dev/null || \
gcloud run services logs read inv-projector --region us-central1 --limit=10
```

Repite el mismo `curl` **con el mismo `event_id`**: la respuesta trae `"duplicate": true`, y el
stock **no se mueve**. Esa es la idempotencia funcionando, y es exactamente la demostración que
pide una entrevista.

---

## 6. 🩺 Provocar el 403 de la entrega push

El error más instructivo del lab, y hay que provocarlo. Quita el binding que permite a Pub/Sub
invocar al proyector:

```bash
gcloud run services remove-iam-policy-binding inv-projector \
  --region us-central1 \
  --member="serviceAccount:inv-pubsub-sa@inv-lab-472913.iam.gserviceaccount.com" \
  --role=roles/run.invoker
```

Publica otro movimiento y observa el silencio: **el `curl` a `inv-api` devuelve 202 tan feliz**. No
falla nada visible. El evento está en Firestore, el mensaje está publicado, y el stock no se
actualiza nunca.

> 🩺 **Diagnóstico.** Ese silencio es la característica más incómoda de las arquitecturas
> asíncronas: **el productor no se entera de que el consumidor no recibe**. Por eso el diagnóstico
> no empieza en el `curl`, empieza en las métricas de la subscription y en los logs del destino.

```bash
# ¿hay mensajes sin confirmar acumulándose?
gcloud pubsub subscriptions describe inv-events-push --format='value(name)'

# el 403 real, en los logs del servicio de destino
gcloud logging read \
  'resource.type="cloud_run_revision" AND resource.labels.service_name="inv-projector" AND httpRequest.status=403' \
  --limit=5 --freshness=30m \
  --format='table(timestamp, httpRequest.status, protoPayload.authenticationInfo.principalEmail)'
```

- `logging read` usa el mismo lenguaje de consulta que la consola de Cloud Logging.
- `--freshness=30m` acota la ventana temporal; sin él la consulta barre demasiado atrás.
- El `principalEmail` de la entrada te dice **con qué identidad llegó la llamada**, que es
  justamente lo que hay que comparar con el binding.

La corrección, en el recurso correcto:

```bash
gcloud run services add-iam-policy-binding inv-projector \
  --region us-central1 \
  --member="serviceAccount:inv-pubsub-sa@inv-lab-472913.iam.gserviceaccount.com" \
  --role=roles/run.invoker
```

Y en cuanto se aplica, **los mensajes acumulados se entregan solos**: Pub/Sub llevaba reintentando
todo este tiempo con el backoff de la `retry_policy`. Eso también es una lección: el reintento no
es un plan B, es el comportamiento normal.

> ⚠️ **La causa que no es IAM y parece IAM.** Si el `pushEndpoint` apunta a la ruta equivocada
> —`/` en vez de `/events`— la entrega devuelve un 404, y en las métricas de la subscription se ve
> exactamente igual de muda que un 403. Antes de revisar bindings, comprueba la URL completa.

---

## 7. 🧱 Reintentos, ack deadline y at-least-once

Los tres parámetros que gobiernan cuántas veces te llega un mensaje.

| Parámetro | Qué controla | Qué pasa si se queda corto |
|---|---|---|
| `ack_deadline_seconds` | Cuánto tiene tu endpoint para responder 2xx | Pub/Sub da la entrega por fallida y reintenta: duplicados que no son de red |
| `retry_policy` | El backoff entre reintentos | Sin política, reintenta de inmediato y martillea un endpoint caído |
| `max_delivery_attempts` | Cuántas veces antes del DLQ | Muy alto: el veneno se reintenta días. Muy bajo: mensajes buenos al DLQ por un fallo transitorio |

La relación entre el primero y tu código es la que hay que interiorizar:

> 🧭 **Regla de arquitectura.** El `ack_deadline` tiene que ser **mayor que el peor tiempo de
> proceso de tu handler**, y el `--timeout` del servicio de Cloud Run tiene que ser coherente con
> los dos. Tres relojes distintos —`gunicorn`, Cloud Run y Pub/Sub— midiendo la misma petición: si
> no se ordenan a propósito, producen cortes que parecen aleatorios.

Y el ordenamiento, que conviene mencionar aunque este lab no lo use: una **ordering key** garantiza
que los mensajes con la misma clave se entreguen **en orden**, a costa de serializarlos. Para un
inventario por SKU sería la elección natural si el orden importara; aquí no importa, porque los
movimientos son incrementos y la suma es conmutativa. **Decidir que no hace falta también es una
decisión de diseño**, y saber decir por qué es lo que se pregunta.

---

## 8. 🩺 El mensaje envenenado y el dead-letter

Ahora el mensaje que **nunca** va a poder procesarse. El código de `inv-projector` rechaza un
`delta` de 0 con un `ValueError` y devuelve 400:

```bash
curl -s -X POST "$URL/movements" \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H 'Content-Type: application/json' \
  -d '{"event_id":"ev-veneno","sku":"ABC-1","delta":0,"store_id":"s1"}'
```

El 400 del proyector cuenta como entrega fallida. Pub/Sub reintenta con el backoff configurado y,
tras cinco intentos, lo manda al DLQ. Compruébalo:

```bash
gcloud pubsub subscriptions create inv-events-dlq-pull --topic=inv-events-dlq
gcloud pubsub subscriptions pull inv-events-dlq-pull --auto-ack --limit=5 \
  --format='table(message.data.decode(base64).decode(utf-8), message.attributes)'
```

```text
DATA                              ATTRIBUTES
{"event_id": "ev-veneno"}         {'CloudPubSubDeadLetterSourceDeliveryCount': '5', …}
```

- **La subscription de pull existe solo para mirar el DLQ.** Un topic sin subscription **descarta**
  los mensajes: si el DLQ no tiene consumidor, el veneno se pierde y el ejercicio no demuestra
  nada. Es un detalle que se olvida constantemente.
- **`--auto-ack`** confirma los mensajes al leerlos: para inspeccionar está bien, para un consumidor
  real no.
- **Los atributos que añade Pub/Sub** —cuántas entregas se intentaron y de qué subscription venía—
  son el material con el que se investiga un veneno en producción.

**Y ahora el permiso que todo el mundo olvida.** Si el DLQ estuviera vacío después de todo esto, la
causa es casi siempre esta:

```bash
PROJECT_NUMBER=$(gcloud projects describe inv-lab-472913 --format='value(projectNumber)')
PUBSUB_AGENT="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com"

gcloud pubsub topics add-iam-policy-binding inv-events-dlq \
  --member="$PUBSUB_AGENT" --role=roles/pubsub.publisher

gcloud pubsub subscriptions add-iam-policy-binding inv-events-push \
  --member="$PUBSUB_AGENT" --role=roles/pubsub.subscriber
```

- El **service agent de Pub/Sub** es una service account que **Google crea y administra** para que
  el servicio actúe en tu proyecto. Lleva el `projectNumber` en su dirección — ese número que
  anotaste en [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) y que parecía inútil.
- El primer binding le permite **escribir** el mensaje en el DLQ. El segundo le permite
  **confirmar** el original en la subscription de origen. **Sin el segundo, el mensaje se reenvía al
  DLQ y además se sigue reintentando**: un bucle que se nota primero en la factura de logs.

> 📝 **Contexto.** Que Google cree la cuenta pero no le conceda los permisos parece un descuido y es
> deliberado: hacerlo automáticamente significaría que habilitar una API te modifica la allow policy
> del proyecto sin que lo pidas. El precio de esa coherencia es este error, y por eso está en
> [`A03` §5](a03-catalogo-de-errores-y-diagnostico.md#5--el-service-agent-que-no-existía-todavía).

---

## 9. 🧱 Eventarc, y el service agent que nadie recuerda

Última pieza, y la más barata: reaccionar a un objeto nuevo en el bucket de datos que [`L03`](l03-terraform-desde-la-cli.md) creó.

```hcl
# eventarc.tf

resource "google_eventarc_trigger" "on_object" {
  name     = "inv-lab-on-object"
  location = "us-central1"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = "inv-lab-data-472913"
  }

  destination {
    cloud_run_service {
      service = "inv-projector"
      region  = "us-central1"
      path    = "/objects"
    }
  }

  service_account = "inv-pubsub-sa@inv-lab-472913.iam.gserviceaccount.com"
  labels          = { project = "inv_lab" }
}
```

- **`type = "…object.v1.finalized"`** es el evento "se terminó de escribir un objeto", que cubre
  tanto la creación como la sobrescritura. El catálogo de tipos es cerrado: inventarse uno produce
  un error de validación en el `apply`.
- **`service_account`** es la identidad con la que Eventarc invoca el destino. Es el mismo mecanismo
  OIDC de §5, con otro nombre: por eso reutiliza `inv-pubsub-sa`, que ya tiene `run.invoker`.
- **`path`** es la ruta dentro del servicio. Sin ella, el evento llega a `/` y tu handler de
  eventos no se entera.

> ⚠️ **Eventarc crea infraestructura que tú no pediste.** Por debajo, un trigger de Cloud Storage
> monta **un topic de Pub/Sub y una subscription** en tu proyecto, y usa **dos** service agents: el
> de Eventarc y el de Cloud Storage. El segundo necesita `roles/pubsub.publisher` en el proyecto
> para poder publicar las notificaciones del bucket, y es un binding que Google **no** concede solo:

```bash
GCS_AGENT=$(gcloud storage service-agent --project=inv-lab-472913)
gcloud projects add-iam-policy-binding inv-lab-472913 \
  --member="serviceAccount:${GCS_AGENT}" \
  --role=roles/pubsub.publisher
```

- `gcloud storage service-agent` devuelve la dirección del service agent de Cloud Storage de este
  proyecto. Es más fiable que componerla a mano.

Prueba el trigger:

```bash
terraform apply -var="projector_url=$PROJECTOR_URL"
echo '{"sku":"ABC-1","qty":10}' > /tmp/carga.json
gcloud storage cp /tmp/carga.json gs://inv-lab-data-472913/carga.json
gcloud run services logs read inv-projector --region us-central1 --limit=10
```

> 🧠 **Modelo mental.** Un trigger de Eventarc **no es magia**: es un topic, una subscription push
> y un par de bindings, con una capa de conveniencia encima. Saber eso es lo que te permite
> depurarlo — cuando un trigger "no dispara", el diagnóstico es el mismo de §6, aplicado a recursos
> que no creaste tú. Y es también por qué esos recursos aparecen en el inventario de [`L08`](l08-costos-y-destruccion-verificada.md) sin que
> los hayas escrito en ningún HCL.

---

## 10. ⚖ Qué te mintió el emulador

La lista que se saca de este lab, y que es material de entrevista de primera calidad porque
demuestra que entiendes el servicio y no solo su API:

| Lo que el emulador te dejó hacer | Lo que el servicio real exige |
|---|---|
| Consultar sin índice compuesto | `FAILED_PRECONDITION` hasta que lo declares (§4) |
| Push sin autenticación | Token OIDC firmado, validado, y `run.invoker` en el destino (§5) |
| Entregas siempre exitosas | Reintentos con backoff, ack deadline y DLQ (§7, §8) |
| Sin IAM | Un binding en el sitio equivocado y no llega nada (§6) |
| Sin service agents | Dos cuentas que aparecen solas y necesitan permisos que nadie concede (§8, §9) |
| Sin cuotas | 20.000 escrituras al día en el Always Free de Firestore |

> 💡 **Truco.** Corre la misma suite de pruebas contra el emulador y contra GCP real, y anota cada
> diferencia. Esa lista —"qué me mintió el emulador"— es una respuesta excelente cuando te
> pregunten cómo pruebas una integración con servicios administrados.

---

## 11. 🧹 Teardown de este lab

| Recurso | ¿Cobra? | Qué hacer |
|---|---|---|
| `inv-api`, `inv-projector` con escalado a cero | $0.00 sin tráfico | Se quedan: [`L07`](l07-observabilidad-logs-metricas-y-auditoria.md) los observa |
| Topic `inv-events` y DLQ `inv-events-dlq` | Solo por volumen | Se quedan; los administra Terraform |
| Subscription `inv-events-push` | No | Se queda |
| Subscription `inv-events-dlq-pull` | No | **Créala a mano, bórrala a mano** — Terraform no la ve |
| Índice compuesto de Firestore | No | Se queda; lo administra Terraform |
| Trigger de Eventarc | No | Se queda; **el topic y la subscription que crea por debajo, tampoco los administra Terraform** |
| Documentos en `events` y `stock` | Dentro de 1 GiB | Se van al borrar la base, en [`L08`](l08-costos-y-destruccion-verificada.md) |

Borra ya lo que creaste a mano:

```bash
gcloud pubsub subscriptions delete inv-events-dlq-pull --quiet
```

Y ahora la comprobación que hace útil este lab de cara a [`L08`](l08-costos-y-destruccion-verificada.md):

```bash
# lo que Terraform cree administrar
terraform state list | wc -l

# lo que existe de verdad
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --filter='assetType:pubsub.googleapis.com' \
  --format='table(assetType, name)'
```

**Los dos números no coinciden**, y esa es la lección: en la lista de Pub/Sub aparecen un topic y
una subscription con nombres que no escribiste nunca. Los creó Eventarc en tu nombre.

> 🧠 **Modelo mental.** `terraform destroy` va a borrar el trigger, y con él debería irse lo que
> creó por debajo. **"Debería" no es "va a"**: comprobarlo es exactamente el ejercicio de
> [`L08`](l08-costos-y-destruccion-verificada.md), y por eso ese lab existe en vez de terminar la
> serie aquí.

---

## 📋 Checklist de salida

- [ ] El mismo `event_id` enviado dos veces devuelve `duplicate: true` y **el stock no se mueve**.
- [ ] Provocaste el `FAILED_PRECONDITION` de Firestore y declaraste el índice en Terraform, no desde el enlace del error.
- [ ] Quitaste el binding de `run.invoker` y comprobaste que **el productor sigue devolviendo 202** mientras nada llega.
- [ ] Encontraste el 403 en los logs de `inv-projector` y viste con qué `principalEmail` llegaba.
- [ ] Al restaurar el binding, los mensajes acumulados se entregaron solos.
- [ ] El mensaje envenenado está en el DLQ, y lo leíste con una subscription de pull.
- [ ] Sabes qué dos bindings necesita el service agent de Pub/Sub y qué pasa si falta el segundo.
- [ ] El trigger de Eventarc dispara al subir un objeto al bucket.
- [ ] Concediste `pubsub.publisher` al service agent de Cloud Storage y sabes por qué hacía falta.
- [ ] Comparaste `terraform state list` con el inventario real y encontraste los recursos que Eventarc creó solo.
- [ ] Borraste la subscription `inv-events-dlq-pull`, que creaste a mano.

## 🏁 La señal de que quedó bien

Un `curl` con el mismo `event_id` repetido deja **una** entrada en `events` y **un** movimiento en
`stock`; el veneno está en el DLQ con su contador de entregas; los dos servicios están a cero
instancias; y puedes señalar en el inventario del proyecto los recursos que no escribiste tú y decir
quién los creó.

---

## 🧠 Preguntas rápidas

1. ¿Por qué elegir tú el ID del documento en vez de usar `add()` es la base de la idempotencia?
2. ¿Qué diferencia hay entre `create()` y `set()` en Firestore, y por qué importa aquí?
3. ¿Pub/Sub garantiza exactly-once? ¿Cuál es la respuesta de arquitectura correcta, independientemente de eso?
4. ¿Qué protege exactamente la transacción de `inv-projector`, y qué pasaría sin ella?
5. ¿Qué significa un 2xx en el handler de una push subscription, y qué provoca devolver 200 cuando algo falló?
6. ¿Por qué el cuerpo del POST que recibe tu endpoint no es tu payload?
7. ¿Por qué una consulta que funciona contra el emulador falla contra Firestore real?
8. ¿Importa el orden de los campos en un índice compuesto? ¿Por qué?
9. Enumera los cinco pasos de una entrega push con OIDC y qué puede fallar en cada uno.
10. Quitas `run.invoker` del proyector. ¿Qué devuelve el productor y cómo te enteras de que algo va mal?
11. ¿Qué relación tiene que haber entre el `ack_deadline` y el tiempo de proceso de tu handler?
12. ¿Por qué un DLQ sin subscription no demuestra nada?
13. ¿Qué dos bindings necesita el service agent de Pub/Sub para el dead-letter, y qué ocurre si falta el de `subscriber`?
14. ¿Por qué el binding de Firestore va a nivel proyecto cuando la regla del curso dice "en el recurso más específico"?
15. ¿Qué infraestructura crea un trigger de Eventarc que tú no escribiste, y por qué importa para el teardown?
16. ¿Por qué el lab no usa ordering keys, y por qué esa decisión también hay que saber defenderla?

---

## 📚 Referencias oficiales

- Documentación de Firestore: https://cloud.google.com/firestore/docs
- Transacciones y escrituras por lotes: https://cloud.google.com/firestore/docs/manage-data/transactions
- Agregar y administrar datos: https://cloud.google.com/firestore/docs/manage-data/add-data
- Tipos de índice en Firestore: https://cloud.google.com/firestore/docs/concepts/index-overview
- Administrar índices: https://cloud.google.com/firestore/docs/query-data/indexing
- Cuotas y límites de Firestore: https://cloud.google.com/firestore/quotas
- Documentación de Pub/Sub: https://cloud.google.com/pubsub/docs
- Suscripciones push: https://cloud.google.com/pubsub/docs/push
- Autenticación de suscripciones push: https://cloud.google.com/pubsub/docs/authenticate-push-subscriptions
- Gestión de fallos y dead-letter topics: https://cloud.google.com/pubsub/docs/handling-failures
- Entrega exactly-once: https://cloud.google.com/pubsub/docs/exactly-once-delivery
- Ordenar mensajes con ordering keys: https://cloud.google.com/pubsub/docs/ordering
- Control de acceso en Pub/Sub: https://cloud.google.com/pubsub/docs/access-control
- Documentación de Eventarc: https://cloud.google.com/eventarc/docs
- Crear un trigger para Cloud Storage: https://cloud.google.com/eventarc/docs/run/create-trigger-storage-gcloud
- Roles y permisos de Eventarc: https://cloud.google.com/eventarc/docs/access-control
- Service agents de Google Cloud: https://cloud.google.com/iam/docs/service-agents
- Notificaciones de Pub/Sub para Cloud Storage: https://cloud.google.com/storage/docs/pubsub-notifications
- Cloud Logging: lenguaje de consultas: https://cloud.google.com/logging/docs/view/logging-query-language
- `google_pubsub_subscription`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription
- `google_firestore_index`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_index
- `google_eventarc_trigger`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/eventarc_trigger
