# A04 — Rutina de recurso: CLI, API y destrucción

> **Objetivo:** aprender a crear, inspeccionar, modificar, destruir y verificar **cualquier**
> recurso de GCP con un procedimiento fijo, primero desde `gcloud` y después desde código. Es la
> única pieza del curso que se *hace* en vez de leerse.
> **Se asume leído:** [`A01`](a01-gcloud-de-supervivencia.md) para `--format`, `--filter` y ADC.
> **Costo:** $0.00 por vuelta si eliges los recursos que sugiere §3. Ninguno de ellos cobra por
> existir.
> **Duración:** 45–90 minutos por vuelta. Los pasos 1 a 5 son media hora; el paso 6 es el resto.
> **Prerrequisitos:** un proyecto con facturación y `gcloud` autenticado. No hace falta ningún
> lab previo, aunque [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) deja el
> entorno ideal.
> **Qué queda encendido al terminar:** nada. El paso 4 destruye y el paso 5 lo demuestra.
> **Lenguaje del SDK:** Python. Puedes usar el que quieras; los fragmentos escritos van en uno
> solo para no multiplicar el mismo ejemplo por cuatro.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Por qué esta rutina](#1--por-qué-esta-rutina-y-no-un-tutorial-más) ·
[La forma fija](#2--la-forma-fija-seis-pasos) ·
[Qué recurso elegir](#3--qué-recurso-elegir-para-la-primera-vuelta) ·
[Paso 1: crear](#4--paso-1-crear) ·
[Paso 2: inspeccionar](#5--paso-2-inspeccionar-con---formatjson) ·
[Paso 3: modificar](#6--paso-3-modificar-y-encontrar-la-frontera-inmutable) ·
[Paso 4: destruir](#7--paso-4-destruir) ·
[Paso 5: verificar](#8--paso-5-verificar-qué-quedó-vivo) ·
[Paso 6: el SDK](#9--paso-6-lo-mismo-desde-el-sdk) ·
[El puente `--log-http`](#10--el-puente---log-http) ·
[Las tres lecciones](#11--las-tres-lecciones-que-solo-da-el-paso-6) ·
[El entregable](#12--el-entregable-no-es-el-recurso) ·
[Checklist de salida](#-checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 Por qué esta rutina y no un tutorial más

El problema que resuelve es concreto y probablemente lo reconoces: llevas tiempo usando la nube,
sabes explicar qué es un Managed Instance Group, y si te sientan delante de una terminal y te
dicen *"créalo"*, abres la documentación. Peor: si te dicen *"hazlo desde código"*, abres una
guía distinta y descubres que el ejemplo no se parece nada al comando que sí sabías.

Eso pasa porque la CLI y el SDK se aprenden como si fueran dos productos. No lo son.

> 🧠 **Modelo mental.** `gcloud` es un cliente HTTP de las APIs de Google Cloud. Tu código con
> `google-cloud-*` es **otro cliente de las mismas APIs**. Aprender el segundo desde el primero
> no es empezar de cero: es traducir.

La rutina existe para forzar esa traducción, y su forma es deliberadamente aburrida:

> 🧭 **Regla del apéndice: la forma es fija y se repite idéntica para todos los servicios.** Lo
> que varía es el recurso, nunca el procedimiento. Que sea siempre igual es justamente el punto:
> a la tercera vuelta ya no piensas en el procedimiento y piensas solo en el servicio.

Y trae, de regalo, la mejor respuesta que se puede dar a la pregunta de entrevista *"¿cómo harías
X en GCP?"*. La diferencia entre "sé lo que es" y "lo he creado, roto y borrado desde la CLI y
desde código" se nota en la primera repregunta.

---

## 2. 🧱 La forma fija: seis pasos

```text
1. Crear        gcloud ... create
2. Inspeccionar gcloud ... describe --format=json   ¿qué atributos tiene DE VERDAD?
3. Modificar    gcloud ... update                   ¿qué campo es mutable y cuál obliga a recrear?
4. Destruir     gcloud ... delete
5. Verificar    gcloud ... list                     ¿qué quedó vivo que no esperabas?
6. Repetir todo lo anterior desde un SDK
```

Los pasos 1 a 5 son media hora y parecen triviales. Lo son, y aun así casi nadie hace el 2 y el
5 — que son los dos que enseñan algo. **El paso 6 es donde está el aprendizaje de verdad**, y por
eso §10 dedica una sección entera al puente que lleva hasta él.

---

## 3. 🧱 Qué recurso elegir para la primera vuelta

Dos criterios: que su ciclo completo sea gratis, y que tenga al menos un campo mutable y uno
inmutable, porque si no el paso 3 no enseña nada.

| Recurso | Comando base | Costo del ciclo completo | Qué hace interesante el paso 3 |
|---|---|---|---|
| Topic de Pub/Sub | `gcloud pubsub topics` | $0.00 | Las labels y la retención son mutables; el nombre y el proyecto, no |
| Bucket de Cloud Storage | `gcloud storage buckets` | $0.00 vacío | La clase de almacenamiento y el versioning son mutables; **la location no** |
| Service account | `gcloud iam service-accounts` | $0.00 | El display name es mutable; el `accountId` del correo, no |
| Firewall rule | `gcloud compute firewall-rules` | $0.00 | Puertos, prioridad y tags son mutables; la red, no |
| Secret de Secret Manager | `gcloud secrets` | $0.00 dentro de la cuota | Las labels y la política de replicación *no* se cambian igual |

La rutina de este apéndice se muestra con el **topic de Pub/Sub**, porque es el recurso más
barato de todos —no cobra nada por existir, solo por mensajes— y porque su API es lo bastante
pequeña como para leerla entera de un vistazo. Cuando la repitas con otro, cambia el grupo de
comandos y no cambies nada más.

> 💡 **Truco.** Cuando llegue el momento de una entrevista, aplica la rutina **al servicio que
> más te intimide**. No al que ya dominas.

---

## 4. 🧱 Paso 1: crear

```bash
gcloud pubsub topics create inv-events \
  --labels=project=inv_lab \
  --message-retention-duration=1d
```

- `create inv-events` crea el topic. El nombre es único dentro del proyecto y **no se puede
  cambiar después** — eso ya es una respuesta al paso 3.
- `--labels=project=inv_lab` pone el label de rastreo del baseline del curso. Recuerda que los
  labels de GCP solo aceptan minúsculas, números, guiones y guiones bajos: por eso es
  `project=inv_lab` y no `Project=inv-lab`. No es preferencia de estilo, es lo que la API acepta.
- `--message-retention-duration=1d` fija cuánto tiempo guarda el topic los mensajes publicados
  para poder reproducirlos. Es un campo **mutable**, y por lo tanto el candidato natural del
  paso 3. Si lo omites, el topic no retiene mensajes más allá de lo que necesiten sus
  subscriptions.

La salida es de una línea y es engañosamente sencilla:

```text
Created topic [projects/inv-lab-472913/topics/inv-events].
```

Fíjate en el nombre entre corchetes: **el identificador real del recurso no es `inv-events`, es
`projects/inv-lab-472913/topics/inv-events`**. Ese formato —el *resource name* completo— es el
que espera la API, el que aparece en los mensajes de error y el que vas a necesitar en el paso 6.
`gcloud` te deja escribir la forma corta por comodidad; el SDK, muchas veces, no.

---

## 5. 🧱 Paso 2: inspeccionar con `--format=json`

Este es el paso que casi todo el mundo se salta, y es el que responde a la pregunta
*"¿qué atributos tiene este recurso de verdad?"*. La tabla que imprime `gcloud` por defecto
muestra los tres campos que alguien decidió que eran los interesantes. El JSON muestra el objeto
que devuelve la API.

```bash
gcloud pubsub topics describe inv-events --format=json
```

```text
{
  "labels": {
    "project": "inv_lab"
  },
  "messageRetentionDuration": "86400s",
  "messageStoragePolicy": {
    "enforceInTransit": false
  },
  "name": "projects/inv-lab-472913/topics/inv-events"
}
```

Tres cosas que sacar de aquí, y las tres se repiten en cualquier servicio:

- **La API normaliza tus valores.** Escribiste `1d` y el objeto guarda `86400s`. Cuando escribas
  el equivalente desde el SDK, el campo espera una duración, no la cadena que aceptó la CLI.
- **Aparecen campos que no pediste** (`messageStoragePolicy`). Son defaults que el servicio
  aplicó por ti, y saber que existen es medio camino para configurarlos cuando haga falta.
- **`name` es el resource name completo.** Otra vez.

Y ahora la parte útil: los nombres de campo de este JSON son exactamente los que van dentro de
`--format='value(...)'` y de `--filter`. Por eso el flujo correcto siempre es mirar el JSON
primero:

```bash
gcloud pubsub topics describe inv-events --format='value(messageRetentionDuration)'
```

```text
86400s
```

---

## 6. 🧱 Paso 3: modificar, y encontrar la frontera inmutable

El paso tiene dos mitades y la segunda es la importante.

**Primero, un campo que sí se puede cambiar:**

```bash
gcloud pubsub topics update inv-events --message-retention-duration=7d
gcloud pubsub topics describe inv-events --format='value(messageRetentionDuration)'
```

```text
604800s
```

**Ahora uno que no.** Intenta cambiar el nombre, o el proyecto, o cualquier cosa que forme parte
de la identidad del recurso, y verás que **`gcloud` ni siquiera te ofrece el flag**. Esa ausencia
es la respuesta: no es que la operación falle, es que no existe. Para "renombrar" un topic hay que
crear otro y borrar el primero.

En otros servicios el límite se manifiesta como un error explícito. En un bucket, por ejemplo:

```bash
gcloud storage buckets update gs://inv-lab-data-472913 --location=EU
```

```text
ERROR: (gcloud.storage.buckets.update) unrecognized arguments: --location=EU
```

> 🧠 **Modelo mental.** Cada recurso tiene una frontera entre lo que se puede cambiar en sitio y
> lo que obliga a recrearlo. **Es exactamente la misma frontera que Terraform marca como
> `# forces replacement`** en un plan. Verla desde los dos lados —el error de la API y el plan de
> Terraform— es lo que fija el concepto, y es una de las respuestas que más rápido distingue a
> alguien que ha operado de alguien que ha leído.

Vale la pena anotar, para el recurso que estés practicando, dos listas cortas: *mutable* e
*inmutable*. Esa nota es material de repaso de primera calidad y no la vas a encontrar hecha en
ninguna documentación.

---

## 7. 🧱 Paso 4: destruir

```bash
gcloud pubsub topics delete inv-events
```

```text
Deleted topic [projects/inv-lab-472913/topics/inv-events].
```

Dos cosas que conviene provocar aquí, porque son las que enseñan:

**Borrar algo de lo que otra cosa depende.** Si el topic tiene una subscription, el borrado
funciona igual, pero la subscription queda en un estado huérfano y sigue existiendo. Ese es el
patrón general que hay que buscar en cada recurso: *¿el borrado es en cascada o deja hijos?* La
respuesta cambia por servicio y casi nunca está en el sitio donde la buscas.

**Borrar dos veces.**

```bash
gcloud pubsub topics delete inv-events
```

```text
ERROR: (gcloud.pubsub.topics.delete) NOT_FOUND: Resource not found (resource=inv-events).
```

Parece una tontería y no lo es: en el paso 6 vas a tener que decidir qué hace tu código cuando el
recurso ya no está. Un script de teardown que revienta porque algo ya estaba borrado es un script
de teardown que nadie vuelve a ejecutar.

> ⚠️ **`--quiet` en un `delete` no pregunta.** Es lo correcto dentro de un script y es peligroso
> a mano. La combinación `gcloud ... delete --quiet` con el proyecto equivocado activo es la
> forma más rápida de tener una tarde mala 😉.

---

## 8. 🧱 Paso 5: verificar qué quedó vivo

El paso que convierte la rutina en algo serio. No basta con que el `delete` haya dicho que sí:

```bash
gcloud pubsub topics list --format='table(name)'
gcloud pubsub subscriptions list --format='table(name, topic)'
```

La segunda línea es la que importa, y responde a la pregunta del paso 4. Si el topic se borró y
la subscription sigue ahí apuntando a `_deleted-topic_`, acabas de descubrir de primera mano que
el borrado **no** fue en cascada.

Para un barrido de verdad, el que no depende de que te acuerdes de qué creaste:

```bash
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --format='table(assetType, name)'
```

Cloud Asset Inventory ve todos los tipos de recurso, lleven o no tus labels. El catálogo completo
de qué sobrevive a qué borrado está en
[`A02` §5](a02-costos-trampas-y-recursos-huerfanos.md#5--el-catálogo-de-huérfanos-qué-sobrevive-a-qué-borrado),
y el barrido completo en [`L08`](l08-costos-y-destruccion-verificada.md).

---

## 9. 🧪 Paso 6: lo mismo desde el SDK

Aquí está el aprendizaje. Antes de escribir una línea, dos preparativos.

**Las credenciales.** Tu código no usa la credencial de `gcloud`: usa las Application Default
Credentials. Si no las tienes puestas, el script falla y ese fallo es didáctico — es la
diferencia entre `gcloud auth login` y `gcloud auth application-default login` volviéndose una
excepción en tu terminal.

```bash
gcloud auth application-default login
pip install google-cloud-pubsub
```

**El código.** Los seis pasos, en el mismo orden:

```python
import os
from google.cloud import pubsub_v1
from google.api_core.exceptions import AlreadyExists, NotFound

project_id = os.environ["GOOGLE_CLOUD_PROJECT"]
client = pubsub_v1.PublisherClient()

# el resource name completo: exactamente lo que viste en el paso 2
topic_path = client.topic_path(project_id, "inv-events")

# 1. crear — idempotente a mano, porque la API no lo es
try:
    topic = client.create_topic(request={"name": topic_path, "labels": {"project": "inv_lab"}})
    print("creado:", topic.name)
except AlreadyExists:
    print("ya existía:", topic_path)

# 2. inspeccionar
topic = client.get_topic(request={"topic": topic_path})
print("retención:", topic.message_retention_duration)

# 3. modificar — hay que decir QUÉ campos se actualizan, con una update mask
from google.protobuf.duration_pb2 import Duration
from google.protobuf.field_mask_pb2 import FieldMask

topic.message_retention_duration = Duration(seconds=604800)
client.update_topic(request={
    "topic": topic,
    "update_mask": FieldMask(paths=["message_retention_duration"]),
})

# 4. destruir — tolerante a que ya no esté
try:
    client.delete_topic(request={"topic": topic_path})
    print("borrado")
except NotFound:
    print("no existía")

# 5. verificar
restantes = [t.name for t in client.list_topics(request={"project": f"projects/{project_id}"})]
print("quedan:", restantes)
```

Lo que hay que mirar de ese fragmento, línea por línea:

- **`client.topic_path(...)`** construye `projects/<id>/topics/inv-events`. La API no acepta la
  forma corta que `gcloud` te dejaba escribir. Ese detalle solo lo aprendes aquí.
- **`AlreadyExists` y `NotFound`** son excepciones de `google.api_core`, comunes a todas las
  librerías `google-cloud-*`. La idempotencia que `gcloud` te regalaba con un mensaje amable la
  escribes tú.
- **La `update_mask`** es el concepto que más sorprende. La API no infiere qué cambiaste: le
  pasas el objeto entero **y una lista de los campos que debe tomar en cuenta**. Sin la máscara,
  o no cambia nada o cambia más de lo que querías. En `gcloud` esto estaba escondido detrás de
  cada flag `--algo`, que internamente añadía ese campo a la máscara.
- **`list_topics` devuelve un iterador paginado**, no una lista. Materializarlo con un `for` o
  un `list()` es lo que dispara las llamadas siguientes. Es la razón de que un `len()` sobre el
  resultado a veces no compile y otras veces mienta.

> ⚠️ **Lo que este ejemplo no muestra, porque Pub/Sub es de los rápidos: la espera.** En la
> mayoría de los servicios, `create` y `delete` devuelven una **Operation**, no el recurso — ver
> §11.

---

## 10. 🩺 El puente: `--log-http`

¿De dónde salió el nombre exacto del método, la forma del cuerpo y el campo `update_mask`? No de
buscar en la documentación del SDK: de mirar qué hace el comando que ya sabías escribir.

```bash
gcloud pubsub topics create inv-events --log-http
```

```text
=======================
==== request start ====
uri: https://pubsub.googleapis.com/v1/projects/inv-lab-472913/topics/inv-events?alt=json
method: PUT
== headers start ==
Authorization: Bearer ...
== headers end ==
== body start ==
{"labels": {"project": "inv_lab"}}
== body end ==
==== request end ====
---- response start ----
status: 200
-- body start --
{
  "name": "projects/inv-lab-472913/topics/inv-events",
  "labels": {"project": "inv_lab"}
}
-- body end --
```

Con eso delante ya sabes todo lo que necesitas para escribir el paso 6, sin buscar nada:

- **El endpoint**: `pubsub.googleapis.com`, versión `v1`. Es el que va a usar la librería.
- **El método HTTP**: `PUT` sobre la ruta del recurso. Por eso `create_topic` recibe un `name` y
  no un `parent` + `id` como otros servicios — la API modela la creación como "pon este recurso
  en esta ruta".
- **El cuerpo**: lo que va dentro del objeto. Los campos que ves aquí son los que la librería
  espera, con el mismo nombre en `snake_case`.
- **La respuesta**: si devuelve el recurso, no hay operación que esperar. Si devolviera un objeto
  con `"name": "operations/..."` y `"done": false`, sí la habría, y §11 explica qué hacer.

> ⚠️ La salida de `--log-http` incluye tu token de autorización en el header `Authorization`. No
> la pegues en un issue, en un chat ni en un repositorio sin recortarla.

> 💡 **Truco.** Cuando la documentación del SDK y la de la API se contradigan —pasa—, `--log-http`
> es el desempate: te enseña lo que el servicio realmente acepta hoy.

---

## 11. 🧪 Las tres lecciones que solo da el paso 6

Son las tres cosas que ningún documento teórico transmite igual de bien, y las tres son
preguntas de entrevista.

**Las operaciones de larga duración.** Casi todo `create` y `delete` en GCP devuelve una
`Operation`, no el recurso: un objeto que dice "esto está en curso". `gcloud` hace polling por ti
—salvo que le pases `--async`— y por eso *parece* síncrono. Desde el SDK la espera es tuya:

```python
operation = client.create_instance(request=...)   # devuelve una Operation, no la instancia
result = operation.result(timeout=300)            # ESTA línea es la que espera de verdad
```

Olvidar ese `.result()` es el primer sitio donde se rompe el código de quien pasó de la CLI a la
librería: el programa sigue adelante creyendo que el recurso ya existe, y la siguiente llamada
falla con un `NOT_FOUND` que no tiene ningún sentido aparente.

**De dónde saca credenciales tu código.** Ya lo sufriste al principio del paso 6. La regla, en
orden: la variable `GOOGLE_APPLICATION_CREDENTIALS` si está puesta, el archivo de ADC del
usuario, y —dentro de GCP— la identidad que la plataforma le entrega al proceso a través del
metadata server. Ese tercer caso es la razón de que el mismo código funcione en Cloud Run **sin
ninguna clave**, y de que descargar una key de service account casi nunca sea necesario.

**Qué campo es mutable.** El paso 3 te lo enseñó desde la CLI; el SDK te lo enseña como un error
de la API cuando intentas actualizar un campo que no admite actualización, o como una `update_mask`
que el servicio ignora en silencio. Es, otra vez, la misma frontera que Terraform llama
`must be replaced`.

---

## 12. 🧭 El entregable no es el recurso

Al terminar la vuelta no queda nada encendido — ese es el punto. Lo que queda es lo que
escribiste:

- **El script de `gcloud`** con los seis pasos, comentado: qué hace cada flag y por qué está.
- **El fragmento de SDK** equivalente, con las tres notas del §11 donde correspondan.
- **Las dos listas del paso 3**: campos mutables y campos que obligan a recrear.
- **La sorpresa del paso 5**, si la hubo: qué quedó vivo que no esperabas.

Eso vale como material de repaso, vale como respuesta larga en una entrevista y vale como
portafolio. Si vas a hacer más de dos o tres vueltas, ponlo en un repositorio: lo que produce
esta rutina es exactamente material presentable.

---

## 📋 Checklist de salida

- [ ] `gcloud config list` confirma el proyecto y la región correctos antes de empezar.
- [ ] El paso 2 se hizo con `--format=json` y anotaste al menos un campo que no habías pedido.
- [ ] El paso 3 encontró **un campo mutable y uno inmutable**, con el error o la ausencia de flag como prueba.
- [ ] Provocaste a propósito el borrado doble y sabes qué excepción devuelve.
- [ ] El paso 5 salió vacío, o explicaste por qué no.
- [ ] El fragmento de SDK corre de principio a fin sin credenciales descargadas: solo ADC.
- [ ] Guardaste la salida de `--log-http` **con el header `Authorization` recortado**.
- [ ] `gcloud asset search-all-resources --scope=projects/inv-lab-472913` no devuelve el recurso de la práctica.

## 🏁 La señal de que quedó bien

Puedes explicarle a otra persona, sin abrir la documentación, qué llamada REST hace el comando
que escribiste, qué campo de ese recurso obliga a recrearlo y qué línea de tu código es la que
espera de verdad a que la operación termine.

---

## 🧠 Preguntas rápidas

1. ¿Por qué el paso 2 se hace con `--format=json` y no con la salida por defecto?
2. ¿Qué es el *resource name* completo de un recurso y en qué se diferencia de lo que escribes en `gcloud`?
3. Escribiste `--message-retention-duration=1d` y el JSON dice `86400s`. ¿Qué te enseña eso sobre el paso 6?
4. ¿Cómo se manifiesta un campo inmutable desde `gcloud`, y cómo desde Terraform?
5. En el paso 4, ¿qué dos cosas hay que provocar a propósito: sobre las dependencias del recurso y sobre el borrado repetido?
6. ¿Qué es una `update_mask` y por qué en `gcloud` no la escribiste nunca?
7. ¿Por qué `list_*` en el SDK no devuelve una lista, y qué consecuencia tiene?
8. ¿Qué tres cosas te dice `--log-http` que necesitas para escribir el equivalente en código?
9. ¿Qué precaución hay que tomar antes de compartir una salida de `--log-http`?
10. ¿Por qué un `create` desde el SDK necesita una línea que desde `gcloud` no hizo falta escribir?
11. ¿De dónde saca credenciales tu código dentro de Cloud Run, y por qué eso hace innecesaria una key descargada?
12. ¿Qué queda al terminar una vuelta de la rutina, si no queda ningún recurso?

---

## 📚 Referencias oficiales

- Referencia de `gcloud` y flags globales: https://cloud.google.com/sdk/gcloud/reference
- Formatos de salida (`gcloud topic formats`): https://cloud.google.com/sdk/gcloud/reference/topic/formats
- `gcloud pubsub topics`: https://cloud.google.com/sdk/gcloud/reference/pubsub/topics
- API REST de Pub/Sub (`projects.topics`): https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.topics
- Librerías cliente de Google Cloud: https://cloud.google.com/apis/docs/cloud-client-libraries
- Librería cliente de Pub/Sub para Python: https://cloud.google.com/python/docs/reference/pubsub/latest
- Credenciales predeterminadas de la aplicación (ADC): https://cloud.google.com/docs/authentication/application-default-credentials
- Proporcionar credenciales para ADC: https://cloud.google.com/docs/authentication/provide-credentials-adc
- Operaciones de larga duración en las APIs de Google Cloud: https://google.aip.dev/151
- Máscaras de actualización en las APIs de Google (`update_mask`): https://google.aip.dev/134
- Nombres de recurso en las APIs de Google: https://google.aip.dev/122
- Restricciones de labels en Google Cloud: https://cloud.google.com/resource-manager/docs/labels-overview
- Buscar recursos con Cloud Asset Inventory: https://cloud.google.com/asset-inventory/docs/searching-resources
- Reintentos y manejo de errores en las librerías cliente: https://cloud.google.com/storage/docs/retry-strategy
