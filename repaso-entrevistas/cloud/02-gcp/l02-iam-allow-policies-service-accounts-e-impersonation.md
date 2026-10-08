# L02 — IAM: allow policies, service accounts e impersonation

> **Objetivo:** entender cómo se evalúa un permiso en GCP —dónde vive el binding, cómo se hereda,
> qué contiene un rol— y salir del lab capaz de diagnosticar un `PERMISSION_DENIED` con una
> herramienta en vez de con `roles/owner`.
> **Se asume leído:** [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md). Rinde mucho
> más con [`05`](05-seguridad-iam-jerarquia-kms-secretos.md) leído.
> **Costo:** **$0.00**. Service accounts, roles, bindings y un topic de Pub/Sub no cobran nada
> por existir.
> **Duración:** 2–3 horas.
> **Prerrequisitos:** [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) completo. Configuración `inv-lab` activa y APIs habilitadas.
> **Qué queda encendido al terminar:** las tres service accounts del lab (`inv-api-sa`,
> `inv-projector-sa`, `inv-pubsub-sa`) y un rol personalizado. **Ningún recurso que cobre, y
> ninguna key descargada.**
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [El problema](#1--el-problema-que-resuelve-este-lab) ·
[Cómo se evalúa un permiso](#2--cómo-se-evalúa-un-permiso) ·
[Leer una allow policy](#3--leer-una-allow-policy-de-verdad) ·
[Service accounts](#4--una-service-account-por-carga-de-trabajo) ·
[El binding en el recurso equivocado](#5--el-experimento-central-el-binding-en-el-recurso-equivocado) ·
[Policy Troubleshooter](#6--diagnosticar-sin-adivinar-policy-troubleshooter) ·
[Roles personalizados](#7--roles-predefinidos-frente-a-personalizados) ·
[Impersonation](#8--impersonation-en-vez-de-descargar-una-key) ·
[Herencia](#9--herencia-si-tienes-organization) ·
[Deny policies](#10--deny-policies-lo-que-una-allow-policy-no-puede-hacer) ·
[Teardown](#11--teardown-de-este-lab) ·
[Checklist](#-checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 El problema que resuelve este lab

Vas a desplegar un servicio que escribe en Firestore. Le das a su service account el rol
`roles/datastore.user`, despliegas, y el servicio devuelve un 403. Revisas: el rol está. Vuelves
a mirar: sigue estando. Después de veinte minutos le pones `roles/editor` "para salir del paso",
funciona, y sigues adelante.

Eso es exactamente lo que este lab existe para que no vuelva a pasar. No porque `roles/editor`
sea un pecado moral, sino porque **no aprendiste qué estaba mal** y en la siguiente entrevista no
vas a poder explicarlo.

> ⚠️ **El anti-patrón, nombrado sin piedad:** conceder `roles/owner` o `roles/editor` para
> desbloquear. Funciona siempre y no enseña nada. Si un `PERMISSION_DENIED` se arregla así, no lo
> arreglaste: lo tapaste.

IAM es, además, la mitad de las preguntas difíciles de una entrevista de GCP. No porque sea
conceptualmente complicado, sino porque tiene cuatro o cinco detalles que solo se aprenden
tropezando: dónde vive el binding, qué contiene un rol de verdad, quién es el service agent que
apareció solo, y por qué la respuesta correcta a "¿cómo pruebo los permisos de una SA?" no
incluye la palabra *descargar*.

---

## 2. 🧱 Cómo se evalúa un permiso

Tres piezas y una regla.

```text
PRINCIPAL          ROL                          RECURSO
quién              qué puede hacer              sobre qué
─────────          ────────────────             ────────────────
user:ana@…         roles/datastore.user         projects/inv-lab-472913
serviceAccount:…   roles/run.invoker            .../services/inv-projector
group:devs@…       roles/storage.objectViewer   gs://inv-lab-data-472913

        BINDING = (rol, lista de principals)
        ALLOW POLICY = lista de bindings, adjunta a UN recurso
```

Y la regla, que es la frase que hay que poder decir en voz alta:

> 🧠 **Modelo mental.** Una **allow policy** se adjunta a un recurso y contiene bindings. Las
> policies **se heredan hacia abajo** por la jerarquía —Organization → Folder → Project →
> recurso— y son **aditivas**: lo que puedes hacer sobre un recurso es la **unión** de todo lo
> que te concedieron en él y por encima de él.

De esa regla salen las tres consecuencias que producen el 90 % de los `PERMISSION_DENIED` de la
serie:

- **No hay deny dentro de una allow policy.** No puedes "quitar" en el proyecto un rol concedido
  en la organización. Para denegar existen las **IAM Deny policies**, que son otro objeto (§10).
- **El sitio del binding importa.** Un rol concedido en el proyecto aplica a todos los recursos
  del proyecto; el mismo rol concedido en un recurso aplica solo a ese. Los dos "funcionan", y
  uno de los dos es privilegio mínimo.
- **Un rol es un paquete de permisos atómicos**, y el nombre engaña. `roles/storage.objectViewer`
  no incluye `storage.buckets.get`, por mucho que "ver objetos" suene a que debería.

---

## 3. 🩺 Leer una allow policy de verdad

Empieza mirando lo que ya tienes:

```bash
gcloud projects get-iam-policy inv-lab-472913 --format=json
```

```text
{
  "bindings": [
    {
      "members": ["user:tu-cuenta@gmail.com"],
      "role": "roles/owner"
    }
  ],
  "etag": "BwYh0mR3lFo=",
  "version": 1
}
```

Dos campos que no pediste y que conviene entender:

- **`etag`** es un control de concurrencia. Cuando modificas una policy con `set-iam-policy`,
  envías el `etag` que leíste; si alguien la cambió mientras tanto, el servidor rechaza tu
  escritura en vez de pisarla. Es la razón de que exista `add-iam-policy-binding` como comando
  aparte: hace el ciclo leer-modificar-escribir por ti, con reintentos.
- **`version`** indica si la policy usa condiciones IAM. `1` significa que no.

La forma cruda es ilegible en cuanto hay más de tres bindings, porque cada uno tiene una lista de
miembros. `--flatten` la aplana a una fila por par:

```bash
gcloud projects get-iam-policy inv-lab-472913 \
  --flatten='bindings[].members[]' \
  --format='table(bindings.role, bindings.members)'
```

- `bindings[]` aplana la lista de bindings; `members[]` aplana, dentro de cada uno, la lista de
  miembros.
- Después de aplanar, los campos se nombran **en singular y sin corchetes**: `bindings.role`, no
  `bindings[].role`. Es el detalle que hace fallar el comando la primera vez.

Y la pregunta que de verdad quieres hacer —"¿qué tiene *este* principal?"— se responde
filtrando:

```bash
gcloud projects get-iam-policy inv-lab-472913 \
  --flatten='bindings[].members[]' \
  --filter='bindings.members:inv-api-sa' \
  --format='value(bindings.role)'
```

> 🩺 **Diagnóstico.** Ese comando responde *"¿qué roles tiene esta identidad **en el
> proyecto**?"*. Ojo con el "en el proyecto": si el binding está en un recurso concreto, **aquí no
> aparece**. Esa distinción es el experimento de §5 y la trampa central del lab.

---

## 4. 🧱 Una service account por carga de trabajo

Antes de crear nada, la distinción que hay que tener clara:

| | Principal humano | Service account |
|---|---|---|
| Qué es | Una persona con cuenta de Google | Una identidad **para código**, sin contraseña |
| Cómo se autentica | Navegador, MFA | Token firmado, impersonation, o el metadata server |
| Formato | `user:ana@empresa.com` | `serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com` |
| Es también un recurso | No | **Sí** — y por eso tiene su propia allow policy |

Esa última fila es la que sorprende y la que hace posible la impersonation de §8: una service
account es a la vez **una identidad** (puede aparecer como miembro de un binding) y **un
recurso** (puede tener bindings adjuntos que digan quién puede actuar en su nombre).

**Teardown antes de crear:** estas tres cuentas se borran con
`gcloud iam service-accounts delete <email>` y no cobran nada por existir, así que pueden quedarse
toda la serie.

```bash
gcloud iam service-accounts create inv-api-sa \
  --display-name="Inventario — API" \
  --description="Identidad del servicio inv-api de Cloud Run"

gcloud iam service-accounts create inv-projector-sa \
  --display-name="Inventario — Projector" \
  --description="Identidad del servicio inv-projector de Cloud Run"

gcloud iam service-accounts create inv-pubsub-sa \
  --display-name="Inventario — Pub/Sub push" \
  --description="Identidad con la que Pub/Sub firma los tokens OIDC de las push subscriptions"
```

- El primer argumento es el **`accountId`**, la parte antes de la `@`. Es inmutable: el correo
  resultante ya no cambia. `--display-name` sí se puede cambiar después.
- El correo completo lo compone GCP:
  `<accountId>@<projectId>.iam.gserviceaccount.com`. Fíjate en que lleva el **`projectId`**, no
  el número — al revés que los service agents, que llevan el `projectNumber`.
- **Crear una service account no le da ningún permiso.** Recién creada no puede hacer
  absolutamente nada. Es el estado correcto: los permisos se conceden después, uno a uno.

```bash
gcloud iam service-accounts list --format='table(displayName, email, disabled)'
```

> 🧭 **Regla de arquitectura.** Una service account **por carga de trabajo**, no una por
> proyecto. No es purismo: es la única forma de que el informe de auditoría diga *qué* servicio
> hizo algo, y de que un servicio comprometido no traiga los permisos de los otros dos. En
> [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) verás la alternativa por defecto —la service account de Compute Engine, que suele venir
> con `roles/editor` sobre todo el proyecto— y por qué el lab la evita.

---

## 5. 🩺 El experimento central: el binding en el recurso equivocado

Este es el corazón del lab. Se provoca el error a propósito, se confirma con un comando y solo
después se corrige.

**Montaje.** Un topic de prueba, que existe solo para este experimento:

```bash
gcloud pubsub topics create inv-lab-iam-demo --labels=project=inv_lab
```

**Teardown de este recurso:** `gcloud pubsub topics delete inv-lab-iam-demo`, al final de §6. No
cobra nada, pero no tiene por qué sobrevivir al lab.

**Paso 1 — el binding en el sitio equivocado.** Quieres que `inv-api-sa` pueda publicar en *ese*
topic. Le das el rol… en la service account:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  inv-api-sa@inv-lab-472913.iam.gserviceaccount.com \
  --member="serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com" \
  --role=roles/pubsub.publisher
```

El comando **funciona**. Devuelve la policy actualizada sin una sola queja. Y no sirve para nada:
acabas de decir "sobre el recurso *service account inv-api-sa*, esta identidad tiene el rol de
publicador de Pub/Sub". El recurso sobre el que quieres publicar es el topic, no la cuenta.

> 🧠 **Modelo mental.** GCP **no valida que un rol tenga sentido sobre el recurso al que se lo
> pegas.** Puedes conceder `roles/pubsub.publisher` sobre un bucket y nadie te dirá nada. El
> binding se guarda, no hace nada, y tú te quedas con la certeza falsa de que "el rol está
> puesto". Es la causa número uno de los `PERMISSION_DENIED` que no se explican.

**Paso 2 — reproducir el fallo.** Intenta publicar con esa identidad, sin descargar ninguna key:

```bash
gcloud pubsub topics publish inv-lab-iam-demo \
  --message='{"sku":"ABC-1","delta":-3}' \
  --impersonate-service-account=inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
```

```text
ERROR: (gcloud.pubsub.topics.publish) PERMISSION_DENIED: User not authorized to perform this action.
```

- `--impersonate-service-account` es un **flag global**: pide un token de corta duración en
  nombre de esa cuenta y ejecuta el comando con su identidad. Es lo que sustituye a descargar una
  key (§8).
- Si este comando te falla con un error que menciona `generateAccessToken` en vez del de arriba,
  el problema es otro y va en §8: te falta el rol para poder impersonar.

**Paso 3 — confirmar la hipótesis antes de tocar nada.**

```bash
# ¿tiene el rol en el proyecto?
gcloud projects get-iam-policy inv-lab-472913 \
  --flatten='bindings[].members[]' \
  --filter='bindings.members:inv-api-sa' \
  --format='value(bindings.role)'
```

```text
Listed 0 items.
```

```bash
# ¿y en el topic, que es el recurso que importa?
gcloud pubsub topics get-iam-policy inv-lab-iam-demo --format=json
```

```text
{}
```

Una policy vacía. Ahí está: el rol existe, pero adjunto a un recurso que no participa en esta
operación.

**Paso 4 — la corrección, en el recurso correcto.**

```bash
gcloud pubsub topics add-iam-policy-binding inv-lab-iam-demo \
  --member="serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com" \
  --role=roles/pubsub.publisher
```

- `gcloud pubsub topics add-iam-policy-binding` —fíjate en el grupo de comandos— adjunta el
  binding **a la allow policy del topic**. Es el mismo verbo que antes sobre otro recurso, y esa
  es toda la diferencia.

```bash
gcloud pubsub topics publish inv-lab-iam-demo \
  --message='{"sku":"ABC-1","delta":-3}' \
  --impersonate-service-account=inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
```

```text
messageIds:
- '13058950528021'
```

**Paso 5 — y ahora la comparación que cierra el concepto.** Deshaz el binding del topic y ponlo
en el proyecto:

```bash
gcloud pubsub topics remove-iam-policy-binding inv-lab-iam-demo \
  --member="serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com" \
  --role=roles/pubsub.publisher

gcloud projects add-iam-policy-binding inv-lab-472913 \
  --member="serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com" \
  --role=roles/pubsub.publisher
```

Publica otra vez: **también funciona**. Las dos formas resuelven el error, y una de las dos es la
correcta.

```text
binding en el TOPIC      → puede publicar en ESE topic
binding en el PROYECTO   → puede publicar en TODOS los topics del proyecto,
                           incluidos los que crees dentro de seis meses
```

Deja el del proyecto quitado y vuelve a poner el del topic, que es lo que enseña el lab:

```bash
gcloud projects remove-iam-policy-binding inv-lab-472913 \
  --member="serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com" \
  --role=roles/pubsub.publisher
```

> 🧭 **Regla de entrevista.** *"¿Dónde pones el binding?"* — **en el recurso más específico
> donde la operación tenga sentido**. Subirlo al proyecto es cómodo, funciona igual hoy, y
> concede en silencio permiso sobre todo lo que crees mañana.

---

## 6. 🩺 Diagnosticar sin adivinar: Policy Troubleshooter

El experimento anterior lo resolviste mirando dos policies. Con seis recursos y herencia de por
medio eso deja de escalar, y GCP tiene un servicio dedicado exactamente a esta pregunta.

```bash
gcloud policy-troubleshoot iam projects/inv-lab-472913 \
  --principal-email=inv-api-sa@inv-lab-472913.iam.gserviceaccount.com \
  --permission=pubsub.topics.publish
```

- **El primer argumento es el recurso** sobre el que se evalúa el acceso, en formato de nombre
  completo.
- `--principal-email` es quién intenta la acción.
- `--permission` es el **permiso atómico**, no el rol: `pubsub.topics.publish`, no
  `roles/pubsub.publisher`. El permiso exacto siempre aparece en el mensaje de error, y es de
  donde hay que copiarlo.

La respuesta no es un sí o un no: es **qué policy se evaluó en cada nivel de la jerarquía y por
qué el resultado fue el que fue**. Eso es lo que convierte un diagnóstico en una explicación, y
es exactamente lo que te van a pedir en una entrevista cuando te pregunten cómo depurarías un
403.

**La pregunta inversa** —"¿qué permisos tiene este rol de verdad?"— también tiene comando, y
sirve para no volver a suponer que `objectViewer` incluye `buckets.get`:

```bash
gcloud iam roles describe roles/pubsub.publisher \
  --format='value(includedPermissions)'
```

```text
pubsub.topics.publish
```

Un solo permiso. Compáralo con lo que trae un rol amplio:

```bash
gcloud iam roles describe roles/editor \
  --format='value(includedPermissions)' | tr ';' '\n' | wc -l
```

Ese número —miles de permisos— es el argumento entero contra "le pongo editor y listo".

**Limpieza del experimento:**

```bash
gcloud pubsub topics delete inv-lab-iam-demo
```

---

## 7. ⚖ Roles predefinidos frente a personalizados

GCP trae tres familias, y conviene saber cuándo se usa cada una:

| Familia | Ejemplo | Cuándo |
|---|---|---|
| Básicos (legacy) | `roles/owner`, `roles/editor`, `roles/viewer` | Casi nunca. Anteriores a IAM y absurdamente amplios |
| Predefinidos | `roles/run.invoker`, `roles/datastore.user` | El caso normal. Google los mantiene al día cuando salen permisos nuevos |
| Personalizados | `projects/…/roles/invLabPublisher` | Cuando ningún predefinido encaja sin conceder de más |

El costo del rol personalizado es real y hay que decirlo: **eres tú quien lo mantiene**. Si
Google añade un permiso nuevo a una API, el predefinido lo recibe y el tuyo no. Por eso la
recomendación por defecto es predefinido, y el personalizado se reserva para cuando la diferencia
importa.

Aquí sí importa, y sirve de ejercicio:

```bash
gcloud iam roles create invLabPublisher \
  --project=inv-lab-472913 \
  --title="Inventario — solo publicar" \
  --description="Publicar en topics del lab, sin poder listarlos ni borrarlos" \
  --permissions=pubsub.topics.publish \
  --stage=GA
```

- El ID del rol va en **camelCase** y es inmutable.
- `--permissions` es la lista de permisos atómicos, separados por coma. Los nombres salen de
  `gcloud iam roles describe` sobre los predefinidos parecidos.
- `--stage` marca la madurez (`ALPHA`, `BETA`, `GA`, `DEPRECATED`). Es informativo, pero un rol
  en `ALPHA` recuerda a quien lo lea que puede cambiar.
- **Un rol personalizado vive en un proyecto o en una organización**, no suelto. El del lab es
  `projects/inv-lab-472913/roles/invLabPublisher` y muere con el proyecto.

**Teardown:** `gcloud iam roles delete invLabPublisher --project=inv-lab-472913`. Ojo: el borrado
de un rol personalizado es **reversible durante 7 días** (queda deshabilitado antes de
desaparecer del todo), lo que es útil y a la vez explica que su ID no se pueda reutilizar de
inmediato.

---

## 8. 🧱 Impersonation en vez de descargar una key

Ya la usaste en §5 sin explicación. Ahora la explicación, porque es una de las respuestas que más
rápido separan a alguien que ha operado GCP de alguien que ha leído sobre él.

**El instinto** es crear una key JSON de la service account, descargarla y exportar
`GOOGLE_APPLICATION_CREDENTIALS`. Es lo que hace medio Internet.

> ⚠️ **Una key descargada es una credencial de larga duración, sin rotación, en tu disco, en tus
> backups y probablemente en el historial de tu shell.** Es el hallazgo número uno de cualquier
> auditoría. Hay una Organization Policy dedicada a prohibirlas
> (`constraints/iam.disableServiceAccountKeyCreation`), y el curso **no descarga ninguna key en
> ningún lab**.

**La alternativa nativa.** Tu identidad humana pide un token de corta duración *en nombre de* la
service account. Para que funcione hace falta un binding, y fíjate dónde va:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  inv-api-sa@inv-lab-472913.iam.gserviceaccount.com \
  --member="user:tu-cuenta@gmail.com" \
  --role=roles/iam.serviceAccountTokenCreator
```

- El binding va **sobre la service account**, no sobre el proyecto. Aquí la SA actúa como
  *recurso*: su allow policy dice quién puede actuar en su nombre. Es el mejor ejemplo de la
  dualidad identidad/recurso de §4.
- Concedido a nivel proyecto, ese mismo rol te dejaría impersonar **todas** las service accounts
  del proyecto. Otra vez la lección de §5.

A partir de ahí, cualquier comando:

```bash
gcloud pubsub topics list \
  --impersonate-service-account=inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
```

Y para que lo haga **tu código**, sin cambiar una línea del código:

```bash
gcloud auth application-default login \
  --impersonate-service-account=inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
```

Escribe un archivo de ADC que, en lugar de una clave, contiene la instrucción de impersonar.
Terraform y las librerías `google-cloud-*` lo entienden sin saber que existe.

> 💡 **Truco de entrevista.** *"¿Cómo pruebas los permisos de una service account?"* La respuesta
> mala es "me descargo la key". La buena: "la impersono con `--impersonate-service-account`, que
> me da un token de corta duración y **deja rastro en los Audit Logs con mi identidad**, no con la
> suya". Ese último detalle —la trazabilidad— es el que remata la respuesta.

---

## 9. 🧱 Herencia (si tienes Organization)

Si `gcloud organizations list` te devolvió cero en [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md), esta sección se lee y no se ejecuta: sin
organización no hay niveles por encima del proyecto y no hay herencia que observar. No te falta
nada del resto del lab.

Si sí la tienes, el experimento es corto y contundente. Concede un rol de solo lectura en la
organización:

```bash
gcloud organizations add-iam-policy-binding <ORG_ID> \
  --member="user:tu-cuenta@gmail.com" \
  --role=roles/browser
```

Y ahora busca ese rol en la policy del proyecto:

```bash
gcloud projects get-iam-policy inv-lab-472913 \
  --flatten='bindings[].members[]' \
  --filter='bindings.role:roles/browser' \
  --format='value(bindings.members)'
```

```text
Listed 0 items.
```

**No aparece, y sin embargo lo tienes.** Esa es la lección entera:

> 🧠 **Modelo mental.** `get-iam-policy` de un recurso devuelve **solo los bindings adjuntos a
> ese recurso**, nunca los heredados. El acceso efectivo es la unión de todos los niveles, y la
> única forma de verlo completo es una herramienta que recorra la jerarquía: Policy
> Troubleshooter (§6) o Policy Analyzer.

Ese detalle explica una escena entera: alguien mira la policy del proyecto, no ve el rol, lo
concede otra vez ahí, y ahora el mismo permiso está en dos sitios. Quitarlo del proyecto no lo
revoca, porque sigue heredado desde arriba.

Deshaz el experimento:

```bash
gcloud organizations remove-iam-policy-binding <ORG_ID> \
  --member="user:tu-cuenta@gmail.com" \
  --role=roles/browser
```

---

## 10. ⚖ Deny policies: lo que una allow policy no puede hacer

La pregunta natural después de §2 es: *"si las allow policies son aditivas y no tienen deny, ¿cómo
impido que alguien haga algo si ya se lo concedieron arriba?"*. La respuesta es un objeto
distinto.

```text
1. Se evalúan las DENY policies   →  si alguna deniega, se acabó
2. Se evalúan las ALLOW policies  →  unión de todos los niveles
```

Las **IAM Deny policies** se adjuntan a la organización, a un folder o a un proyecto, nombran
permisos (no roles) y **ganan siempre** sobre cualquier allow. Son la herramienta correcta para
un requisito del tipo "nadie, ni siquiera un owner, puede borrar buckets en este folder".

Este lab **no crea ninguna**, y la razón se dice en vez de esconderse: una deny policy mal puesta
te deja fuera de tu propio proyecto, y recuperarse de eso en una cuenta personal sin organización
es incómodo. Lo que sí hay que llevarse es el vocabulario y el orden de evaluación, porque es una
pregunta de entrevista frecuente y porque la confusión típica —"pongo un deny en la allow
policy"— revela de inmediato que quien responde no ha leído el modelo.

> 📝 **Contexto.** Los roles básicos (`owner`, `editor`, `viewer`) son anteriores a IAM tal como
> existe hoy, y sobreviven por compatibilidad. Que `roles/editor` siga apareciendo por defecto en
> algunos sitios —la service account de Compute Engine, sin ir más lejos— es historia, no diseño;
> y es la razón de que [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) insista en no usarla.

---

## 11. 🧹 Teardown de este lab

| Recurso | ¿Cobra? | Qué hacer |
|---|---|---|
| `inv-api-sa`, `inv-projector-sa`, `inv-pubsub-sa` | No | Se quedan: [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) y [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) las usan |
| Topic `inv-lab-iam-demo` | No | **Borrado ya** al final de §6 |
| Rol `invLabPublisher` | No | `gcloud iam roles delete invLabPublisher --project=inv-lab-472913` si no lo quieres |
| Binding de `serviceAccountTokenCreator` sobre `inv-api-sa` | No | Se queda: lo usas en toda la serie |
| Binding de `roles/browser` en la organización | No | **Quitado ya** en §9 |

Verificación:

```bash
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --format='table(assetType, name)'
```

```text
ASSET_TYPE                         NAME
pubsub.googleapis.com/Topic        //pubsub.googleapis.com/projects/inv-lab-472913/topics/inv-lab-budget
iam.googleapis.com/ServiceAccount  //iam.googleapis.com/projects/inv-lab-472913/serviceAccounts/inv-api-sa@…
iam.googleapis.com/ServiceAccount  //iam.googleapis.com/projects/inv-lab-472913/serviceAccounts/inv-projector-sa@…
iam.googleapis.com/ServiceAccount  //iam.googleapis.com/projects/inv-lab-472913/serviceAccounts/inv-pubsub-sa@…
```

Cuatro recursos, ninguno factura. Y una comprobación que no es opcional:

```bash
gcloud iam service-accounts keys list \
  --iam-account=inv-api-sa@inv-lab-472913.iam.gserviceaccount.com \
  --format='table(name, keyType, validAfterTime)'
```

Solo deben aparecer keys de tipo `SYSTEM_MANAGED` —las que Google rota por ti—. **Si aparece una
`USER_MANAGED`, la descargaste tú y hay que borrarla**, aquí y en tu disco.

---

## 📋 Checklist de salida

- [ ] Las tres service accounts existen y `disabled` es `False` en las tres.
- [ ] Ninguna tiene keys `USER_MANAGED`.
- [ ] Provocaste el `PERMISSION_DENIED` poniendo el binding en el recurso equivocado, y lo confirmaste con dos `get-iam-policy` antes de corregir.
- [ ] Publicaste en el topic con `--impersonate-service-account`, sin descargar ninguna key.
- [ ] Ejecutaste `gcloud policy-troubleshoot iam` al menos una vez y leíste su explicación por nivel.
- [ ] Sabes cuántos permisos trae `roles/editor` porque lo contaste.
- [ ] Creaste y describiste un rol personalizado, y puedes decir cuál es su costo de mantenimiento.
- [ ] El topic `inv-lab-iam-demo` está borrado.
- [ ] Puedes explicar, sin mirar, por qué un rol heredado de la organización no aparece en `get-iam-policy` del proyecto.

## 🏁 La señal de que quedó bien

El inventario del proyecto tiene cuatro recursos y ninguno factura; puedes ejecutar cualquier
comando como `inv-api-sa` sin que exista un solo archivo de credenciales en tu disco; y sabes
decir en una frase por qué el mismo rol concedido en dos sitios distintos resuelve el mismo error
y solo uno de los dos es correcto.

---

## 🧠 Preguntas rápidas

1. ¿Qué tres piezas componen un binding, y a qué se adjunta una allow policy?
2. ¿En qué dirección se heredan las allow policies y qué significa exactamente que sean aditivas?
3. ¿Puedes quitar en el proyecto un rol concedido en la organización? Si no, ¿qué objeto sirve para eso?
4. Concediste `roles/pubsub.publisher` sobre una service account en vez de sobre un topic. ¿Falla el comando? ¿Qué consecuencia tiene?
5. ¿Por qué `get-iam-policy` del proyecto no muestra un permiso que sí tienes?
6. ¿Qué diferencia hay entre poner `roles/run.invoker` en el proyecto y ponerlo en el servicio?
7. ¿Qué te da Policy Troubleshooter que no te dé un `get-iam-policy`, y qué le pasas: el rol o el permiso?
8. ¿Cómo averiguas qué permisos atómicos contiene un rol predefinido?
9. ¿En qué sentido una service account es a la vez una identidad y un recurso?
10. ¿Qué rol necesitas, y sobre qué recurso, para poder impersonar una service account?
11. ¿Por qué la impersonation es mejor respuesta que descargar una key, más allá de la seguridad del archivo?
12. ¿Cuál es el costo real de mantener un rol personalizado frente a usar uno predefinido?
13. ¿En qué orden se evalúan las deny policies y las allow policies?
14. ¿Qué tipo de key esperas ver en `service-accounts keys list` y cuál es señal de alarma?
15. ¿Por qué el curso evita la service account por defecto de Compute Engine?

---

## 📚 Referencias oficiales

- Descripción general de IAM: https://cloud.google.com/iam/docs/overview
- Allow policies y cómo se evalúan: https://cloud.google.com/iam/docs/policies
- Herencia de políticas y jerarquía de recursos: https://cloud.google.com/iam/docs/resource-hierarchy-access-control
- Roles básicos, predefinidos y personalizados: https://cloud.google.com/iam/docs/understanding-roles
- Crear y administrar roles personalizados: https://cloud.google.com/iam/docs/creating-custom-roles
- Referencia de permisos de IAM: https://cloud.google.com/iam/docs/permissions-reference
- Service accounts: https://cloud.google.com/iam/docs/service-account-overview
- Prácticas recomendadas para service accounts: https://cloud.google.com/iam/docs/best-practices-service-accounts
- Suplantación de identidad de service accounts: https://cloud.google.com/iam/docs/service-account-impersonation
- Riesgos de las claves de service account: https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys
- Service agents: https://cloud.google.com/iam/docs/service-agents
- IAM Deny policies: https://cloud.google.com/iam/docs/deny-overview
- Policy Troubleshooter: https://cloud.google.com/policy-intelligence/docs/troubleshoot-access
- Policy Analyzer: https://cloud.google.com/policy-intelligence/docs/policy-analyzer-overview
- Solución de problemas de acceso: https://cloud.google.com/iam/docs/troubleshooting-access
- Organization Policy Service: https://cloud.google.com/resource-manager/docs/organization-policy/overview
- Restricciones de Organization Policy: https://cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints
- Control de acceso en Pub/Sub: https://cloud.google.com/pubsub/docs/access-control
