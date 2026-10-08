# A01 — `gcloud` de supervivencia

> **Objetivo:** manejar la CLI de Google Cloud sin pelearte con ella: configuraciones,
> autenticación, impersonation, `--format`, `--filter`, `--flatten` y los flags globales que
> convierten diez comandos en uno. Es el apéndice que se consulta desde cualquier lab.
> **Se asume leído:** nada. Si sabes abrir una terminal, alcanza.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Qué es gcloud](#1--qué-es-gcloud-y-qué-no-es) ·
[Instalación y componentes](#2--instalación-componentes-y-versiones) ·
[Configuraciones](#3--configuraciones-la-pieza-que-casi-nadie-usa-y-lo-arregla-todo) ·
[Propiedades y variables](#4--propiedades-y-variables-de-entorno) ·
[Autenticación](#5--autenticación-dos-credenciales-distintas-que-todos-confunden) ·
[Impersonation](#6--impersonation-en-vez-de-descargar-una-key) ·
[`--format`](#7----format-la-salida-la-eliges-tú) ·
[`--filter`](#8----filter-filtra-en-el-servidor-no-con-grep) ·
[`--flatten`](#9----flatten-cuando-el-dato-que-quieres-vive-dentro-de-una-lista) ·
[Operaciones largas](#10--operaciones-de-larga-duración-y---async) ·
[`--log-http`](#11----log-http-y---verbosity-el-microscopio) ·
[APIs y proyectos](#12--apis-proyectos-y-cuotas-desde-la-cli) ·
[Errores de la CLI](#13--errores-que-son-de-la-cli-y-no-de-gcp) ·
[Chuleta](#14--chuleta-de-una-página) ·
[Preguntas rápidas](#-preguntas-rápidas)

Este apéndice no tiene orden ni prerrequisitos: se entra por la sección que necesitas. Todo lo
que aparece aquí se usa en `L01`–`L08`, y casi todo se usa en el primero.

---

## 1. 🧭 Qué es `gcloud` y qué no es

Antes del primer comando conviene deshacer una idea que hace perder muchas horas: `gcloud` no
es "la consola web en modo texto", ni un producto aparte con sus propias reglas.

> 🧠 **Modelo mental.** `gcloud` es **un cliente HTTP de las APIs de Google Cloud**. Cada
> comando se traduce a una o varias llamadas REST a `*.googleapis.com`, autenticadas con un
> token OAuth. La consola web es otro cliente de las mismas APIs. Tu código con las librerías
> `google-cloud-*`, un tercero.

Esto tiene tres consecuencias prácticas que vale la pena tener presentes desde el principio:

- **Si la API no está habilitada en el proyecto, el comando falla**, por muchos permisos que
  tengas. Es el `SERVICE_DISABLED` que aparece en [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) y que se cataloga en
  [`A03`](a03-catalogo-de-errores-y-diagnostico.md).
- **Si tu identidad no tiene el permiso, el comando falla igual**, aunque la consola web te
  deje ver el botón. La consola y la CLI comparten el mismo IAM.
- **Todo lo que hace `gcloud` lo puedes hacer desde código**, y `--log-http` (§11) te enseña
  exactamente cómo. Ese es el puente que usa la rutina de
  [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md).

La forma de casi todos los comandos es la misma, y reconocerla ahorra buscar en la
documentación:

```text
gcloud  GRUPO  [SUBGRUPO]  VERBO  [NOMBRE]  [--flags]
        ─────  ──────────  ─────  ────────
        run    services    list
        iam    service-accounts create   inv-api-sa
        pubsub topics      describe      inv-events
```

Los verbos se repiten en todo el catálogo: `create`, `describe`, `list`, `update`, `delete`,
y a veces `add-iam-policy-binding` / `remove-iam-policy-binding`. Si sabes el grupo, casi
siempre puedes adivinar el comando; y si no, `gcloud <grupo> --help` lo lista.

---

## 2. 🧱 Instalación, componentes y versiones

`gcloud` viene dentro del **Google Cloud SDK**, que se instala como un paquete único y trae
más binarios de los que parece: `gcloud`, `gsutil` (histórico, para Cloud Storage), `bq`
(BigQuery) y opcionalmente `terraform`-adjacent nada — Terraform se instala aparte.

```bash
gcloud version
```

```text
Google Cloud SDK 525.0.0
bq 2.1.9
core 2025.08.29
gcloud-crc32c 1.0.0
gsutil 5.30
```

Ese comando es la primera cosa que se pega en un reporte de error: media docena de
comportamientos raros de la CLI son versiones viejas.

**Componentes.** El SDK es modular. Lo que no viene instalado se agrega:

```bash
gcloud components list
gcloud components install pubsub-emulator
gcloud components update
```

- `components list` muestra qué está instalado, qué se puede instalar y qué tiene actualización
  pendiente.
- `components install <nombre>` agrega uno. Los emuladores de la tabla de
  [`L00` §8](l00-idea-lab-practico.md#8--emuladores-locales-qué-sirve-y-qué-miente) llegan por
  aquí.
- `components update` actualiza todo el SDK.

> ⚠️ **Si instalaste el SDK con el gestor de paquetes del sistema** (`apt`, `dnf`, `brew`,
> Chocolatey), `gcloud components update` te va a decir que la gestión de componentes está
> deshabilitada y que actualices con ese gestor. No es un error: es que el paquete del sistema
> es dueño de los archivos. Elige un método y sostenlo.

**Canales `alpha` y `beta`.** Muchos comandos existen solo en un canal de preview:

```bash
gcloud beta run services describe inv-api --region us-central1
```

Los canales se instalan como componentes (`gcloud components install alpha beta`) y no son
prohibidos, pero sí son señal: **un comando que solo existe en `alpha` es una superficie que
puede cambiar sin aviso**. En este curso, cuando se usa uno, se dice explícitamente.

---

## 3. 🧱 Configuraciones: la pieza que casi nadie usa y lo arregla todo

Este es el problema que resuelve, y es el que produce el 90 % de los "pero si yo creé ese
recurso, ¿dónde está?": tienes un proyecto personal, el proyecto del lab y quizá uno del
trabajo. Sin configuraciones, o repites `--project` en cada comando o dejas un
`gcloud config set project` global que se te olvida y desplegás el lab en el proyecto
equivocado.

Una **configuración** es un conjunto con nombre de propiedades (cuenta, proyecto, región,
zona) que se activa entera de un golpe.

```bash
gcloud config configurations create inv-lab
gcloud config set account tu-cuenta@gmail.com
gcloud config set project inv-lab-472913
gcloud config set run/region us-central1
gcloud config set compute/region us-central1
```

- `configurations create inv-lab` crea la configuración **y la activa**. El nombre `inv-lab`
  es el que fija el baseline del curso.
- `config set account` fija con qué identidad se ejecutan los comandos de esta configuración.
  No autentica nada: solo elige, de entre las credenciales que ya tienes, cuál usar.
- `config set project` fija el proyecto por defecto. A partir de aquí `--project` sobra.
- `config set run/region` y `compute/region` son **propiedades de sección**: `run/region` solo
  la lee `gcloud run`, `compute/region` la leen los comandos de Compute Engine y varios de red.
  No hay una "región global" única, y por eso a veces pones región y un comando te la sigue
  pidiendo.

Para moverte entre ellas:

```bash
gcloud config configurations list
gcloud config configurations activate inv-lab
gcloud config list
```

```text
[core]
account = tu-cuenta@gmail.com
disable_usage_reporting = True
project = inv-lab-472913
[run]
region = us-central1
```

> 💡 **Truco.** `gcloud config list` es lo primero que hay que mirar cuando un comando "no
> encuentra" algo. Nueve de cada diez veces el recurso existe y estás apuntando a otro
> proyecto.

**Sin activar nada, para un solo comando:**

```bash
gcloud --configuration=inv-lab run services list
```

El flag global `--configuration` usa esa configuración solo para esa invocación. Es lo correcto
dentro de un script: **un script nunca debe depender de cuál configuración dejaste activa**.

---

## 4. 🧱 Propiedades y variables de entorno

Toda propiedad de configuración tiene una variable de entorno equivalente, con el patrón
`CLOUDSDK_<SECCIÓN>_<PROPIEDAD>`:

| Propiedad | Variable de entorno |
|---|---|
| `core/project` | `CLOUDSDK_CORE_PROJECT` |
| `core/account` | `CLOUDSDK_CORE_ACCOUNT` |
| `run/region` | `CLOUDSDK_RUN_REGION` |
| `compute/zone` | `CLOUDSDK_COMPUTE_ZONE` |

El orden de precedencia, de mayor a menor, es el que importa recordar:

```text
flag en la línea de comandos   >   variable de entorno   >   configuración activa   >   default
```

Por eso un `--project` explícito siempre gana, y por eso en CI se fija todo por variables de
entorno en vez de por configuraciones: el contenedor del pipeline no tiene un `~/.config`
persistente que activar.

---

## 5. 🧱 Autenticación: dos credenciales distintas que todos confunden

Aquí está la confusión más cara de la CLI, y conviene resolverla antes de escribir una línea de
código. **`gcloud` y tu código no usan la misma credencial.**

```bash
gcloud auth login
```

Abre el navegador, te autentica y guarda un token **para que lo use la CLI**. Después de esto,
`gcloud storage buckets list` funciona. Tu script de Python, no.

```bash
gcloud auth application-default login
```

Abre el navegador otra vez, y guarda **un archivo de credenciales en la ruta estándar de las
Application Default Credentials (ADC)** — `~/.config/gcloud/application_default_credentials.json`
en Linux y macOS. Ese archivo es el que buscan las librerías `google-cloud-*`, Terraform y
cualquier cosa que hable "ADC". Después de esto, tu script de Python funciona.

> 🧠 **Modelo mental.** `gcloud auth login` es "yo, el humano, ante la CLI".
> `gcloud auth application-default login` es "yo, el humano, prestándole mi identidad al código
> que corro en esta máquina". Son dos credenciales guardadas en dos sitios distintos y se
> revocan por separado.

Qué busca ADC, en orden, y por qué importa saberlo:

```text
1. La variable GOOGLE_APPLICATION_CREDENTIALS, si apunta a un archivo de credenciales
2. El archivo de ADC del usuario  (gcloud auth application-default login)
3. La credencial adjunta al entorno de ejecución:
     - la service account de la instancia (Compute Engine, GKE)
     - la service account del servicio  (Cloud Run, Cloud Functions)
   servida por el metadata server, sin ningún archivo de por medio
```

El punto 3 es la razón de que tu código funcione en Cloud Run **sin ninguna clave**: la
plataforma le entrega tokens de la service account del servicio a través del metadata server.
Es también la razón de que descargar una key de service account casi nunca sea necesario — ver
§6.

Para ver qué tienes ahora mismo:

```bash
gcloud auth list
```

```text
   Credentialed Accounts
ACTIVE  ACCOUNT
*       tu-cuenta@gmail.com
        inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
```

El asterisco marca la cuenta activa. Y para limpiar al terminar una sesión:

```bash
gcloud auth revoke tu-cuenta@gmail.com
gcloud auth application-default revoke
```

Los dos comandos son distintos porque las dos credenciales son distintas. Revocar una deja la
otra viva, y eso explica el clásico "revoqué el acceso pero mi script sigue funcionando".

---

## 6. 🧱 Impersonation en vez de descargar una key

El problema: quieres probar qué puede hacer `inv-api-sa` sin desplegar nada. La respuesta
instintiva es crear una key JSON de esa service account, descargarla y exportar
`GOOGLE_APPLICATION_CREDENTIALS`. Es lo que hace medio Internet y es exactamente lo que no hay
que hacer.

> ⚠️ **Una key descargada es una credencial de larga duración, sin rotación, en tu disco y
> probablemente en tu historial de shell.** Es el hallazgo número uno de cualquier auditoría, y
> hay una Organization Policy dedicada a prohibirlas
> (`constraints/iam.disableServiceAccountKeyCreation`). El curso no descarga keys en ningún
> lab.

La alternativa nativa es la **impersonation**: tu identidad humana pide un token de corta
duración *en nombre de* la service account.

```bash
gcloud storage buckets list \
  --impersonate-service-account=inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
```

- `--impersonate-service-account` es un **flag global**: funciona en cualquier comando de
  `gcloud`, no solo en este. Internamente pide un access token efímero por ti.
- Para que funcione, tu usuario necesita el rol
  **`roles/iam.serviceAccountTokenCreator` sobre esa service account** (no sobre el proyecto).
  Si no lo tienes, el error es un `PERMISSION_DENIED` que menciona `generateAccessToken`, y es
  uno de los casos del catálogo de [`A03`](a03-catalogo-de-errores-y-diagnostico.md).

Para que tu **código** haga lo mismo, la variante de ADC:

```bash
gcloud auth application-default login \
  --impersonate-service-account=inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
```

Escribe un archivo de ADC que, en vez de contener una clave, contiene la instrucción de
impersonar. Terraform y las librerías cliente lo entienden sin cambios en el código.

> 💡 **Truco de entrevista.** "¿Cómo pruebas los permisos de una service account?" tiene dos
> respuestas: la mala es "me descargo la key"; la buena es "la impersono con
> `--impersonate-service-account`, que me da un token de corta duración y deja rastro en los
> Audit Logs con mi identidad, no con la suya".

---

## 7. 🧱 `--format`: la salida la eliges tú

Por defecto `gcloud` imprime una tabla pensada para humanos, que **no es un contrato estable**:
las columnas cambian entre versiones. Parsear esa tabla con `awk` es la forma más rápida de
escribir un script que se rompe solo.

`--format` es un flag global y cambia por completo la salida.

```bash
gcloud run services describe inv-api --region us-central1 --format=json
```

- `--format=json` imprime el recurso completo, tal como lo devuelve la API. Es la vista que
  usa el paso 2 de la rutina de [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md), porque
  te enseña **qué campos tiene de verdad** el objeto, no los cuatro que la tabla decidió
  mostrarte.
- `--format=yaml` es lo mismo, más legible para leer a ojo.

Los dos formatos que de verdad ahorran tiempo son estos:

```bash
gcloud run services describe inv-api --region us-central1 \
  --format='value(status.url)'
```

- `value(...)` imprime **solo** el valor del campo, sin comillas, sin encabezado y sin adorno:
  perfecto para meterlo en una variable de shell. Varios campos separados por coma salen
  separados por tabulador.

```bash
gcloud iam service-accounts list \
  --format='table(displayName, email, disabled)'
```

- `table(...)` arma tu propia tabla con las columnas que te interesan. Admite títulos
  (`email:label=CUENTA`) y orden (`email:sort=1`).

Un detalle que confunde: **la ruta del campo es la del JSON, no la de la tabla por defecto**.
Si la tabla muestra `URL` pero el JSON dice `status.url`, en `--format` va `status.url`. Por eso
el flujo correcto es siempre mirar primero el `--format=json` y después escribir el `value()`.

```bash
# el patrón completo, y probablemente el que más vas a repetir en la serie
URL=$(gcloud run services describe inv-api --region us-central1 --format='value(status.url)')
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$URL"
```

`gcloud auth print-identity-token` imprime un **ID token** de tu identidad, que es lo que Cloud
Run valida cuando el servicio está desplegado con `--no-allow-unauthenticated`. Ojo con la
confusión clásica: `print-access-token` imprime un **access token** para llamar a las APIs de
Google, y **no sirve** para invocar un servicio de Cloud Run privado. Son dos tokens distintos
para dos cosas distintas.

---

## 8. 🧱 `--filter`: filtra en el servidor, no con `grep`

El problema con `| grep` es doble: filtra sobre la representación de texto (frágil) y, en las
listas largas, después de haberse traído todo. `--filter` usa una expresión que `gcloud`
entiende y que, en muchos comandos, **empuja al servidor**.

```bash
gcloud compute instances list --filter='status=RUNNING AND zone:us-central1'
```

- `=` es igualdad exacta. `status=RUNNING` no matchea `RUNNING_LATE`.
- `:` es "contiene" — `zone:us-central1` matchea `us-central1-a` y `us-central1-b`.
- `AND`, `OR` y `NOT` se escriben en mayúsculas. `AND` es el implícito si pones dos condiciones
  seguidas, pero escribirlo hace el comando legible.
- Comparadores `<`, `>`, `<=`, `>=` funcionan sobre números y timestamps.
- `~` compara contra una expresión regular: `name~^inv-`.

Dos usos que se repiten en toda la serie:

```bash
# todo lo que lleva el label de rastreo del lab
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --filter='labels.project=inv_lab' \
  --format='table(assetType, name)'

# las reglas de firewall que dejan pasar SSH desde cualquier sitio
gcloud compute firewall-rules list \
  --filter='allowed[].map().firewall_rule().list():22 AND sourceRanges:0.0.0.0/0'
```

El segundo comando parece jeroglífico y conviene desarmarlo, porque es la forma canónica de
consultar un campo que es una lista de objetos: `allowed[]` toma la lista, `.map()` aplica lo
que sigue a cada elemento, `.firewall_rule()` es una función de proyección que formatea cada
regla como `tcp:22`, y `.list()` junta el resultado en una cadena sobre la que ya se puede
buscar `:22`. Si esto te parece demasiado, la salida honesta es: `--format=json` y `jq`. No
hay premio por hacerlo todo en una línea.

> ⚠️ **`--filter` no siempre filtra en el servidor.** Algunos comandos traen la lista entera y
> filtran en tu máquina; otros aceptan además un `--filter` nativo de la API. Para el tamaño de
> este laboratorio da igual, pero en un proyecto con miles de recursos la diferencia se nota en
> la cuota de la API.

---

## 9. 🧱 `--flatten`: cuando el dato que quieres vive dentro de una lista

El caso: quieres ver quién tiene qué rol en el proyecto. La allow policy es un objeto con una
lista de `bindings`, y cada binding tiene un rol y una lista de `members`. Una tabla no puede
mostrar eso sin aplastarlo primero.

```bash
gcloud projects get-iam-policy inv-lab-472913 --format=json
```

```text
{
  "bindings": [
    {
      "members": ["user:tu-cuenta@gmail.com"],
      "role": "roles/owner"
    },
    {
      "members": [
        "serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com",
        "serviceAccount:inv-projector-sa@inv-lab-472913.iam.gserviceaccount.com"
      ],
      "role": "roles/datastore.user"
    }
  ],
  "etag": "BwYh0mR3lFo=",
  "version": 1
}
```

`--flatten` convierte **cada elemento de una lista en un registro propio**, repitiendo el resto
de los campos:

```bash
gcloud projects get-iam-policy inv-lab-472913 \
  --flatten='bindings[].members[]' \
  --format='table(bindings.role, bindings.members)'
```

```text
ROLE                     MEMBERS
roles/owner              user:tu-cuenta@gmail.com
roles/datastore.user     serviceAccount:inv-api-sa@inv-lab-472913.iam.gserviceaccount.com
roles/datastore.user     serviceAccount:inv-projector-sa@inv-lab-472913.iam.gserviceaccount.com
```

- `bindings[]` aplana la lista de bindings; `members[]` aplana, dentro de cada uno, la lista de
  miembros. El resultado es una fila por par (rol, miembro), que es lo que querías desde el
  principio.
- Fíjate en que después de aplanar, en `--format` los campos se nombran **en singular sin
  corchetes**: `bindings.role`, no `bindings[].role`.

Con eso ya se puede filtrar por miembro, que es la pregunta real cuando algo devuelve
`PERMISSION_DENIED`:

```bash
gcloud projects get-iam-policy inv-lab-472913 \
  --flatten='bindings[].members[]' \
  --filter='bindings.members:inv-api-sa' \
  --format='value(bindings.role)'
```

> 🩺 **Diagnóstico.** Ese comando responde "¿qué roles tiene esta service account **en el
> proyecto**?". Ojo con el "en el proyecto": si el binding está en el recurso (un bucket, un
> topic, un servicio de Cloud Run) no aparece aquí. Para eso está
> `gcloud <recurso> get-iam-policy`, y esa distinción es la trampa central de [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md).

---

## 10. 🧱 Operaciones de larga duración y `--async`

Casi todo `create` y `delete` en GCP no devuelve el recurso: devuelve una **Operation**, un
objeto que representa "esto está en curso". `gcloud` te lo esconde porque hace polling por ti
hasta que termina, y por eso los comandos *parecen* síncronos.

```bash
gcloud pubsub topics create inv-events --async
```

- `--async` le dice a `gcloud` que **no espere**: imprime el nombre de la operación y te
  devuelve el prompt. Útil cuando lanzas varias creaciones independientes.
- Sin `--async`, `gcloud` bloquea hasta que la operación termina o falla.

Esto importa por una razón que va más allá de la comodidad: **cuando escribas el mismo `create`
desde un SDK, la espera la tienes que hacer tú.** Es el error número uno de quien pasa de la
CLI a la librería —el código sigue adelante creyendo que el recurso ya existe— y es la lección
que fija el paso 6 de la rutina de [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md).

---

## 11. 🩺 `--log-http` y `--verbosity`: el microscopio

Dos flags globales para cuando algo no cuadra.

```bash
gcloud pubsub topics create inv-events --log-http
```

`--log-http` imprime **la petición y la respuesta HTTP completas**: método, URL, headers,
cuerpo enviado y cuerpo recibido. Es decir, te enseña la llamada REST exacta que produce el
comando que acabas de escribir. Sirve para tres cosas, y la tercera es la importante:

1. Ver el mensaje de error crudo de la API cuando `gcloud` te lo resume demasiado.
2. Confirmar contra qué endpoint y con qué versión de API estás hablando.
3. **Traducir el comando a código.** Con la URL, el método y el cuerpo delante, escribir el
   equivalente con una librería cliente deja de ser un ejercicio de documentación.

> ⚠️ La salida de `--log-http` incluye el header `Authorization` con tu token. No la pegues en
> un issue ni en un chat sin recortarla.

```bash
gcloud run deploy inv-api --image ... --verbosity=debug
```

`--verbosity` acepta `debug`, `info`, `warning`, `error`, `critical` y `none`. `debug` muestra
el rastro interno de `gcloud` —incluidas las excepciones de Python cuando algo revienta de
verdad—, que es lo que hay que adjuntar cuando el problema es de la CLI y no de GCP.

Otros dos flags globales que conviene tener presentes:

- `--quiet` (o `-q`) responde "sí" a toda pregunta interactiva. Es imprescindible en scripts y
  **peligroso a mano**: `gcloud projects delete` con `--quiet` no te pregunta dos veces 😉.
- `--impersonate-service-account`, ya visto en §6.

---

## 12. 🧱 APIs, proyectos y cuotas desde la CLI

Los cuatro comandos que se repiten en cada lab de la serie.

**Habilitar APIs.** En GCP un proyecto nuevo trae casi todo apagado. Cada producto es una API
que se habilita explícitamente, y hasta entonces todos sus comandos fallan.

```bash
gcloud services list --enabled
gcloud services enable run.googleapis.com pubsub.googleapis.com firestore.googleapis.com
```

- `services list --enabled` muestra qué está habilitado en el proyecto activo. Sin el flag,
  lista el catálogo completo de APIs disponibles, que es enorme.
- `services enable` acepta varias a la vez, y **tarda**: es una operación de larga duración de
  las de §10, y hay un retardo de propagación tras el cual el primer comando todavía puede
  fallar. Si acabas de habilitar una API y el siguiente comando dice `SERVICE_DISABLED`,
  espera treinta segundos y repite antes de dudar de tu IAM.

**Proyectos.**

```bash
gcloud projects list --filter='labels.project=inv_lab'
gcloud projects describe inv-lab-472913
```

Y el detalle que confunde a todo el mundo: un proyecto tiene **tres identificadores**. El
`projectId` (`inv-lab-472913`) es el que usas siempre y es inmutable; el `name` es una etiqueta
legible y cambiable; el `projectNumber` es un número que aparece solo, y es el que verás en los
correos de las service accounts gestionadas por Google —los *service agents*— y en varios
mensajes de error. No son intercambiables.

**Cuotas.** Las cuotas son por proyecto y por API, y son la explicación de varios fallos que
parecen aleatorios:

```bash
gcloud services quota list \
  --service=run.googleapis.com \
  --consumer=projects/inv-lab-472913
```

---

## 13. 🩺 Errores que son de la CLI y no de GCP

Cuatro fricciones que cuestan tiempo y no tienen nada que ver con tu arquitectura.

**"El recurso no existe" y sí existe.** Estás en otro proyecto o en otra región. `gcloud config
list` primero, siempre. Recuerda que `run/region` y `compute/region` son propiedades
**distintas**: fijar una no fija la otra.

**El comando pide una región que ya configuraste.** Muchos comandos de `gcloud` no leen ninguna
propiedad de región y exigen `--region` o `--location` explícito. No es un bug: no todos los
grupos tienen una propiedad de sección asociada.

**Comillas y el shell.** Las expresiones de `--filter` y `--format` llevan paréntesis, comas y
a veces `$`. Van **siempre entre comillas simples**, para que las expanda `gcloud` y no tu
shell. Un `--format="value(status.url)"` con comillas dobles funciona por casualidad hasta que
metes un `$` dentro.

**`gcloud` actualizado a medias.** Si un comando documentado "no existe", mira `gcloud version`
y si el comando pertenece a `alpha` o `beta`. El mensaje de la CLI suele sugerirte el
componente que falta.

---

## 14. 🧭 Chuleta de una página

```text
CONFIGURACIÓN
  gcloud config configurations create|activate|list  inv-lab
  gcloud config set project|account|run/region       <valor>
  gcloud config list                                 ← míralo antes de dudar de GCP
  gcloud --configuration=inv-lab <comando>           ← en scripts, nunca la activa

AUTENTICACIÓN
  gcloud auth login                                  ← credencial de la CLI
  gcloud auth application-default login              ← credencial de TU CÓDIGO (ADC)
  gcloud auth list
  gcloud auth print-identity-token                   ← invocar Cloud Run privado
  gcloud auth print-access-token                     ← llamar a las APIs de Google
  gcloud auth revoke / application-default revoke
  --impersonate-service-account=SA                   ← en vez de descargar una key

SALIDA
  --format=json | yaml                               ← qué campos tiene DE VERDAD
  --format='value(status.url)'                       ← para meter en una variable
  --format='table(name, email:label=CUENTA)'
  --filter='status=RUNNING AND zone:us-central1'     ← = exacto, : contiene, ~ regex
  --flatten='bindings[].members[]'                   ← una fila por elemento de la lista

DIAGNÓSTICO
  --log-http                                         ← la llamada REST exacta (¡lleva token!)
  --verbosity=debug
  --async                                            ← no esperar a la Operation
  --quiet                                            ← en scripts; con cuidado a mano

PROYECTO
  gcloud services list --enabled
  gcloud services enable <api>.googleapis.com        ← tarda y propaga con retardo
  gcloud projects describe <projectId>               ← projectId ≠ name ≠ projectNumber
```

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia hay entre `gcloud auth login` y `gcloud auth application-default login`, y cuál necesita tu script de Python?
2. Si revocas una de las dos credenciales anteriores, ¿qué sigue funcionando y qué no?
3. ¿Por qué `--impersonate-service-account` es preferible a descargar una key JSON, y qué rol necesitas para usarlo?
4. Fijaste `compute/region` y un comando de `gcloud run` te sigue pidiendo la región. ¿Por qué?
5. ¿Qué imprime `--format='value(...)'` que no imprima `--format=json`, y para qué sirve esa diferencia?
6. ¿De dónde sacas el nombre correcto del campo que va dentro de `value()`?
7. ¿Qué diferencia hay entre `=` y `:` dentro de una expresión de `--filter`?
8. ¿Qué hace `--flatten='bindings[].members[]'` y por qué hace falta para leer una allow policy?
9. ¿Por qué un `gcloud ... create` parece síncrono y el mismo `create` desde un SDK no lo es?
10. ¿Qué te enseña `--log-http` que no te enseñe `--verbosity=debug`, y qué precaución hay que tomar con su salida?
11. Acabas de habilitar una API y el siguiente comando falla con `SERVICE_DISABLED`. ¿Cuál es la primera hipótesis antes de tocar IAM?
12. ¿En qué se diferencian el `projectId`, el `name` y el `projectNumber` de un proyecto, y dónde te vas a topar con el tercero?
13. ¿Por qué las expresiones de `--filter` y `--format` se escriben entre comillas simples?
14. ¿Qué token necesitas para invocar un servicio de Cloud Run desplegado con `--no-allow-unauthenticated`, y cuál es el que la gente usa por error?

---

## 📚 Referencias oficiales

- Documentación del SDK de Google Cloud: https://cloud.google.com/sdk/docs
- Instalar el SDK: https://cloud.google.com/sdk/docs/install
- Referencia completa de `gcloud` y sus flags globales: https://cloud.google.com/sdk/gcloud/reference
- Gestionar configuraciones del SDK: https://cloud.google.com/sdk/docs/configurations
- Propiedades del SDK y sus variables de entorno: https://cloud.google.com/sdk/docs/properties
- Gestión de componentes: https://cloud.google.com/sdk/gcloud/reference/components
- `gcloud auth login`: https://cloud.google.com/sdk/gcloud/reference/auth/login
- `gcloud auth application-default login`: https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login
- Credenciales predeterminadas de la aplicación (ADC): https://cloud.google.com/docs/authentication/application-default-credentials
- Proporcionar credenciales para ADC: https://cloud.google.com/docs/authentication/provide-credentials-adc
- Suplantación de identidad de service accounts: https://cloud.google.com/iam/docs/service-account-impersonation
- Formatos de salida de `gcloud` (`gcloud topic formats`): https://cloud.google.com/sdk/gcloud/reference/topic/formats
- Expresiones de filtro (`gcloud topic filters`): https://cloud.google.com/sdk/gcloud/reference/topic/filters
- Proyecciones de campos (`gcloud topic projections`): https://cloud.google.com/sdk/gcloud/reference/topic/projections
- Habilitar y deshabilitar servicios: https://cloud.google.com/service-usage/docs/enable-disable
- `gcloud services enable`: https://cloud.google.com/sdk/gcloud/reference/services/enable
- Identificadores de un proyecto: https://cloud.google.com/resource-manager/docs/creating-managing-projects
- Cuotas y límites: https://cloud.google.com/docs/quotas
- Operaciones de larga duración en las APIs de Google Cloud: https://google.aip.dev/151
- Chuleta oficial de `gcloud`: https://cloud.google.com/sdk/docs/cheatsheet
