# L07 — Observabilidad: logs, métricas y auditoría

> **Objetivo:** hacer observable el sistema que montaste: logs estructurados que Cloud Logging sepa
> indexar, una log-based metric, una alerting policy que **se dispare de verdad**, Error Reporting,
> Cloud Trace, y saber exactamente qué registran —y qué no— los Cloud Audit Logs.
> **Se asume leído:** [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md). Rinde mucho más
> con [`08`](08-observabilidad-auditoria-gobierno.md) leído.
> **Costo:** **$0.00**. El lab se queda muy por debajo de los 50 GiB de ingesta gratuita de Cloud
> Logging, y las métricas y alertas de este alcance no cobran.
> **Duración:** 2–3 horas.
> **Prerrequisitos:** `L01`–`L06` completos, con el sistema entero funcionando y el veneno de [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md)
> §8 reproducible.
> **Qué queda encendido al terminar:** lo mismo que dejó [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md), más una log-based metric, una
> alerting policy y un canal de notificación. Nada de eso factura.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Las tres preguntas](#1--las-tres-preguntas-que-responde-la-observabilidad) ·
[Logs estructurados](#2--logs-estructurados-la-diferencia-entre-buscar-y-filtrar) ·
[Consultar logs](#3--consultar-logs-desde-la-cli) ·
[Log-based metrics](#4--log-based-metrics-de-un-log-a-un-número) ·
[Una alerta que se dispare](#5--una-alerta-que-se-dispare-de-verdad) ·
[Error Reporting](#6--error-reporting-agrupar-en-vez-de-contar) ·
[Cloud Trace](#7--cloud-trace-y-el-salto-entre-servicios) ·
[Audit Logs](#8--cloud-audit-logs-qué-se-registra-y-qué-no) ·
[Retención y sinks](#9--retención-sinks-y-lo-que-de-verdad-cuesta) ·
[Teardown](#10--teardown-de-este-lab) ·
[Checklist](#-checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 Las tres preguntas que responde la observabilidad

Un sistema asíncrono tiene una propiedad desagradable que ya sufriste en
[`L06` §6](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md#6--provocar-el-403-de-la-entrega-push):
**el productor no se entera de que el consumidor no recibe**. El `curl` devolvía 202 tan feliz
mientras nada se procesaba. Sin observabilidad, ese sistema puede estar roto durante días.

Las tres preguntas, y con qué se responde cada una:

```text
¿QUÉ pasó?          →  logs         una línea por evento, con contexto
¿CUÁNTO pasa?       →  métricas     un número en el tiempo, con umbrales
¿QUIÉN lo hizo?     →  audit logs   quién llamó a qué API, cuándo y desde dónde
```

> 🧠 **Modelo mental.** Los tres son cosas distintas y se confunden constantemente. Un log
> responde "¿qué le pasó a esta petición?"; una métrica responde "¿cuántas veces está pasando y
> desde cuándo?"; un audit log responde "¿quién cambió esto?". Montar alertas sobre logs sin
> convertirlos primero en métricas es el error de diseño más común, y §4 lo resuelve.

---

## 2. 🧱 Logs estructurados: la diferencia entre buscar y filtrar

En [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) tu servicio ya escribía así, y ahora toca explicar por qué:

```python
print(json.dumps({
    "severity": "ERROR",
    "message": "delta 0 no es un movimiento válido",
    "event_id": event_id,
    "sku": sku,
}))
```

**Qué hace Cloud Logging con eso.** En Cloud Run, todo lo que escribes en `stdout` y `stderr` se
recoge automáticamente. Si la línea es texto plano, se guarda como `textPayload`: un bloque de
texto que solo se puede buscar por subcadena. **Si la línea es un JSON válido, se guarda como
`jsonPayload`**, con cada campo indexado y consultable por separado.

```text
texto plano   →  textPayload: "ERROR delta 0 no válido event=ev-veneno"
                 buscas con:  textPayload:"ev-veneno"      ← subcadena, frágil

JSON          →  jsonPayload: {message, event_id, sku}
                 filtras con: jsonPayload.event_id="ev-veneno"   ← campo, exacto
```

Y hay dos campos con significado especial que Cloud Logging **saca del JSON y sube al nivel de la
entrada**:

- **`severity`** — `DEBUG`, `INFO`, `NOTICE`, `WARNING`, `ERROR`, `CRITICAL`, `ALERT`,
  `EMERGENCY`. Sin él, todo lo que escribes en `stdout` aparece como `INFO` y **todo lo de `stderr`
  como `ERROR`**, lo que llena el panel de falsos errores con cada `warning` de una librería.
- **`logging.googleapis.com/trace`** — si lo pones, la entrada se asocia a una traza y podrás verla
  junto al resto de la petición. Es la costura con §7.

> 💡 **Truco.** Si usas el módulo `logging` de Python en vez de `print`, la librería
> `google-cloud-logging` trae un handler que hace esta traducción por ti y añade el trace
> automáticamente. Para un servicio de veinte líneas, el `print` con `json.dumps` es más honesto:
> **te enseña que la magia es solo un JSON en stdout**, que es lo que hay que saber para depurar
> cuando la librería no está.

---

## 3. 🩺 Consultar logs desde la CLI

```bash
gcloud logging read \
  'resource.type="cloud_run_revision"
   AND resource.labels.service_name="inv-projector"
   AND severity>=ERROR' \
  --limit=10 --freshness=1h \
  --format='table(timestamp, jsonPayload.event_id, jsonPayload.message)'
```

- **La consulta usa el mismo lenguaje que la consola**, así que lo que aprendas aquí sirve en los
  dos sitios.
- **`resource.type`** es el primer filtro de cualquier consulta: acota a un tipo de recurso.
  `cloud_run_revision` es el de un servicio de Cloud Run.
- **`severity>=ERROR`** aprovecha que la severidad es ordinal: trae `ERROR`, `CRITICAL` y por
  encima.
- **`--freshness=1h`** acota la ventana temporal. Sin él, la consulta barre hacia atrás mucho más
  de lo que necesitas y tarda.
- **`--limit`** corta el número de entradas. Los dos flags juntos son la diferencia entre una
  consulta de dos segundos y una de dos minutos.

Tres consultas que vale la pena tener guardadas, porque responden a las preguntas reales de la
serie:

```bash
# 1. el 403 de una entrega push (el de L06 §6)
gcloud logging read \
  'resource.type="cloud_run_revision" AND httpRequest.status=403' \
  --limit=5 --freshness=1h \
  --format='table(timestamp, resource.labels.service_name, protoPayload.authenticationInfo.principalEmail)'

# 2. todo lo que tocó un evento concreto, cruzando los dos servicios
gcloud logging read \
  'jsonPayload.event_id="ev-veneno"' \
  --freshness=6h \
  --format='table(timestamp, resource.labels.service_name, severity, jsonPayload.message)'

# 3. arranques fallidos de una revisión
gcloud logging read \
  'resource.type="cloud_run_revision" AND textPayload:"failed to start"' \
  --limit=5 --freshness=24h
```

La segunda es la que demuestra el valor del log estructurado: **una sola consulta que sigue un
evento a través de dos servicios**, porque los dos escribieron el mismo campo `event_id`. Con
texto plano eso es un `grep` con los dedos cruzados.

---

## 4. 🧱 Log-based metrics: de un log a un número

El problema: quieres una alerta cuando lleguen mensajes al dead-letter topic. Los logs te dicen
*qué* pasó, pero **no se puede alertar sobre un log directamente**: una alerta necesita una serie
temporal, es decir, un número que evoluciona.

Una **log-based metric** es exactamente ese puente: cuenta las entradas que coinciden con un filtro
y las expone como métrica.

```hcl
# observability.tf

resource "google_logging_metric" "poison_events" {
  name   = "inv_lab_poison_events"
  filter = <<-EOT
    resource.type="cloud_run_revision"
    AND resource.labels.service_name="inv-projector"
    AND severity>=ERROR
    AND jsonPayload.message:"no es un movimiento válido"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "sku"
      value_type  = "STRING"
      description = "SKU del movimiento rechazado"
    }
  }

  label_extractors = {
    "sku" = "EXTRACT(jsonPayload.sku)"
  }
}
```

- **`metric_kind = "DELTA"`** significa "cuántas veces ocurrió en este intervalo", que es lo
  correcto para un contador de eventos. La alternativa, `GAUGE`, es para valores instantáneos como
  una temperatura.
- **`labels` + `label_extractors`** es lo que convierte un contador tonto en algo útil: extrae el
  `sku` de cada entrada y lo convierte en una dimensión de la métrica. Así puedes preguntar *"¿qué
  SKU está generando los rechazos?"* sin volver a los logs.
- ⚠️ **Cuidado con la cardinalidad.** Un label con muchos valores distintos —un `event_id`, un ID
  de usuario— multiplica las series temporales y llega a los límites del servicio. `sku` está bien
  porque son decenas; `event_id` sería un error.
- **La métrica solo cuenta desde que existe.** No hay retroactividad: crear la métrica no procesa
  los logs de ayer.

```bash
terraform apply -var="projector_url=$PROJECTOR_URL"
gcloud logging metrics list --format='table(name, filter.trim())'
```

---

## 5. 🩺 Una alerta que se dispare de verdad

Aquí está el ejercicio del lab, y la parte que casi todo el mundo se salta: **una alerta que nunca
se ha disparado no es una alerta, es una intención**.

Primero el canal por donde va a llegar:

```hcl
resource "google_monitoring_notification_channel" "email" {
  display_name = "inv-lab — correo"
  type         = "email"

  labels = {
    email_address = "tu-cuenta@gmail.com"
  }
}
```

- **`type = "email"`** es el canal más simple. Hay otros —Pub/Sub, webhook, SMS, integraciones de
  terceros— y el de Pub/Sub es el que usarías para automatizar una respuesta, igual que hiciste con
  el presupuesto en [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md).

Y la política:

```hcl
resource "google_monitoring_alert_policy" "poison" {
  display_name = "inv-lab — eventos envenenados"
  combiner     = "OR"

  conditions {
    display_name = "Más de 2 rechazos en 5 minutos"

    condition_threshold {
      filter = <<-EOT
        metric.type="logging.googleapis.com/user/inv_lab_poison_events"
        AND resource.type="cloud_run_revision"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 2
      duration        = "0s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}
```

- **`metric.type` lleva el prefijo `logging.googleapis.com/user/`.** Toda log-based metric vive bajo
  ese espacio de nombres, y olvidarlo produce una política que nunca dispara porque apunta a una
  métrica inexistente. **No da error al crearla**: simplemente no pasa nada nunca, que es el peor
  modo de fallo posible.
- **`aggregations`** es la parte que más se equivoca. `alignment_period = "300s"` agrupa los puntos
  en ventanas de cinco minutos y `ALIGN_SUM` los suma. Sin aggregations, comparas puntos sueltos
  contra el umbral y la alerta se comporta de forma errática.
- **`duration = "0s"`** dispara en cuanto una ventana supera el umbral. Un valor mayor exige que la
  condición se sostenga ese tiempo, que es lo correcto para métricas ruidosas como la latencia.
- **`auto_close`** cierra el incidente solo si la condición deja de cumplirse. Sin él, los
  incidentes se acumulan abiertos y el panel deja de significar nada.

**Ahora dispárala.** Manda tres mensajes envenenados seguidos:

```bash
URL=$(gcloud run services describe inv-api --region us-central1 --format='value(status.url)')
for i in 1 2 3; do
  curl -s -o /dev/null -X POST "$URL/movements" \
    -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
    -H 'Content-Type: application/json' \
    -d "{\"event_id\":\"ev-veneno-$i\",\"sku\":\"ABC-1\",\"delta\":0}"
done
```

Recuerda de [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) que cada uno se reintenta cinco veces antes de irse al DLQ, así que la métrica va
a contar bastante más de tres. Espera unos minutos y comprueba:

```bash
gcloud alpha monitoring policies list \
  --format='table(displayName, enabled, conditions[0].displayName)'
```

> 🩺 **Diagnóstico: la alerta no se dispara.** El orden de sospecha, de lo más común a lo menos:
> (1) el filtro de la **métrica** no coincide con lo que escribe tu código — compruébalo con un
> `logging read` usando el mismo filtro; (2) el `metric.type` de la **política** no lleva el prefijo
> `logging.googleapis.com/user/`; (3) faltan las `aggregations`; (4) la métrica se creó **después**
> de los logs que esperabas contar. Las cuatro producen el mismo síntoma: silencio.

---

## 6. 🧱 Error Reporting: agrupar en vez de contar

Los logs te dan una línea por incidente. Cuando el mismo error ocurre diez mil veces, lo que quieres
no son diez mil líneas: quieres **un grupo** con su primera aparición, su última y su frecuencia.

Error Reporting hace exactamente eso, y no hay que configurar nada: **agrupa automáticamente las
entradas de log con severidad de error que contienen un stack trace**, por la firma de la
excepción. Recoge las de Cloud Run sin que le digas nada.

Lo que sí depende de ti es que el error llegue con forma de error:

```python
import json
import traceback

try:
    apply_movement(db.transaction())
except Exception:
    print(json.dumps({
        "severity": "ERROR",
        "message": traceback.format_exc(),   # el stack trace COMPLETO, no solo str(exc)
        "event_id": event_id,
    }))
    raise
```

> ⚠️ **`str(exc)` no es un stack trace.** Un mensaje sin traza se registra como un error más y **no
> se agrupa**, porque no hay firma con la que agrupar. Es la razón número uno de que Error Reporting
> "no funcione": el problema no está en el producto, está en lo que le mandas.

---

## 7. 🧱 Cloud Trace y el salto entre servicios

Una petición a `inv-api` desencadena una escritura en Firestore, una publicación en Pub/Sub, una
entrega push y una transacción en `inv-projector`. Cuando el total tarda tres segundos, la pregunta
es **dónde** se fueron.

Cloud Trace responde eso con **spans**: cada tramo de trabajo con su duración, anidados en un árbol.
En Cloud Run hay una parte gratis y una que hay que ganarse:

- **Cloud Run genera automáticamente un span por petición** y le pone un ID de traza, que llega a tu
  proceso en el header `X-Cloud-Trace-Context`.
- **Los spans internos —"esto tardó tanto en Firestore"— los añade tu código**, con el SDK de
  OpenTelemetry o el cliente de Cloud Trace.
- **La traza no cruza el salto asíncrono por sí sola.** Entre `inv-api` y `inv-projector` hay un
  mensaje de Pub/Sub, y para que las dos mitades queden en la misma traza hay que **propagar el
  contexto como atributo del mensaje** y recogerlo en el consumidor. Si no lo haces, tienes dos
  trazas inconexas y no puedes contar la historia completa.

```python
# propagar el contexto: un atributo más del mensaje, igual que event_id
trace_header = request.headers.get("X-Cloud-Trace-Context", "")
publisher.publish(TOPIC, payload, event_id=event_id, trace_context=trace_header)
```

> 🧠 **Modelo mental.** El tracing distribuido no es automático **en el punto donde el sistema deja
> de ser síncrono**. Ese es el detalle que separa a quien ha instrumentado un sistema real de quien
> ha leído sobre tracing, y es una repregunta muy frecuente cuando dices "usamos Cloud Trace".

Este lab no instrumenta spans manuales —sería un lab de OpenTelemetry, no de GCP—, pero sí conviene
mirar lo que ya hay:

```bash
gcloud logging read 'resource.type="cloud_run_revision" AND trace!=""' \
  --limit=5 --freshness=1h \
  --format='table(timestamp, trace, resource.labels.service_name)'
```

Ese campo `trace` es el que enlaza log y traza. Verlo poblado es la señal de que la costura existe.

---

## 8. 🧱 Cloud Audit Logs: qué se registra y qué no

Cambiamos de pregunta: ya no es "¿qué le pasó a mi petición?" sino **"¿quién cambió esto?"**. Los
Audit Logs son la respuesta, y tienen una división que hay que conocer al dedillo porque cae en
entrevista y porque afecta a la factura.

| Tipo | Qué registra | ¿Está activo por defecto? |
|---|---|---|
| **Admin Activity** | Toda llamada que **modifica** configuración o metadatos: crear un servicio, cambiar una allow policy, borrar un topic | **Sí, siempre. No se puede desactivar y no cobra** |
| **Data Access** | Lecturas y escrituras de **datos**: leer un documento de Firestore, descargar un objeto | **No.** Hay que habilitarlo, y **cobra** por volumen |
| **System Event** | Acciones que hace Google solo, sin que nadie llame | Sí, y no cobra |
| **Policy Denied** | Accesos denegados por una política de seguridad | Sí |

> 🧠 **Modelo mental.** **Quién borró el topic siempre queda registrado; quién leyó el documento,
> no** — a menos que hayas habilitado Data Access antes de que pasara. Es la distinción más
> importante del producto, y la razón de que un incidente de exfiltración de datos sea a menudo
> imposible de reconstruir a posteriori.

Compruébalo con algo que hiciste tú:

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   AND protoPayload.methodName:"SetIamPolicy"' \
  --limit=5 --freshness=24h \
  --format='table(timestamp, protoPayload.authenticationInfo.principalEmail, protoPayload.resourceName)'
```

```text
TIMESTAMP                 PRINCIPAL_EMAIL       RESOURCE_NAME
2026-09-06T17:12:44Z      tu-cuenta@gmail.com   projects/inv-lab-472913/services/inv-projector
```

Ahí está el binding de `run.invoker` que quitaste y volviste a poner en [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) §6, con tu nombre y la
hora. **Nadie tuvo que activar nada** para que eso quedara registrado.

- **`logName:"cloudaudit.googleapis.com%2Factivity"`** — el `%2F` es una barra codificada, porque el
  nombre del log la lleva dentro. Es feo y es así.
- **`protoPayload`** es la estructura de un audit log, distinta de `jsonPayload`. Sus campos clave:
  `authenticationInfo.principalEmail` (quién), `methodName` (qué API), `resourceName` (sobre qué) y
  `requestMetadata.callerIp` (desde dónde).

Y el otro lado de la moneda, para que la decisión sea informada:

> 💰 **Costo.** Habilitar **Data Access** en un proyecto con tráfico real puede multiplicar la
> ingesta de logs por un factor enorme —cada lectura genera una entrada—, y la ingesta por encima de
> los 50 GiB gratuitos por proyecto se paga. Habilitarlo "por si acaso" en todos los servicios es
> una de las formas más rápidas de convertir la observabilidad en la partida más cara de la factura.
> Se habilita por servicio y por tipo de acceso, no todo o nada.

---

## 9. 💰 Retención, sinks y lo que de verdad cuesta

El modelo de precios de Cloud Logging, en tres frases, porque es de los que más sorprende:

- **Se paga la ingesta**, no la consulta. Los primeros **50 GiB por proyecto al mes** son gratis.
- **La retención por defecto del bucket `_Default` es de 30 días** y está incluida; guardar más
  tiempo cuesta.
- **Los logs de Admin Activity van a un bucket aparte (`_Required`), con 400 días de retención,
  gratis y no configurable.** No puedes borrarlos ni acortarlos, y es deliberado.

Los dos diales que de verdad mueven ese número:

**Exclusiones.** Dejar de ingerir lo que no vas a mirar. Es lo que hace un equipo cuando descubre
que el 80 % de su factura de logs son los health checks:

```bash
gcloud logging sinks list --format='table(name, destination, filter.trim())'
```

**Sinks.** Enrutar logs a otro destino: otro bucket de Logging, Cloud Storage para archivo barato,
BigQuery para analizarlos con SQL, o Pub/Sub para reaccionar en caliente. Un sink a Cloud Storage
con clase de almacenamiento fría es el patrón estándar para requisitos de retención larga sin pagar
retención de Logging.

Este lab **no crea ningún sink**, y la razón se dice en vez de esconderse: con el volumen de logs
que genera —unos cientos de entradas— cualquier sink sería puro teatro, y un sink a BigQuery
añadiría un dataset al inventario que [`L08`](l08-costos-y-destruccion-verificada.md) tiene que limpiar sin haber enseñado nada nuevo. El
vocabulario sí entra en entrevista, y con eso basta.

---

## 10. 🧹 Teardown de este lab

| Recurso | ¿Cobra? | Qué hacer |
|---|---|---|
| Log-based metric `inv_lab_poison_events` | No | Se va con `terraform destroy` |
| Alerting policy y canal de notificación | No | Se van con `terraform destroy` |
| Logs ingeridos | Dentro de 50 GiB | Expiran solos a los 30 días; los de Admin Activity, a los 400 |
| Incidentes abiertos de la alerta | No | Se cierran solos con `auto_close`, o a mano |
| Data Access logs | **Sí, si los habilitaste** | **Deshabilítalos** si los activaste para probar |

La última fila es la única que importa de verdad, y conviene mirarla aunque creas que no la tocaste:

```bash
gcloud projects get-iam-policy inv-lab-472913 \
  --format='value(auditConfigs)'
```

Si devuelve vacío, no hay Data Access habilitado en ninguna parte y no hay nada que apagar.

```bash
gcloud logging metrics list --format='table(name)'
gcloud alpha monitoring policies list --format='table(displayName, enabled)'
gcloud logging sinks list --format='table(name, destination)'
```

Los sinks que aparezcan sin que tú los crearas son los de sistema (`_Default` y `_Required`) y no se
tocan.

---

## 📋 Checklist de salida

- [ ] Tus logs llegan como `jsonPayload`, no como `textPayload`, y lo verificaste con un `logging read`.
- [ ] La `severity` que escribes se refleja en la entrada, y no todo aparece como `INFO`.
- [ ] Seguiste un mismo `event_id` a través de los **dos** servicios con una sola consulta.
- [ ] La log-based metric existe y su filtro devuelve resultados cuando lo pruebas con `logging read`.
- [ ] El label `sku` se extrae de verdad, y sabes por qué `event_id` sería mala idea como label.
- [ ] **La alerta se disparó**, no solo se creó.
- [ ] Sabes las cuatro causas por las que una alerta puede no dispararse nunca sin dar ningún error.
- [ ] Encontraste en los Audit Logs el `SetIamPolicy` que ejecutaste en [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md), con tu identidad y la hora.
- [ ] Puedes decir qué queda registrado por defecto y qué no, y qué implica habilitar Data Access.
- [ ] `get-iam-policy --format='value(auditConfigs)'` está vacío, o desactivaste lo que hubieras activado.

## 🏁 La señal de que quedó bien

Recibiste el correo de la alerta que tú mismo provocaste; una sola consulta te devuelve la vida
completa de un evento cruzando dos servicios; y puedes explicar, señalando una entrada de audit log,
quién cambió una allow policy y a qué hora — sin haber habilitado nada para conseguirlo.

---

## 🧠 Preguntas rápidas

1. ¿Qué pregunta responde cada uno de los tres pilares: logs, métricas y audit logs?
2. ¿Qué diferencia hay entre `textPayload` y `jsonPayload`, y qué tienes que hacer para obtener el segundo?
3. ¿Qué pasa con la severidad de lo que escribes en `stderr` si no incluyes el campo `severity`?
4. ¿Por qué no se puede crear una alerta directamente sobre un log?
5. ¿Qué diferencia hay entre `DELTA` y `GAUGE` en una log-based metric?
6. ¿Por qué `sku` es un buen label de métrica y `event_id` no?
7. Una log-based metric recién creada, ¿cuenta los logs de ayer?
8. ¿Qué prefijo lleva el `metric.type` de una log-based metric, y qué ocurre si lo olvidas en la política?
9. ¿Para qué sirve el bloque `aggregations` de una condición y qué pasa si falta?
10. Nombra las cuatro causas de que una alerta no se dispare nunca sin dar error.
11. ¿Por qué `str(exc)` no basta para que Error Reporting agrupe un error?
12. ¿Qué genera Cloud Run automáticamente en materia de trazas y qué tienes que añadir tú?
13. ¿Por qué una traza no cruza sola el salto de Pub/Sub, y qué hay que hacer para que lo cruce?
14. ¿Qué registran los Admin Activity logs y qué registran los Data Access logs? ¿Cuáles están activos por defecto?
15. ¿Cuál de los dos cobra y por qué habilitarlo "por si acaso" es peligroso?
16. ¿Qué se paga en Cloud Logging: la ingesta o la consulta? ¿Cuál es la cuota gratuita?
17. ¿Cuánto se retienen los logs de Admin Activity y puedes cambiarlo?
18. ¿Qué dos mecanismos tienes para bajar la factura de logs, y para qué sirve cada uno?

---

## 📚 Referencias oficiales

- Documentación de Cloud Logging: https://cloud.google.com/logging/docs
- Logs estructurados: https://cloud.google.com/logging/docs/structured-logging
- Lenguaje de consultas de Logging: https://cloud.google.com/logging/docs/view/logging-query-language
- Niveles de severidad: https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#logseverity
- Log-based metrics: https://cloud.google.com/logging/docs/logs-based-metrics
- Métricas de contador basadas en logs: https://cloud.google.com/logging/docs/logs-based-metrics/counter-metrics
- Retención y buckets de logs: https://cloud.google.com/logging/docs/buckets
- Enrutamiento de logs y sinks: https://cloud.google.com/logging/docs/routing/overview
- Exclusiones de logs: https://cloud.google.com/logging/docs/exclusions
- Precios de Cloud Logging y Monitoring: https://cloud.google.com/stackdriver/pricing
- Documentación de Cloud Monitoring: https://cloud.google.com/monitoring/docs
- Políticas de alertas: https://cloud.google.com/monitoring/alerts
- Condiciones de umbral en una política: https://cloud.google.com/monitoring/alerts/concepts-indepth
- Canales de notificación: https://cloud.google.com/monitoring/support/notification-options
- Documentación de Error Reporting: https://cloud.google.com/error-reporting/docs
- Formatear errores para Error Reporting: https://cloud.google.com/error-reporting/docs/formatting-error-messages
- Documentación de Cloud Trace: https://cloud.google.com/trace/docs
- Cloud Audit Logs: https://cloud.google.com/logging/docs/audit
- Configurar Data Access logs: https://cloud.google.com/logging/docs/audit/configure-data-access
- Logs de auditoría por servicio: https://cloud.google.com/logging/docs/audit/services
- `google_logging_metric`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_metric
- `google_monitoring_alert_policy`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy
- `google_monitoring_notification_channel`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_notification_channel
