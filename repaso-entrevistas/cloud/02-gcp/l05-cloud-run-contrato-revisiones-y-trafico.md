# L05 — Cloud Run: contrato, revisiones y tráfico

> **Objetivo:** desplegar `inv-api` con identidad propia y cerrado a invocación anónima, y
> entender el **contrato de plataforma** de Cloud Run: `PORT`, concurrencia, escalado a cero,
> timeouts, revisiones, reparto de tráfico y de dónde salen los secretos. Es la costura entre tu
> código y GCP, y es lo único de todo esto que un `docker run` local no te enseña.
> **Se asume leído:** [`L03`](l03-terraform-desde-la-cli.md) —la infraestructura se crea con
> Terraform— y [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md). Rinde mucho
> más con [`02`](02-computo-contenedores-y-balanceo.md) leído.
> **Costo:** **centavos.** El tráfico del lab cabe de sobra en la cuota Always Free de Cloud Run
> (2 M requests, 360.000 GiB-s, 180.000 vCPU-s al mes). El único cargo real es **Artifact
> Registry** por encima de 0,5 GB, y por eso §3 elige una imagen pequeña.
> **Duración:** 3 horas.
> **Prerrequisitos:** `L01`–`L03` completos. **Docker instalado en tu máquina** y Python 3 para
> probar en local.
> **Qué queda encendido al terminar:** el repositorio de Artifact Registry, el secreto de Secret
> Manager y el servicio `inv-api` con `min-instances = 0`. Con escalado a cero y sin tráfico,
> `inv-api` cuesta $0.00.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [El contrato](#1--el-contrato-de-plataforma) ·
[Artifact Registry](#2--artifact-registry-el-único-cargo-del-tronco) ·
[El servicio en Python](#3--el-servicio-en-python-y-su-imagen) ·
[Romper `PORT` a propósito](#4--romper-el-contrato-a-propósito-port) ·
[La identidad del servicio](#5--la-identidad-del-servicio-y-el-default-peligroso) ·
[Invocación autenticada](#6--invocación-autenticada-los-dos-tokens) ·
[Concurrencia y escalado](#7--concurrencia-escalado-a-cero-y-timeouts) ·
[`min-instances`](#8--min-instances-el-flag-que-rompe-el-cero) ·
[Revisiones y canary](#9--revisiones-y-reparto-de-tráfico) ·
[Secretos](#10--un-secreto-desde-secret-manager) ·
[Teardown](#11--teardown-de-este-lab) ·
[Checklist](#-checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 El contrato de plataforma

Cloud Run no ejecuta "tu aplicación". Ejecuta **tu contenedor**, y le pide cuatro cosas. Todo lo
demás —qué lenguaje, qué framework, qué librerías— le da exactamente igual.

```text
1. Escucha en el puerto que te doy en la variable PORT, y en 0.0.0.0
2. Arranca dentro del timeout de inicio
3. Responde por HTTP; yo decido cuántas peticiones te mando a la vez
4. Cuando no haya tráfico, te apago. Y no te aviso.
```

Ese contrato es la materia de este lab, porque es **lo único que un `docker run` en tu portátil no
puede enseñarte**. La imagen es idéntica en los dos sitios; lo que cambia es quién la arranca, con
qué identidad, con qué variables y cuándo la mata.

> 🧠 **Modelo mental.** Un contenedor en tu máquina es un proceso que tú lanzas. Un contenedor en
> Cloud Run es un proceso que **la plataforma** lanza, escala y apaga según su criterio, con una
> identidad que no es la tuya. Todo lo que sale mal en este lab sale de no haber interiorizado esa
> frase.

Y la cuarta cláusula tiene una consecuencia que decide diseños enteros: **entre peticiones, tu
instancia puede no existir**. Nada de estado en memoria, nada de tareas en segundo plano después
de responder, nada de escribir en el disco local esperando encontrarlo luego.

---

## 2. 💰 Artifact Registry: el único cargo del tronco

Antes del código, el sitio donde va a vivir la imagen. Se crea con Terraform, como toda la
infraestructura de la serie:

```hcl
# registry.tf

resource "google_artifact_registry_repository" "images" {
  location      = "us-central1"
  repository_id = "inv-lab"
  format        = "DOCKER"
  description   = "Imágenes de los servicios del laboratorio"

  labels = {
    project = "inv_lab"
  }
}
```

- **`format = "DOCKER"`** es inmutable: un repositorio sirve para un tipo de artefacto. Cambiarlo
  obliga a recrear, y ya sabes cómo se ve eso en un plan.
- **`location`** es regional y debe coincidir con la región de Cloud Run, porque de ahí sale el
  nombre del host de la imagen.
- **Este repositorio no lleva política de limpieza a propósito.** Es lo que hace visible el
  problema en §11.

```bash
terraform apply
gcloud auth configure-docker us-central1-docker.pkg.dev
```

- `gcloud auth configure-docker` escribe en tu `~/.docker/config.json` un *credential helper* que
  hace que `docker push` use tu credencial de `gcloud`. **Sin esto, el push falla con un 401 que no
  menciona GCP por ningún lado.** El argumento es el host regional del registry; sin él, `gcloud`
  configura solo los hosts antiguos de Container Registry.

> 💰 **Costo.** La cuota Always Free de Artifact Registry es de **0,5 GB de almacenamiento**, y
> **cada despliegue deja una imagen más**. Cinco despliegues de una imagen de 200 MB ya se pasan.
> No es dinero serio —son centavos— pero es la demostración perfecta de un costo que nadie decidió:
> se acumula solo. Por eso §3 usa una imagen `slim` y §11 lo limpia.

---

## 3. 🧱 El servicio en Python y su imagen

`inv-api` recibe movimientos de inventario. En este lab solo los valida y los devuelve; en
[`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) empezará a escribir en Firestore y a
publicar en Pub/Sub.

```python
# app.py — inv-api

import json
import os
from flask import Flask, request

app = Flask(__name__)

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

@app.post("/movements")
def movements():
    body = request.get_json(silent=True) or {}
    if "sku" not in body or "delta" not in body:
        return {"error": "sku y delta son obligatorios"}, 400

    # log estructurado: Cloud Logging parsea el JSON y lo indexa por campo
    print(json.dumps({
        "severity": "INFO",
        "message": "movement accepted",
        "sku": body["sku"],
        "delta": body["delta"],
    }))
    return {"accepted": True, "sku": body["sku"]}, 202

if __name__ == "__main__":
    # PORT lo inyecta Cloud Run; el 8080 es solo el default para correr en local
    port = int(os.environ.get("PORT", 8080))
    # 0.0.0.0, nunca 127.0.0.1: desde fuera del contenedor, localhost es no escuchar
    app.run(host="0.0.0.0", port=port)
```

Las dos últimas líneas son el contrato entero, y las dos son la causa del error de §4.

Ese `print` con un JSON no es un capricho de estilo: **Cloud Logging reconoce un JSON en stdout y
lo convierte en una entrada estructurada**, con `severity` reconocido y cada campo consultable por
separado. Es la diferencia entre buscar por texto y filtrar por `jsonPayload.sku`. Se explota a
fondo en [`L07`](l07-observabilidad-logs-metricas-y-auditoria.md).

```text
# requirements.txt
Flask==3.0.3
gunicorn==22.0.0
```

Versiones **exactas**, por la misma razón que el provider de Terraform va pinneado: un rango
convierte "funciona en mi máquina" en una lotería.

```dockerfile
# Dockerfile
FROM python:3.12-slim

WORKDIR /app

# las dependencias primero: esta capa se cachea y no se reconstruye si solo cambia el código
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# gunicorn en vez del servidor de desarrollo de Flask, y leyendo $PORT del entorno
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 app:app
```

- **`python:3.12-slim`** en vez de la imagen completa: la diferencia son cientos de megas, y ahí se
  va directamente tu cuota de Artifact Registry.
- **`COPY requirements.txt` antes que `COPY app.py`** aprovecha el caché de capas: cambiar el código
  no reinstala las dependencias.
- **`exec`** hace que `gunicorn` sea el PID 1 del contenedor y reciba las señales de la plataforma.
  Sin `exec`, la shell se queda de PID 1 y **`SIGTERM` no llega a tu proceso**: Cloud Run mata la
  instancia a la fuerza al escalar a cero, sin apagado ordenado.
- **`--workers 1 --threads 8`** es la configuración razonable para Cloud Run: la plataforma escala
  **añadiendo instancias**, no procesos dentro de una instancia. Poner ocho workers en un contenedor
  de 1 vCPU multiplica la memoria sin añadir throughput.
- **`--timeout 0`** desactiva el timeout de `gunicorn`, porque el timeout que manda es el del
  servicio de Cloud Run (§7). Dos timeouts compitiendo producen cortes que parecen aleatorios.
- **`$PORT` se expande en tiempo de ejecución**, no de build, porque `CMD` está en forma de shell.
  Ese detalle es justo lo que hace que el contrato se cumpla.

Prueba en local primero, que es gratis y tarda segundos:

```bash
docker build -t inv-api:local .
docker run --rm -e PORT=8080 -p 8080:8080 inv-api:local
curl -s -X POST localhost:8080/movements -H 'Content-Type: application/json' \
  -d '{"sku":"ABC-1","delta":-3}'
```

```text
{"accepted":true,"sku":"ABC-1"}
```

Y ahora a Artifact Registry:

```bash
IMAGE=us-central1-docker.pkg.dev/inv-lab-472913/inv-lab/inv-api:v1
docker build -t "$IMAGE" .
docker push "$IMAGE"
```

- El nombre completo de la imagen tiene cuatro partes:
  `<región>-docker.pkg.dev/<projectId>/<repositorio>/<imagen>:<tag>`. Equivocarse en cualquiera de
  ellas produce un 404 o un 403 al hacer push.
- **El tag es `v1`, no `latest`.** `latest` no es una versión: es un nombre que apunta a otra cosa
  cada vez, y hace imposible saber qué está corriendo de verdad. En este curso las imágenes se
  etiquetan con versión explícita, siempre.

> 💡 **Truco.** `gcloud run deploy --source .` construye y sube por ti sin que tengas Docker
> instalado, usando Cloud Build. Es cómodo y esconde exactamente lo que este lab quiere enseñar:
> de dónde sale la imagen, cuánto pesa y quién paga por guardarla. Cuando ya lo sepas, úsalo sin
> culpa.

---

## 4. 🩺 Romper el contrato a propósito: `PORT`

Antes de desplegar la versión buena, la versión rota. Cambia el `CMD` del Dockerfile por un puerto
fijo, que es el error que comete todo el mundo la primera vez:

```dockerfile
CMD exec gunicorn --bind :5000 --workers 1 --threads 8 --timeout 0 app:app
```

```bash
docker build -t "${IMAGE%v1}v0-roto" .
docker push "${IMAGE%v1}v0-roto"

gcloud run deploy inv-api \
  --image "${IMAGE%v1}v0-roto" \
  --region us-central1 \
  --service-account inv-api-sa@inv-lab-472913.iam.gserviceaccount.com \
  --no-allow-unauthenticated
```

```text
Deploying container to Cloud Run service [inv-api] in project [inv-lab-472913] region [us-central1]
X Deploying new service... Cloud Run error: The user-provided container failed to start and
  listen on the port defined provided by the PORT=8080 environment variable within the allocated
  timeout. This can happen when the container port is misconfigured.
ERROR: (gcloud.run.deploy) Revision 'inv-api-00001-abc' is not ready and cannot serve traffic.
```

**Confirma la causa antes de arreglar**, que es el método de toda la serie:

```bash
gcloud run services logs read inv-api --region us-central1 --limit=20
```

```text
[2026-09-06 18:22:41 +0000] [1] [INFO] Starting gunicorn 22.0.0
[2026-09-06 18:22:41 +0000] [1] [INFO] Listening at: http://0.0.0.0:5000 (1)
```

Ahí está: el proceso arrancó perfectamente y escucha en el 5000. No hay stack trace, no hay crash.
**La aplicación funciona; lo que no cumple es el contrato.**

> 🩺 **Diagnóstico.** "Failed to start and listen on PORT" tiene tres causas y se distinguen en los
> logs de la revisión: si ves el arranque anunciando **otro puerto**, es que no lees `PORT`; si no
> ves nada más que el arranque y el proceso escucha en `127.0.0.1`, desde fuera es no escuchar; si
> ves un **stack trace**, el problema no es el puerto, es que revienta antes de llegar a escuchar.
> El catálogo está en
> [`A03` §6](a03-catalogo-de-errores-y-diagnostico.md#6--cloud-run-el-contenedor-no-escuchó-en-port).

Restaura el `CMD` con `$PORT`, reconstruye, y despliega la buena:

```bash
gcloud run deploy inv-api \
  --image "$IMAGE" \
  --region us-central1 \
  --service-account inv-api-sa@inv-lab-472913.iam.gserviceaccount.com \
  --no-allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --concurrency 80 \
  --timeout 60s \
  --min-instances 0 \
  --max-instances 3 \
  --labels project=inv_lab
```

Los flags se desglosan en §5, §7 y §8. La revisión rota no desaparece sola: sigue en el historial
del servicio y su imagen sigue en Artifact Registry, que es el punto de §11.

---

## 5. 🧱 La identidad del servicio, y el default peligroso

De todos los flags del despliegue, este es el que más importa:

```text
--service-account inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
```

**Fija la identidad con la que corre el servicio.** Todo lo que tu código haga contra las APIs de
Google lo hará como esa cuenta.

> ⚠️ **Si omites el flag, Cloud Run usa la service account por defecto de Compute Engine**, que en
> muchos proyectos trae el rol **`roles/editor` sobre todo el proyecto**. Es decir: tu servicio de
> juguete corriendo como administrador, con permiso para borrar la base de datos de al lado. Ese
> default es la causa número uno de labs que "funcionan" mientras enseñan exactamente lo contrario
> del privilegio mínimo.

Compruébalo con tus propios ojos:

```bash
gcloud run services describe inv-api --region us-central1 \
  --format='value(spec.template.spec.serviceAccountName)'
```

```text
inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
```

Y mira qué tiene concedido esa cuenta ahora mismo:

```bash
gcloud projects get-iam-policy inv-lab-472913 \
  --flatten='bindings[].members[]' \
  --filter='bindings.members:inv-api-sa' \
  --format='value(bindings.role)'
```

```text
Listed 0 items.
```

**Nada, y el servicio funciona igual**, porque todavía no llama a ninguna API. Ese es el estado
correcto: los permisos se conceden cuando hacen falta y sobre el recurso concreto, que es lo que
hará [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) con Firestore y Pub/Sub.

**De dónde saca credenciales tu código, sin que escribas una sola línea.** Dentro de Cloud Run no
hay ningún archivo de claves: la plataforma entrega tokens de la service account del servicio a
través del **metadata server**, y las librerías `google-cloud-*` lo encuentran solo por la cadena
de ADC. Es la razón técnica de que descargar una key de service account casi nunca sea necesario, y
la mejor respuesta a esa pregunta en una entrevista.

---

## 6. 🩺 Invocación autenticada: los dos tokens

El servicio está desplegado con `--no-allow-unauthenticated`. Compruébalo:

```bash
URL=$(gcloud run services describe inv-api --region us-central1 --format='value(status.url)')
curl -s -o /dev/null -w '%{http_code}\n' -X POST "$URL/movements" \
  -H 'Content-Type: application/json' -d '{"sku":"ABC-1","delta":-3}'
```

```text
403
```

Perfecto: un 403 es la señal de que el servicio no está abierto al mundo. Ahora con credencial:

```bash
curl -s -X POST "$URL/movements" \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H 'Content-Type: application/json' \
  -d '{"sku":"ABC-1","delta":-3}'
```

```text
{"accepted":true,"sku":"ABC-1"}
```

Y aquí la confusión que hay que resolver de una vez, porque cuesta horas:

| Token | Comando | Para qué sirve |
|---|---|---|
| **Identity token** (ID token, OIDC) | `gcloud auth print-identity-token` | Invocar un servicio de Cloud Run privado |
| **Access token** (OAuth) | `gcloud auth print-access-token` | Llamar a las APIs de Google (`*.googleapis.com`) |

> ⚠️ **Usar el access token para invocar Cloud Run devuelve 401 o 403** y el mensaje no ayuda
> nada. Son dos tokens para dos cosas distintas: el ID token dice *quién eres* al servicio; el
> access token dice *qué puedes hacer* a una API. Cuando en [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) sea Pub/Sub quien invoque a
> `inv-projector`, el token que firme será de la primera familia.

**Quién puede invocar** es una allow policy más, y va **en el servicio**:

```bash
gcloud run services get-iam-policy inv-api --region us-central1 \
  --flatten='bindings[].members[]' \
  --filter='bindings.role:roles/run.invoker' \
  --format='value(bindings.members)'
```

Tú puedes porque eres owner del proyecto y el rol se hereda. Para dar acceso a alguien más, el
binding correcto es el del recurso —no el del proyecto—, por la razón de
[`L02` §5](l02-iam-allow-policies-service-accounts-e-impersonation.md#5--el-experimento-central-el-binding-en-el-recurso-equivocado):

```bash
gcloud run services add-iam-policy-binding inv-api \
  --region us-central1 \
  --member="serviceAccount:inv-projector-sa@inv-lab-472913.iam.gserviceaccount.com" \
  --role=roles/run.invoker
```

> ⚠️ **`--allow-unauthenticated` añade `allUsers` como principal con `roles/run.invoker`**: publica
> la URL a Internet, para cualquiera, sin autenticación. Es una decisión legítima para una web
> pública y es un desastre para un endpoint interno. Si despliegas sin ninguno de los dos flags,
> `gcloud` te lo **pregunta de forma interactiva**, y responder que sí por inercia es cómo acaba
> abierto medio Internet. Por eso el curso escribe siempre `--no-allow-unauthenticated`.

---

## 7. 🧱 Concurrencia, escalado a cero y timeouts

Los tres parámetros que definen cómo se comporta —y cuánto cuesta— el servicio.

```bash
gcloud run services describe inv-api --region us-central1 \
  --format='value(spec.template.spec.containerConcurrency, spec.template.spec.timeoutSeconds)'
```

**`--concurrency 80`.** Cuántas peticiones atiende **una misma instancia a la vez**. Es la
diferencia más importante frente a un modelo de funciones clásico, donde cada petición ocupa una
instancia entera.

```text
concurrency = 1     1000 peticiones simultáneas → hasta 1000 instancias
concurrency = 80    1000 peticiones simultáneas → unas 13 instancias
```

Y como Cloud Run factura por **vCPU-segundo y GiB-segundo de instancia**, la concurrencia es
directamente un dial de costo. El límite lo pone tu código: si no es seguro atender varias
peticiones a la vez en el mismo proceso, `--concurrency 1` es correcto y caro. Si lo es, subirlo
es la optimización más barata que existe.

**Escalado a cero.** Sin tráfico, Cloud Run apaga todas las instancias y **el servicio cuesta
$0.00**. El precio es el **cold start**: la primera petición después de un rato paga el arranque
del contenedor. Mídelo tú mismo:

```bash
time curl -s -o /dev/null -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$URL/healthz"
# espera cinco minutos sin tocar el servicio y repite: la diferencia es el cold start
```

Ahí se ve por qué §3 insistía en la imagen `slim`: una imagen más pequeña arranca antes.

**`--timeout 60s`.** Cuánto puede tardar una petición antes de que la plataforma la corte. El
default es más generoso y el máximo, mucho mayor; ponerlo bajo a propósito es lo correcto para una
API, porque una petición colgada consume una ranura de concurrencia todo ese tiempo. Y recuerda el
detalle del Dockerfile: **el timeout de `gunicorn` está desactivado precisamente para que mande
este**.

**`--max-instances 3`.** El techo de escalado. En un lab es una protección real: un bucle de
reintentos —los que vas a provocar en [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md)— con escalado ilimitado es la forma más rápida de
gastar la cuota gratuita en una tarde.

---

## 8. 💰 `min-instances`: el flag que rompe el cero

El experimento más corto del lab, y el que más dinero ahorra a largo plazo. Elimina el cold start:

```bash
gcloud run services update inv-api --region us-central1 --min-instances 1
```

Vuelve a medir el `curl` tras cinco minutos de silencio: instantáneo. El cold start desapareció.

Y ahora lo que acabas de comprar:

> ⚠️ **`--min-instances 1` significa una instancia encendida siempre.** vCPU y memoria facturando
> **24 horas al día, 7 días a la semana**, aunque no llegue ni una sola petición. Es la forma más
> fácil de convertir un servicio que costaba $0.00 en uno que cobra por hora, y en la factura
> aparece como consumo de Cloud Run sin ningún tráfico que lo explique.

Es una decisión legítima en producción, cuando el cold start del percentil 99 importa más que el
costo. En un laboratorio no lo es nunca. Deshazlo **ahora**, no al final de la sesión:

```bash
gcloud run services update inv-api --region us-central1 --min-instances 0
gcloud run services describe inv-api --region us-central1 \
  --format='value(spec.template.metadata.annotations["autoscaling.knative.dev/minScale"])'
```

```text
0
```

---

## 9. 🧱 Revisiones y reparto de tráfico

Cada despliegue crea una **revisión** inmutable: imagen, variables, recursos y configuración
congelados. El servicio es un puntero que reparte tráfico entre revisiones.

```text
servicio inv-api
   │
   ├── revisión inv-api-00003-xyz   ← 100 % del tráfico
   ├── revisión inv-api-00002-def   ← 0 %  (existe, no recibe nada)
   └── revisión inv-api-00001-abc   ← 0 %  (la rota de §4)
```

```bash
gcloud run revisions list --service inv-api --region us-central1 \
  --format='table(metadata.name, status.conditions[0].status, spec.containers[0].image)'
```

**El canary.** Despliega una versión nueva sin darle tráfico:

```bash
gcloud run deploy inv-api \
  --image us-central1-docker.pkg.dev/inv-lab-472913/inv-lab/inv-api:v2 \
  --region us-central1 \
  --service-account inv-api-sa@inv-lab-472913.iam.gserviceaccount.com \
  --no-allow-unauthenticated \
  --no-traffic \
  --tag canary
```

- **`--no-traffic`** crea la revisión y **no le manda nada**. Sin este flag, cada despliegue se
  lleva el 100 % del tráfico al instante.
- **`--tag canary`** le da a esa revisión **una URL propia y estable** (`canary---inv-api-….run.app`)
  para probarla en aislamiento antes de exponerla. Es lo que convierte el despliegue progresivo en
  algo verificable en vez de en un acto de fe.

Reparte el tráfico cuando estés conforme:

```bash
gcloud run services update-traffic inv-api --region us-central1 \
  --to-revisions=inv-api-00004-canary=10,inv-api-00003-xyz=90
```

```bash
gcloud run services describe inv-api --region us-central1 \
  --format='table(status.traffic.revisionName, status.traffic.percent, status.traffic.tag)'
```

Y el rollback, que es la razón de que todo esto exista:

```bash
gcloud run services update-traffic inv-api --region us-central1 --to-latest
# o, para volver a una revisión concreta:
gcloud run services update-traffic inv-api --region us-central1 \
  --to-revisions=inv-api-00003-xyz=100
```

> 🧠 **Modelo mental.** El rollback en Cloud Run **no reconstruye ni redespliega nada**: mueve un
> puntero de tráfico a una revisión que ya existe y ya está sana. Es cuestión de segundos, y es la
> mejor respuesta a "¿cómo revertirías un despliegue fallido?" — siempre que no hayas borrado la
> revisión anterior.

---

## 10. 🧱 Un secreto desde Secret Manager

Última pieza. El servicio necesita una clave de API de un proveedor imaginario, y hay tres formas
de dársela: dos malas y una correcta.

```text
❌ en el Dockerfile           queda en la imagen, en el registry, para siempre
❌ en --set-env-vars          visible en `describe`, en los logs de despliegue y en el historial
✅ en Secret Manager          versionado, con IAM propio, y montado en tiempo de ejecución
```

El secreto es infraestructura, así que va en Terraform:

```hcl
# secrets.tf

resource "google_secret_manager_secret" "api_key" {
  secret_id = "inv-api-external-key"

  replication {
    auto {}   # Google elige dónde replicarlo; la alternativa es user_managed con regiones fijas
  }

  labels = {
    project = "inv_lab"
  }
}

# el valor NO se pone aquí: acabaría en el state en claro
resource "google_secret_manager_secret_iam_member" "api_can_read" {
  secret_id = google_secret_manager_secret.api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com"
}
```

- **`replication { auto {} }`** deja que Google replique el secreto donde quiera. La alternativa,
  `user_managed`, fija las regiones y es lo que pide un requisito de residencia de datos.
- **El valor del secreto no está en el HCL, y es deliberado**: un
  `google_secret_manager_secret_version` con el valor inline lo dejaría **en claro dentro del
  state**, que es justo el problema que Secret Manager viene a resolver
  ([`L03` §5](l03-terraform-desde-la-cli.md#5--qué-hay-dentro-del-state-y-por-qué-no-se-toca)).
  La versión se crea fuera, con `gcloud`.
- **`roles/secretmanager.secretAccessor` va sobre el secreto**, no sobre el proyecto. Otra vez la
  lección de [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md): en el proyecto, esa cuenta podría leer **todos** los secretos presentes y
  futuros.

```bash
terraform apply
printf 'clave-de-mentira-para-el-lab' | \
  gcloud secrets versions add inv-api-external-key --data-file=-
```

- `--data-file=-` lee el valor de la entrada estándar. **Nunca pases un secreto como argumento de
  la línea de comandos**: queda en el historial del shell y en la lista de procesos.
- Cada `versions add` crea una versión nueva; las anteriores siguen ahí hasta que las
  deshabilites. La cuota Always Free cubre **6 versiones activas** y 10.000 accesos al mes.

Y ahora las dos formas de consumirlo desde Cloud Run:

```bash
# como variable de entorno, resuelta al arrancar la instancia
gcloud run services update inv-api --region us-central1 \
  --set-secrets=EXTERNAL_API_KEY=inv-api-external-key:latest

# o montado como archivo
gcloud run services update inv-api --region us-central1 \
  --set-secrets=/secrets/api-key=inv-api-external-key:latest
```

- **`--set-secrets` no guarda el valor en la configuración del servicio**: guarda una referencia
  `nombre:versión`. El valor se resuelve en el arranque de cada instancia, con la identidad del
  servicio. Por eso el binding de arriba era imprescindible: sin él, la instancia falla al
  arrancar con un `PERMISSION_DENIED` sobre el secreto.
- **`:latest` frente a `:3`.** `latest` toma siempre la última versión, cómodo y no determinista:
  añadir una versión cambia el comportamiento de la siguiente instancia que arranque, sin
  desplegar nada. Fijar el número es reproducible y obliga a un despliegue para rotar. En
  producción, número; en un lab, `latest` es aceptable y conviene saber qué se está aceptando.

```bash
gcloud run services describe inv-api --region us-central1 --format=json | grep -A3 secret
```

Lo que ves es la referencia, no la clave. Ese es el punto entero.

---

## 11. 🧹 Teardown de este lab

| Recurso | ¿Cobra? | Qué hacer |
|---|---|---|
| Servicio `inv-api` con `min-instances 0` | $0.00 sin tráfico | Se queda: [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) lo amplía |
| Revisiones antiguas (incluida la rota de §4) | No | Se van con el servicio |
| Repositorio de Artifact Registry | **Sí, por encima de 0,5 GB** | Limpiar imágenes viejas — abajo |
| Secreto `inv-api-external-key` | No dentro de la cuota | Se queda: [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) no lo toca |
| Binding `secretAccessor` sobre el secreto | No | Se queda |

**Lo único que cobra de verdad**, y conviene verlo con números propios:

```bash
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/inv-lab-472913/inv-lab/inv-api \
  --include-tags \
  --format='table(version.basename():label=DIGEST, tags, createTime, imageSizeBytes)'
```

Tres o cuatro imágenes ya, y una de ellas es la rota de §4 que no sirve para nada. Bórrala:

```bash
gcloud artifacts docker images delete \
  us-central1-docker.pkg.dev/inv-lab-472913/inv-lab/inv-api:v0-roto \
  --delete-tags --quiet
```

- `--delete-tags` borra también los tags que apuntan a ese digest; sin el flag, el comando se
  niega si hay alguno.
- **Ojo con el orden:** borrar una imagen que una revisión activa todavía usa deja esa revisión
  incapaz de arrancar una instancia nueva. Borra solo lo que ninguna revisión con tráfico
  referencia.

> ⚠️ **Y el huérfano que no ves.** La revisión rota de §4 sigue en el historial del servicio para
> siempre, y no cobra; su imagen sí cobraba, y ya no. Esta es, en pequeño, la mecánica exacta de un
> costo que nadie decidió: nadie eligió pagar por una imagen fallida de hace tres semanas. El
> catálogo completo está en
> [`A02` §3](a02-costos-trampas-y-recursos-huerfanos.md#3--el-catálogo-de-lo-que-cobra-por-existir).

Verificación de que no se coló nada que cobre por hora:

```bash
gcloud compute forwarding-rules list --format='table(name, region)'
gcloud compute addresses list --format='table(name, region, status)'
gcloud run services list --format='table(metadata.name, status.url)'
```

Los dos primeros vacíos —Cloud Run **no** crea load balancers ni IPs: la URL `run.app` viene con el
servicio y no cobra— y un solo servicio en el tercero.

---

## 📋 Checklist de salida

- [ ] Probaste la imagen en local con `docker run -e PORT=8080` antes de subir nada.
- [ ] Provocaste el fallo de `PORT` a propósito y confirmaste la causa en los logs de la revisión.
- [ ] El servicio corre con `inv-api-sa`, y lo verificaste con `describe`, no de memoria.
- [ ] Esa service account **no tiene ningún rol en el proyecto** y el servicio funciona igual.
- [ ] Un `curl` sin token devuelve 403 y con identity token devuelve 202.
- [ ] Sabes qué token es cuál y por qué el access token no sirve aquí.
- [ ] Mediste el cold start, activaste `--min-instances 1`, viste la diferencia y **lo devolviste a 0**.
- [ ] Desplegaste una revisión con `--no-traffic --tag canary` y repartiste tráfico 90/10.
- [ ] Hiciste un rollback moviendo el tráfico, sin redesplegar.
- [ ] El secreto se consume por referencia: `describe` no muestra su valor.
- [ ] Borraste la imagen rota de Artifact Registry y sabes cuántas quedan.

## 🏁 La señal de que quedó bien

`gcloud run services describe inv-api` muestra `minScale: 0`, una service account propia sin roles
de proyecto y un secreto referenciado por nombre y versión; un `curl` sin credencial devuelve 403;
no hay una sola forwarding rule ni IP reservada en el proyecto; y puedes explicar en una frase por
qué este servicio cuesta $0.00 mientras nadie lo llame.

---

## 🧠 Preguntas rápidas

1. ¿Cuáles son las cuatro cláusulas del contrato de plataforma de Cloud Run?
2. ¿Por qué no puedes guardar estado en memoria entre peticiones?
3. ¿Qué pasa si tu proceso escucha en `127.0.0.1` en vez de `0.0.0.0`, y por qué el mensaje de error es el mismo que si usaras un puerto fijo?
4. ¿Cómo distingues en los logs las tres causas de "failed to start and listen on PORT"?
5. ¿Por qué el `CMD` del Dockerfile lleva `exec`, y qué se rompe si lo quitas?
6. ¿Por qué `--workers 1 --threads 8` y no ocho workers?
7. Si omites `--service-account` en el despliegue, ¿con qué identidad corre el servicio y por qué es un problema?
8. ¿De dónde saca credenciales tu código dentro de Cloud Run, sin ningún archivo de claves?
9. ¿Qué token necesitas para invocar un servicio privado y cuál es el que la gente usa por error?
10. ¿Qué hace exactamente `--allow-unauthenticated` en términos de IAM?
11. ¿Cómo cambia el número de instancias necesarias al pasar de `--concurrency 1` a `--concurrency 80`, y por qué es un dial de costo?
12. ¿Qué compras y qué pagas con `--min-instances 1`?
13. ¿Por qué el timeout de `gunicorn` está desactivado en el Dockerfile?
14. ¿Qué hace `--no-traffic --tag canary` y por qué es mejor que desplegar y repartir después?
15. ¿Por qué un rollback en Cloud Run es cuestión de segundos?
16. ¿Por qué el valor del secreto no se pone en el HCL, y dónde va el binding de `secretAccessor`?
17. ¿Qué se guarda en la configuración del servicio cuando usas `--set-secrets`, y qué implica usar `:latest`?
18. ¿Cuál es el único recurso de este lab que cobra de verdad, y por qué crece solo?

---

## 📚 Referencias oficiales

- Documentación de Cloud Run: https://cloud.google.com/run/docs
- Contrato del contenedor de Cloud Run: https://cloud.google.com/run/docs/container-contract
- Desplegar servicios de contenedores: https://cloud.google.com/run/docs/deploying
- Identidad de servicio en Cloud Run: https://cloud.google.com/run/docs/securing/service-identity
- Autenticación de desarrolladores y de servicio a servicio: https://cloud.google.com/run/docs/authenticating/service-to-service
- Permitir el acceso público a un servicio: https://cloud.google.com/run/docs/authenticating/public
- Configurar la concurrencia: https://cloud.google.com/run/docs/configuring/concurrency
- Configurar el número mínimo de instancias: https://cloud.google.com/run/docs/configuring/min-instances
- Configurar el número máximo de instancias: https://cloud.google.com/run/docs/configuring/max-instances
- Configurar el tiempo de espera de las solicitudes: https://cloud.google.com/run/docs/configuring/request-timeout
- Acerca de las revisiones: https://cloud.google.com/run/docs/managing/revisions
- Distribuir el tráfico entre revisiones: https://cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration
- Usar secretos en Cloud Run: https://cloud.google.com/run/docs/configuring/services/secrets
- Solución de problemas de Cloud Run: https://cloud.google.com/run/docs/troubleshooting
- Precios de Cloud Run: https://cloud.google.com/run/pricing
- Documentación de Artifact Registry: https://cloud.google.com/artifact-registry/docs
- Configurar la autenticación de Docker: https://cloud.google.com/artifact-registry/docs/docker/authentication
- Administrar imágenes en Artifact Registry: https://cloud.google.com/artifact-registry/docs/docker/manage-images
- Políticas de limpieza de Artifact Registry: https://cloud.google.com/artifact-registry/docs/repositories/cleanup-policy
- Precios de Artifact Registry: https://cloud.google.com/artifact-registry/pricing
- Documentación de Secret Manager: https://cloud.google.com/secret-manager/docs
- Crear y acceder a secretos: https://cloud.google.com/secret-manager/docs/creating-and-accessing-secrets
- Control de acceso en Secret Manager: https://cloud.google.com/secret-manager/docs/access-control
- Logs estructurados en Cloud Logging: https://cloud.google.com/logging/docs/structured-logging
- `google_artifact_registry_repository`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository
- `google_secret_manager_secret`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret
