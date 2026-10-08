# ✍️ Guía de estilo, tono y convenciones
## GCP Core Refresh — repaso para entrevistas y serie práctica de labs

Esta guía es la fuente de verdad editorial de `repaso-gcp-entrevistas/`. Cualquier
chat que produzca o edite un `.md` de este curso la sigue. Su objetivo es que los
veintiocho documentos —trece teóricos, el solucionario, ocho labs, cuatro apéndices, el
encuadre de la serie práctica y el README— se lean como escritos por la misma mano y
apunten al mismo lugar: **que el lector pueda explicar y defender una decisión de
arquitectura en Google Cloud, no que recuerde nombres de servicios**.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que
mañana tiene una entrevista de arquitectura y pasado mañana tiene que diseñar de
verdad el sistema del que habló.

> 📝 **Esta guía se reescribió tomando como base la del curso `docker-container-legacy`
> y su hermana de `repaso-aws-entrevistas/`.** La versión anterior pedía sobriedad
> absoluta, prohibía todo emoji y ordenaba "brevedad ante todo, 10–15 minutos de
> lectura". Producía documentos correctos que se leían como una hoja de referencia:
> el mecanismo estaba, la razón no. Lo que cambia es el registro y la exigencia
> pedagógica; lo que no cambia es el fondo, que sigue siendo material de entrevista.

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien reconozca, explique, compare y decida.**

No enseñamos GCP "completo": el catálogo pasa de los doscientos productos y
memorizarlos no hace a nadie mejor arquitecto. Repasamos el vocabulario, los
mecanismos y los matices que separan a quien entiende el modelo de quien aprendió la
lista. En la serie práctica, además, formamos una capacidad concreta: **encender
infraestructura desde la CLI y desde Terraform, romperla a propósito, diagnosticarla y
destruirla con certeza**.

El filtro para cada párrafo es este: **¿esto ayuda a reconocer, explicar, comparar o
decidir?** Si no, sobra. Aunque esté muy bien escrito.

Y el corolario, repetido tantas veces como haga falta:

> Cada comando se explica. Cada flag se explica. Cada decisión responde a
> "¿por qué estamos haciendo esto y qué pasaría si no?".

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, de colega a colega. Piensa en alguien que
ya se quemó con esto —un `PERMISSION_DENIED` que no era de IAM sino de una API sin
habilitar, un `terraform destroy` que falla por `deletion_protection`, una factura con
un forwarding rule olvidado— y te lo explica con paciencia y sin solemnidad de manual
corporativo.

Cómo se ve en la práctica:

- **Tuteo latinoamericano, siempre.** Le hablas al lector de "tú": *"fíjate en qué
  recursos marca el plan como `must be replaced`"*, *"si esto te suena raro, es porque
  todavía no vimos cómo se evalúan las allow policies; aguanta dos secciones"*. Nada de
  voseo, nada de "usted", nada de impersonal permanente ("se debe configurar…") que
  enfría el texto.
- **Semi formal.** Cercano, pero no chat. Frases completas, puntuación correcta, cero
  abreviaturas de mensajería.
- **Humor mínimo y seco.** Un 😉 bien puesto para desdramatizar una fricción real —la
  fe ciega en `--quiet`, el enésimo `SERVICE_DISABLED`— y nada más. Regla práctica:
  **como mucho un desdramatizador por documento**, y si no fluye solo, se borra. Este
  curso no es el de Docker: aquí el humor es la excepción, no el registro.
- **Honesto sobre las simplificaciones.** Cuando la respuesta común de entrevista es
  una sobregeneralización —"Pub/Sub garantiza exactly-once", "Firestore siempre es
  fuertemente consistente", "una VM sin IP externa no puede salir a Internet", "la VPC
  de GCP es como cualquier otra VPC"— se nombra la simplificación y se da la versión
  precisa. **Este es el recurso pedagógico central del curso**, por encima de la
  analogía y del ejemplo.
- **Honesto sobre el dinero.** Cada recurso que cobra por hora se nombra con su precio
  y su unidad. No hay eufemismos tipo "costo reducido": o entra en el Always Free y se
  dice con su cuota exacta, o cuesta $0.025/h, o se dice que no se verificó.
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca infantilizamos.
  "Como para un bebé" significa **cero ambigüedad**, no menos profundidad — ver §4.
- **Sin relleno motivacional.** Sin "¡tú puedes!", sin "vas a dominar GCP". Quien lee
  ya sabe por qué está repasando.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no sea código o
  salida de terminal.
- **Los nombres de productos, features y términos del stack se quedan en inglés** cuando
  son el nombre real de la cosa: *Region*, *Zone*, *Shared VPC*, *allow policy*,
  *binding*, *Workload Identity Federation*, *ordering key*, *hot partition*,
  *eventually consistent*, *cold start*, *drift*, *forwarding rule*. Traducirlos
  forzadamente ("política de permitir", "regla de reenvío") confunde y no es lo que el
  lector va a ver en la consola, en `gcloud` ni en los mensajes de error. Los que ya
  tienen traducción asentada —región, cola, rol, proyecto, carpeta— pueden alternar con
  naturalidad; lo importante es no inventar vocabulario.
- **Markdown siempre.** Nada de HTML embebido.
- **Estructura visual primero, pero la prosa ya no es el último recurso.** El orden de
  preferencia sigue siendo diagrama ASCII → tabla → lista → párrafo *para exponer una
  relación entre cosas*. Pero el **porqué** de una decisión se escribe en prosa: una
  tabla no puede explicar por qué un `terraform destroy` aparentemente exitoso te deja
  una base de Firestore viva, ni por qué borrar el proyecto no corta la facturación al
  instante.
- **Nada de prosa telegrama.** Una frase corta y sola, con líneas en blanco a ambos
  lados, es un buen golpe de ritmo. Tres seguidas ya no son ritmo: son un telegrama, y
  el lector deja de encontrar el argumento porque no hay párrafo donde buscarlo. Regla
  práctica: **una frase aislada por sección, dos si la sección es larga**.
- **Diagramas ASCII en bloques ` ```text `.** Es el recurso visual principal del curso, y
  se usa sin timidez para la jerarquía Organization → Folder → Project, flujos de
  tráfico, arquitecturas y máquinas de estados. Simples: cajas, flechas, texto. Sin arte
  ASCII elaborado.
- **Tablas solo para comparar o mapear**, con tres o cuatro columnas como norma:
  "Cloud Run vs GKE", "Cloud SQL vs AlloyDB", "qué cobra por hora y qué entra en el
  Always Free", necesidad→servicio. **La excepción legítima es la matriz que enfrenta
  cuatro alternativas a un criterio** —Pub/Sub vs Cloud Tasks vs Eventarc vs Workflows en
  `07`, las estrategias de DR en `11`—, donde cinco columnas son la forma natural del
  contenido. **Si necesitas explicar una celda, ya no es una tabla**: es una lista con
  subtítulos o un par de párrafos. Nunca se narra en tabla.
- **Salida de terminal literal.** Cuando se muestra lo que imprime un comando, se muestra
  tal como sale, en bloque ` ```text `, sin embellecer y sin recortar la parte incómoda.
  El error real enseña más que el error editado. Los identificadores se anonimizan
  siempre con los valores del baseline de §5.1 —proyecto `inv-lab-472913`, cuenta de
  facturación `01A2B3-C4D5E6-F7G8H9`— y los nombres de recurso completos
  (`projects/…/locations/…/services/…`) mantienen su forma real.
- **Encabezados con emoji, con moderación.** Uno por sección `##` numerada, ninguno en
  las subsecciones `###`. El emoji es funcional: señala de qué tipo es la sección
  (🧭 encuadre, 🧱 mecanismo, ⚖ comparación, 🩺 diagnóstico, 💰 costo, 🧪 verificación,
  📚 referencias). Un documento que parece un teclado de emojis pierde autoridad.

### 3.1 El curso es autocontenido y no traduce desde AWS

Regla heredada de la versión anterior de esta guía, y sigue vigente sin cambios.

Este curso **no asume que el lector sabe AWS**, aunque viva en el mismo repositorio que
`repaso-aws-entrevistas/`. Cada concepto se explica desde cero. **No se agregan tablas
de mapeo AWS→GCP ni frases del tipo "esto es como el ALB de AWS".** Cuando un concepto
de GCP diverge de la intuición típica de quien viene de otra nube —que la VPC es de
alcance global y la subnet regional, que el proyecto es la unidad de aislamiento y de
facturación, que las allow policies son aditivas— se explica como una propiedad de GCP
en sí misma, no como contraste con otro proveedor.

La única excepción admitida está en `l00-idea-lab-practico.md` §10, donde el documento
sitúa esta serie dentro del repositorio y puede nombrar los otros cursos por su nombre.
Nombrarlos no es traducir conceptos.

---

## 4. 🎓 Pedagogía: "como para un bebé"

Esta sección es la que más define el curso desde esta versión de la guía, y viene
prestada del curso `docker-container-legacy`. El principio se enuncia así:

> **"Como para un bebé" significa cero ambigüedad, no menos profundidad.**

No es escribir más simple: es no dejar ningún hueco donde el lector tenga que adivinar.
Se explica qué es una service account, en qué se diferencia de un principal humano, qué
significa que un binding sea aditivo y qué error exacto sale cuando le das el rol en el
recurso equivocado. No se dice "asigna el rol correcto" y se sigue adelante.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar el servicio, muestra el dolor que resuelve.
   *"Tu servicio de Cloud Run escribe en Firestore, Pub/Sub reintenta la entrega y ahora
   tienes el mismo movimiento de inventario contado dos veces. ¿Qué le pones delante?"*
2. **El mecanismo después.** Ahora sí, el nombre y la definición mínima: lo justo para
   usarlo hoy, no el capítulo completo de la documentación.
3. **El comando, el HCL o la salida que corre.** El fragmento más pequeño que demuestra
   el punto, con su salida esperada.

Presentar el servicio antes que el problema produce gente que sabe recitar "Pub/Sub
desacopla productores de consumidores" y no sabe cuándo elegir Pub/Sub en vez de Cloud
Tasks.

### 4.2 Ningún comando ni ningún flag queda sin explicar

Esta es la regla más importante de la sección y no admite excepciones.

Cada comando de `gcloud`, cada bloque de HCL y cada `terraform` que aparezca en un lab o
en un apéndice se acompaña de qué hace, qué significan sus flags no obvios y qué pasa si
los omites o los pones mal. Los flags ya explicados (`--project`, `--region`) no se
repiten en cada aparición, pero **el primero de su tipo en el curso se explica entero**.

```bash
gcloud run deploy inv-api \
  --source . \
  --region us-central1 \
  --service-account inv-api-sa@inv-lab-472913.iam.gserviceaccount.com \
  --no-allow-unauthenticated
```

- `--source .` le pide a Cloud Build que construya la imagen desde el directorio actual
  y la suba a Artifact Registry antes de desplegar. Si omites el flag, `gcloud` espera
  una imagen ya construida en `--image` y falla pidiéndotela. Es cómodo, pero no es
  gratis en almacenamiento: cada despliegue deja una imagen más en el repositorio.
- `--service-account` fija la identidad con la que corre el servicio. **Si lo omites,
  Cloud Run usa la service account por defecto de Compute Engine, que suele traer el rol
  `roles/editor` sobre todo el proyecto** — es decir, el lab entero corriendo como
  administrador. Ese default es la causa número uno de labs que "funcionan" mientras
  enseñan exactamente lo contrario del privilegio mínimo.
- `--no-allow-unauthenticated` deja el servicio cerrado: solo lo invoca quien tenga
  `roles/run.invoker`. Sin el flag, `gcloud` te pregunta de forma interactiva y, si
  respondes que sí, publica la URL a Internet con `allUsers` como principal.

Ese nivel es el estándar. Un bloque de comandos sin desglose posterior es un error de
estilo, por más correcto que sea el comando.

### 4.3 Explica el porqué, no solo el cómo

Un paso sin justificación es un paso que el lector no puede adaptar cuando su caso real
difiera del ejemplo. Cada decisión relevante lleva su porqué, aunque sea media línea
entre paréntesis: por qué el state de Terraform vive en un bucket y no en disco, por qué
el lab crea una service account por servicio en vez de reutilizar una, por qué el lab
evita el load balancer global en lugar de enseñarlo.

Cuando el porqué es económico y no técnico —que en la nube pasa seguido— se dice
también: *"el lab no pone un Application Load Balancer global delante de Cloud Run porque
un forwarding rule global cuesta $0.025/h y Cloud Run ya te da una URL HTTPS con
certificado administrado sin cobrar nada por ella"*.

### 4.4 Nada de cajas negras prematuras

El curso enseña primero el mecanismo y después la comodidad:

- primero `gcloud` crudo (`gcloud services enable`, `gcloud iam service-accounts
  add-iam-policy-binding`, `gcloud asset search-all-resources`), **después** —y solo si
  simplifica de verdad— la consola web;
- primero Terraform con HCL escrito a mano y state explícito, **después** módulos,
  workspaces o Infrastructure Manager;
- primero leer el mensaje crudo que llega a un endpoint push, **después** el framework
  que lo abstrae.

No es que esas herramientas sean malas. Es que ocultan exactamente lo que el curso quiere
enseñar, y quien entiende el mecanismo aprende la capa de arriba en una tarde.

### 4.5 Analogías con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan diciendo
dónde se rompen. Un proyecto se parece a una carpeta de recursos *hasta que descubres
que también es la unidad de facturación, de cuota, de aislamiento de IAM y de borrado
atómico*. Una analogía que no se cierra genera bugs conceptuales que aparecen cinco
documentos después.

Cuidado especial con las cuatro más peligrosas del temario, que se desmontan en el mismo
párrafo en que aparecen:

- **una read replica no es un backup**;
- **Firestore no es "el DynamoDB de Google"** ni Bigtable "un Firestore grande";
- **una allow policy no tiene deny explícito** — para eso existen las IAM Deny policies,
  y son otro objeto;
- **una firewall rule de VPC no es un security group adjunto a una instancia**: se aplica
  por targets y tags en el ámbito de la red.

### 4.6 Densidad calibrada y sin techo de longitud

Esta guía **retira la regla anterior de "brevedad ante todo, 10–15 minutos de lectura"**.
Un documento dura lo que necesite para no dejar huecos. A cambio:

- Un concepto nuevo por vez. Si un bloque de código introduce tres cosas desconocidas, se
  parte en tres bloques.
- Repetir lo importante está bien. Los conceptos que sostienen el curso —zonal vs
  regional vs global, quién administra qué, la jerarquía de recursos, qué cobra por hora
  y qué entra en el Always Free— reaparecen con otras palabras. La repetición espaciada
  funciona; la enciclopedia no.
- Ninguna sección teórica supera las dos pantallas sin un diagrama, una tabla, un comando
  o una salida real.
- **Todo documento de más de ~400 líneas abre con un índice de salto rápido** (§6.2), para
  que siga sirviendo como chuleta de repaso aunque haya crecido.

### 4.7 Cierra los bucles

Si abres un paréntesis —*"esto lo vemos en `05`"*, *"el teardown de esto está en `L04`"*—
tiene que cerrarse en algún documento del curso, y con enlace real. Un pendiente que
nunca se resuelve es ruido y el lector deja de confiar en las promesas del texto. El mapa
de referencias cruzadas entre documentos es parte del producto.

---

## 5. 💻 Idioma del código, comandos y recursos

> **Regla normativa: todo lo que se ejecuta o se versiona va en inglés —nombres de
> recurso, identificadores de Terraform, labels, variables de entorno, service accounts,
> topics y servicios— y todos los comentarios van en español.**

| Elemento | Idioma | Ejemplo |
|---|---|---|
| Nombres de producto, feature y recurso GCP | Inglés (nombre oficial) | `Firewall rule`, `Managed Instance Group`, `Ordering key` |
| Identificadores de Terraform y claves de YAML | Inglés, `snake_case` | `google_storage_bucket.app_bucket`, `deletion_protection` |
| Nombres de recurso desplegado | Inglés, kebab-case | `inv-api`, `inv-events`, `inv-lab-tfstate` |
| Labels de GCP | Inglés, minúsculas y guiones bajos | `project=inv_lab`, `env=lab` |
| Comentarios dentro de bloques de código | Español | `# el bucket guarda el state; por eso lleva versioning` |
| Narrativa alrededor del código | Español | todo el texto fuera de los bloques |
| Términos técnicos consolidados | Inglés sin traducir | *stateful*, *eventually consistent*, *drift* |

> ⚠️ **Los labels de GCP no admiten mayúsculas ni la mayoría de los signos.** Clave y
> valor aceptan minúsculas, números, guiones y guiones bajos. Por eso el label de rastreo
> del laboratorio es `project=inv_lab` y no `Project=inv-lab`: no es una preferencia de
> estilo, es lo que la API acepta.

### 5.1 Nombres estables de la serie práctica

Estos valores son el baseline del laboratorio y no cambian entre documentos. Si un lab
necesita otro, lo declara y explica por qué.

| Elemento | Valor fijado |
|---|---|
| Región del lab | `us-central1` |
| Proyecto (ID de ejemplo en salidas) | `inv-lab-472913` |
| Cuenta de facturación de ejemplo | `01A2B3-C4D5E6-F7G8H9` |
| Configuración de `gcloud` | `inv-lab` |
| Label de rastreo obligatorio | `project=inv_lab` |
| Bucket de state de Terraform | `inv-lab-tfstate-472913` |
| Servicios de Cloud Run | `inv-api`, `inv-projector` |
| Service accounts | `inv-api-sa`, `inv-projector-sa`, `inv-pubsub-sa` |
| VPC y subnet del lab | `inv-lab-vpc`, `inv-lab-subnet` |
| Topic y DLQ de Pub/Sub | `inv-events`, `inv-events-dlq` |
| Base de datos de Firestore | `(default)`, en modo Native, ubicación `nam5` |

**Nunca uses `latest`, `*` ni rangos donde el curso fija un valor exacto**, ni en tags de
imagen, ni en versiones del provider de Terraform, ni en runtimes. Un
`google = "~> 5.0"` en un ejemplo destruye la reproducibilidad que el curso intenta
enseñar: el provider se pinnea con versión exacta y se dice cuál.

---

## 6. 🧱 Plantilla de los documentos temáticos (`01`–`13`)

1. **Título** — `# NN — Tema` (dos dígitos, sin emoji en el título).
2. **Blockquote de encabezado** — objetivo del documento en una o dos líneas, qué se
   asume leído, y **`Vigencia:`** con la fecha en que se verificaron los enlaces y el
   comportamiento de los servicios descritos. Ese campo es obligatorio: quien abre `04`
   sin pasar por el README tiene que saber qué tan reciente es lo que lee.
3. **Índice de salto rápido** — si el documento pasa de ~400 líneas (§6.2).
4. **Secciones `##` numeradas**, una por concepto o servicio, con emoji funcional. Cuando
   el documento cubre bloques claramente separables (`03` separa storage de SQL, `05`
   separa IAM de jerarquía y de KMS/secretos) se usan divisores `# Parte I — …` en
   romanos, **manteniendo la numeración arábiga de `##` continua** a través de las partes.
5. **⚠️ Errores frecuentes** — sección opcional pero recomendada: la confusión típica de
   entrevista sobre ese tema, con la versión precisa al lado.
6. **🧠 Preguntas rápidas** — cierre obligatorio, sin respuestas visibles (§8).
7. **📚 Referencias oficiales** — cierre obligatorio (§9).

**Excepciones declaradas a la plantilla:**

- `README.md` — índice, mapa mental y tabla de asociaciones.
- `10-preguntas-entrevista-y-mapa-mental.md` — simulación de entrevista completa:
  preguntas `P#` sin respuesta inline (van al solucionario) y escenarios de arquitectura
  que **sí** conservan su solución desarrollada, porque son ejemplos resueltos y no
  autochequeo de memoria.
- `14-respuestas.md` — solucionario centralizado. No lleva "Preguntas rápidas" ni
  referencias propias.
- `l00-idea-lab-practico.md` — encuadre e introducción de la serie práctica (§7.1).

### 6.2 Índice de salto rápido

Formato fijo, justo después del blockquote de encabezado:

```markdown
**Salto rápido:** [Region](#2--region) · [Zone](#3--zone) ·
[VPC — alcance global](#4--vpc--alcance-global) · [Subnet](#6--subnet) ·
[Preguntas rápidas](#-preguntas-rápidas)
```

**Cómo se calcula un ancla de GitHub**, porque es donde se rompen estos índices: se pasa
el encabezado a minúsculas, se eliminan los caracteres que no son letra, número, espacio,
guion o guion bajo —lo que se lleva por delante el punto de la numeración, el emoji, los
backticks y los dos puntos— y por último los espacios restantes se convierten en guiones.
Cada carácter borrado **deja su espacio**, y de ahí salen los guiones dobles:

| Encabezado | Ancla |
|---|---|
| `## 2. 🧱 Region` | `#2--region` |
| `## 4. 🧱 VPC — alcance global` | `#4--vpc--alcance-global` |
| `## 8. 🧱 \`terraform plan\`` | `#8--terraform-plan` |
| `## 🧠 Preguntas rápidas` | `#-preguntas-rápidas` |

Fíjate en el último: un encabezado que empieza por emoji genera un ancla que **empieza
por guion**. Verifica los anclas al escribirlos; un índice con enlaces rotos es peor que
no tener índice.

---

## 7. 🧪 La serie práctica: labs (`lNN-`) y apéndices (`aNN-`)

Los labs y los apéndices siguen la plantilla de §6 con los añadidos de abajo, y sin
ninguna excepción de tono ni de pedagogía: aquí la regla de §4.2 —ningún comando ni flag
sin explicar— se aplica con más rigor que en ninguna otra parte, porque son los
documentos que el lector ejecuta contra un proyecto que le cobra.

### 7.1 La doctrina de reparto es materia editorial, no solo de alcance

**Regla de arquitectura del curso, y se enuncia en cada lab que la toque:**

> En la nube se practica lo que **solo** existe en la nube. Todo lo demás se practica en
> local con contenedores, gratis y con un ciclo de iteración de segundos.

Un tema entra en el laboratorio de pago solo si cumple al menos una condición: lo hace
cumplir Google y nadie más (IAM, jerarquía de recursos, habilitación de APIs, routing de
VPC), el fallo real difiere del emulado (`deletion_protection`, entrega push con OIDC,
dead-letter, cuotas), solo se conoce pagando (informes de facturación, presupuestos,
Always Free) o es la costura entre tu código y GCP (service accounts, ADC, Workload
Identity Federation, service agents).

Y la contrapartida se escribe con la misma claridad: **cuando el curso excluye algo
—GKE, Compute Engine, Cloud SQL, un load balancer global, un microservicio de negocio—
dice por qué, cuánto costaría y dónde se practica en su lugar.** Una exclusión sin
justificación se lee como un hueco del temario; una exclusión justificada es contenido.
El desarrollo completo de esta doctrina vive en `l00-idea-lab-practico.md` y el resto de
documentos remite ahí en vez de reabrir la discusión.

### 7.2 Labs `lNN-tema.md`

Título `# LNN — Tema`. Son acumulativos y se hacen en orden. Además de lo de §6:

> 🧭 **Cuántos labs tiene la serie lo decide GCP, no la simetría con otro curso.** Un lab es una
> sesión de dos o tres horas con un teardown propio, y se parte en dos en cuanto mezcla dos
> diagnósticos distintos —el contrato de Cloud Run y la entrega de eventos, por ejemplo— o en
> cuanto un tema que en otra nube sería caro aquí resulta gratis y merece practicarse en vez de
> solo leerse, como pasa con la red. El recuento vigente y su justificación viven en
> `l00-idea-lab-practico.md` §7.1; esta guía no lo duplica.

- **Cabecera con contrato económico y temporal:** costo esperado con su unidad y su
  relación con el Always Free, duración estimada, prerrequisitos (qué lab anterior debe
  estar hecho) y qué queda encendido al terminar.
- **Teardown escrito antes que el despliegue.** Ningún lab introduce un recurso sin que el
  documento diga, en ese mismo punto, cómo se destruye y cómo se verifica que murió. Si el
  recurso sobrevive a un `terraform destroy` —o si su `deletion_protection` lo bloquea—,
  se dice ahí, no en el lab de teardown.
- **Reproducir el error antes de arreglarlo.** Cuando el lab enseña un fallo
  —`SERVICE_DISABLED` por una API no habilitada, un `PERMISSION_DENIED` por el binding en
  el recurso equivocado, un `destroy` que falla por un bucket no vacío— se provoca a
  propósito, se muestra la salida literal y solo después la corrección.
- **📋 Checklist de salida** en formato `- [ ]` antes del cierre, con comprobaciones
  ejecutables. Es la única lista de tareas admitida en el curso y no son ejercicios: son
  criterios de terminado verificables.
- **🏁 La señal de que quedó bien** — una frase de cierre que describe el estado correcto:
  *"`gcloud asset search-all-resources --scope=projects/inv-lab-472913` no devuelve un
  solo recurso facturable, y el informe de facturación confirma $0.00 a las 48 horas"*.

### 7.3 Apéndices `aNN-tema.md`

Título `# ANN — Tema`. Material de consulta, sin orden ni prerrequisitos. No llevan costo,
duración ni checklist de salida —con la excepción declarada de `A04`, que es una rutina para
ejecutar y sí los lleva (§8.1)—. Abren siempre con índice de salto rápido (son de
consulta: nadie los lee linealmente) y organizan el contenido en secciones cortas e
independientes, cada una autosuficiente. Sí llevan "Preguntas rápidas" y "Referencias
oficiales".

---

## 8. 🧠 Preguntas rápidas y la rutina de recurso

Este curso **no lleva el aparato de ejercicios de los cursos narrativos del repositorio**: nada
de 20 a 35 ejercicios graduados con 🟢🟡🟠🔴 por documento. Lleva dos cosas distintas y mucho más
pequeñas: las **Preguntas rápidas** que cierran cada documento, y **una única rutina ejecutable**
definida en `A04` y aplicada donde haga falta.

`CLAUDE.md` fija como norma por defecto de 20 a 30 ejercicios graduados por sección, y admite
expresamente que **la guía de cada curso reemplace ese aparato por otro formato de evaluación,
siempre que lo diga y diga por qué**. Esto es ese reemplazo, y la razón es la naturaleza del
material: repaso para una entrevista, no un curso narrativo con proyecto integrador. La regla, en
tres líneas:

```text
capítulos teóricos  →  SOLO preguntas rápidas. Nunca ejercicios.
apéndices y labs    →  preguntas rápidas + lo único ejecutable del curso
respuestas          →  SIEMPRE en 14-respuestas.md, nunca junto a la pregunta
```

**Si alguna vez entra un ejercicio, entra por apéndice o por lab, jamás por un capítulo
teórico**, y solo con estas dos formas, que ya existen y no hay que inventar otras: la **rutina
de recurso** de `A04` (§8.1) y el **`📋 Checklist de salida`** de cada lab (§7.2), que no es una
lista de ejercicios sino de criterios de terminado verificables. Cualquiera de las dos declara su
costo y su teardown, como cualquier otra cosa que se ejecute en este curso.

### 8.1 La rutina de recurso (`A04`)

Es la excepción declarada a "aquí no se ejecuta nada", y existe porque hay un aprendizaje que
ninguna pregunta de memoria produce: crear, inspeccionar, modificar y destruir un recurso
cualquiera desde cero, primero con `gcloud` y después desde un SDK.

Reglas para escribirla:

- **La forma es fija y se repite idéntica para todos los servicios**: crear → inspeccionar con
  `--format=json` → modificar → destruir → verificar qué quedó vivo → repetir desde el SDK. Que
  sea siempre la misma es el punto; la variación está en el servicio, no en el procedimiento.
- **El puente CLI→API se enseña con `--log-http`**, no con dos páginas de documentación paralela.
  El lector tiene que ver la petición REST que produce su propio comando antes de escribir la
  primera línea de código.
- **Cada vuelta declara su costo** con la misma honestidad que un lab (§7.2), y se eligen
  recursos cuyo ciclo completo sea gratis o de centavos.
- **El entregable es el script y el fragmento de código anotados**, no el recurso. Eso se dice
  explícitamente: lo que sobrevive a la sesión es el apunte.
- **Los ejemplos de SDK van en un solo lenguaje** —el que fije `l00-idea-lab-practico.md` §11— y
  se declara que el lector puede usar otro. No se escriben cuatro versiones del mismo fragmento.
- Se aplican, con la misma forma, dentro de los drills de `l00` §9.

### 8.2 Preguntas rápidas

Cierran todos los documentos. Son preguntas para contestar de memoria o razonando, no trabajos
para resolver con código.

- **Cantidad: 10 a 15 por documento temático o lab, y de 6 a 12 en un apéndice**,
  calibrada por cuántas cosas distintas enseña el documento y se pueden comprobar por
  separado — nunca por su longitud. La banda admite desbordarse **cuando el documento
  cubre varias Partes o es un catálogo**: `05` puede pasar de 15 porque abarca IAM,
  jerarquía de recursos, Workload Identity, KMS, Secret Manager y Organization Policies, y
  un apéndice de trampas de costo puede pasar de 12 porque cada trampa es comprobable por
  su cuenta. Fuera de esos casos, subir de 15 exige poder decir qué comprueba cada
  pregunta nueva que no comprobara ya otra.
- **Directas y verificables.** Cada pregunta tiene respuesta corta y objetiva localizable
  en el propio documento. Nunca "reflexiona sobre…".
- **Reparto sugerido**, para que la sección entrene algo más que memoria: aproximadamente
  la mitad de definición o distinción ("¿una subnet puede abarcar dos regiones?"), un
  tercio de decisión o comparación ("¿cuándo usarías Cloud Tasks en lugar de Pub/Sub?") y
  el resto de diagnóstico ("¿cómo depurarías una push subscription que devuelve 403?").
  **Dos documentos vecinos no deberían tener el mismo reparto.**
- **Sin respuesta en el documento, con solucionario centralizado.** Todas las respuestas,
  explicadas, viven en `14-respuestas.md`, agrupadas por documento y numeradas igual que
  la pregunta original (la pregunta 3 de `04` se responde en la entrada "04 → 3"). Quien
  agregue, elimine o reordene una pregunta **debe reflejar el mismo cambio en
  `14-respuestas.md` en la misma edición**.
- **Orden libre**, por relevancia de entrevista, no correlativo a las secciones.

---

## 9. 🧷 Vocabulario visual: reglas y callouts

Vocabulario deliberadamente más reducido que el de los cursos narrativos del repositorio,
pero ya no limitado a tres recursos.

### 9.1 Regla o mnemotecnia (bloque `text`)

Para una asociación mental que vale la pena aislar, en especial con forma de comparación o
ecuación corta. Se etiqueta antes con una línea breve: "Regla:", "Regla mental:", "Regla
de entrevista:" o "Regla de arquitectura:".

```text
VPC       = global
Subnet    = regional
Instancia = zonal
```

### 9.2 Frase de respuesta correcta (blockquote `>`)

Para la única frase que un entrevistado debería decir en voz alta, normalmente después de
mostrar la simplificación incorrecta. Sirve igual para blindar contra la mala respuesta
("Nunca respondas: > …") que para dar la buena ("Mejor: > …"). También admite etiqueta
corta de énfasis —"Regla importante:", "Punto importante:"— cuando lo que sigue es una
única frase definitoria o correctiva.

Prueba práctica: si cabe en una oración y corrige o fija un concepto, va en blockquote; si
es lista, ecuación o comparación de dos o más líneas, va en bloque `text`.

### 9.3 Callouts admitidos

Se usan en blockquote, con negrita en la etiqueta, y solo cuando aportan. Ninguno es
obligatorio en ningún documento.

- ⚠️ **Advertencia.** Ignorarlo rompe algo en producción, cuesta dinero o produce una
  respuesta de entrevista objetivamente incorrecta. Uso escaso; nunca decorativo.
- 🧠 **Modelo mental.** La frase que hay que llevarse, no el detalle.
- 💡 **Truco o atajo** que ahorra tiempo real (un `--format` o un `--filter` que evita
  cinco comandos, `--impersonate-service-account` en vez de descargar una key).
- 🩺 **Diagnóstico.** El comando que confirma o descarta una hipótesis.
- 💰 **Costo.** Lo que cobra ese recurso, con unidad y con qué lo dispara, o la cuota del
  Always Free que lo cubre. Obligatorio la primera vez que un documento introduce algo que
  cobra por hora.
- 📝 **Contexto.** Por qué Google hace algo así, o qué cambió recientemente y por qué la
  respuesta "clásica" que el lector pueda encontrar en fuentes viejas ya no aplica
  (Deployment Manager frente a Terraform es el caso canónico).
- 📚 **Referencia inline.** El enlace útil justo donde nace la duda, sin esperar al cierre.

**Marcadores ✅ y ❌.** Se admiten como señal de sí/no dentro de tablas y de bloques
` ```text ` de comparación. Nunca como decoración en prosa ni en un encabezado.

Fuera de esta lista, de ✅/❌ y de los emojis de encabezado de §3, **no se usan otros
emojis**. Nada de 🪦, 💸, 🔥, ⭐, 🚨 ni escalas de dificultad: pertenecen a los cursos
narrativos del repositorio.

### 9.4 Autopsia de un fallo

Cuando un lab documenta un fallo real —y varios lo hacen— la estructura es:

1. Síntoma, con la salida literal del comando.
2. Qué lo provocó, hasta la línea del HCL o el binding concreto.
3. La hipótesis y el comando que la confirma o la descarta.
4. La corrección, distinguiendo el parche que desbloquea hoy de la solución que uno haría
   con calma.
5. La prevención: la comprobación, el label o el checklist que evita la repetición.

Dos reglas de método que atraviesan la serie práctica: **una variable a la vez** y
**reproducir antes de reparar**. Y los anti-patrones se nombran sin piedad:
`roles/owner` "para salir del paso", `allUsers` en un servicio de Cloud Run "porque el
`curl` no andaba", descargar una service account key en vez de usar impersonation, y
tocar en la consola lo que Terraform administra.

---

## 10. 📚 Bibliografía, referencias y enlaces

### 10.1 Enlaces externos

- **Solo documentación oficial de Google Cloud** en la sección de referencias:
  `cloud.google.com` y `docs.cloud.google.com`, las páginas de pricing por producto,
  la calculadora y las notas de lanzamiento. El curso no cita libros, blogs ni videos.
- **Excepción declarada: Terraform.** `09-terraform-iac.md` y los labs que usan Terraform
  citan también `registry.terraform.io/providers/hashicorp/google/…` y
  `developer.hashicorp.com/terraform/…` como fuente primaria, porque Terraform no es una
  herramienta de Google: es el estándar de facto de IaC en GCP y su documentación de
  provider es la referencia autorizada de cada recurso. Es la única excepción a "solo
  documentación de Google".
- **Herramientas de terceros que el laboratorio local usa** (contenedores, `kind`,
  emuladores no oficiales) van en una **subsección aparte marcada como opcional**, nunca
  mezcladas con la documentación oficial.
- **URLs completas y clicables**, nunca solo el dominio, y **una URL por concepto
  cubierto**, no un enlace genérico a toda la documentación del producto cuando existe la
  página específica. Si el documento explica `deletion_protection`, el enlace es a la
  página del recurso, no a la portada de Firestore.
- **No se inventan URLs.** Un enlace que no se pudo verificar no se escribe: se cita el
  nombre exacto de la página y se deja el enlace al índice del producto. Inventar una ruta
  plausible de `cloud.google.com` es el error más caro de este curso, porque parece
  correcta hasta que alguien la abre en una entrevista.
- **No se inventan precios.** Los precios de GCP viven en tablas que la documentación
  renderiza dinámicamente y cambian por región. Se cita el número solo cuando se verificó
  contra la página oficial de pricing, con su unidad exacta (GiB, no GB, cuando la fuente
  dice GiB); si no se verificó, se dice "verifica en la calculadora" y se enlaza, en vez
  de escribir una cifra plausible.

### 10.2 Enlaces internos entre documentos

Son parte del producto, no un adorno, y hacen cumplir §4.7.

- **Formato:** enlace Markdown relativo al archivo, con el número del documento en el
  texto visible:

  ```markdown
  ver [`05` — evaluación de allow policies](05-seguridad-iam-jerarquia-kms-secretos.md)
  ```

- **Con ancla cuando la sección destino existe y es estable:**

  ```markdown
  [`09` §12 — drift](09-terraform-iac.md#12--drift)
  ```
- **Cada documento temático enlaza al menos a los dos documentos con los que más se
  toca**, y todo lab enlaza al documento teórico que sustenta lo que practica y al
  apéndice que lo complementa.
- **Al renombrar un archivo o un encabezado se revisan los enlaces entrantes en la misma
  edición.** Un enlace roto dentro del propio curso es peor que un enlace externo caído:
  el externo tiene disculpa, el interno no.

### 10.3 Vigencia

El README declara la fecha de revisión general y **cada documento la repite en su
blockquote de encabezado**. Cuando un documento incorpora un cambio reciente de GCP —el
fin de soporte de Deployment Manager, los spend cap budgets, un cambio de cuotas del
Always Free— se marca con 📝 en el propio texto, para que quien repasa sepa que puede no
coincidir con las respuestas "clásicas" de fuentes más viejas.

---

## 11. 🔗 Coherencia entre documentos

- **No contradecir documentos anteriores.** Si `03` establece que una read replica de
  Cloud SQL es para read scaling y la configuración regional es para failover, `10` puede
  matizarlo, nunca contradecirlo.
- **Terminología estable.** Si `01` dice "VPC de alcance global", el resto del curso no lo
  llama "red virtual global" ni abrevia distinto.
- **Los labs son acumulativos y lo declaran.** Cada lab dice en su cabecera qué deja
  encendido y el siguiente asume exactamente ese estado. Si un lab rompe la cadena, lo
  dice explícitamente.
- **Los nombres del baseline de §5.1 mandan.** Cualquier desviación se declara con ⚠️ en el
  documento que la introduce.
- **Fuentes de verdad, en orden:** (1) **esta guía y los demás documentos de `prompts/`**,
  que según la regla de precedencia de `CLAUDE.md` mandan sobre las normas por defecto del
  repositorio en todo lo que declaren explícitamente; (2) `CLAUDE.md` de la raíz, para todo lo
  que esta guía no toca; (3) `l00-idea-lab-practico.md` para el alcance y la doctrina de reparto
  de la serie práctica; (4) `README.md` para orden de lectura y mapa; (5) documentos ya
  publicados; (6) decisiones explícitas del chat actual.

---

## 12. ✅ Checklist antes de dar por cerrado un `.md`

- [ ] Sigue la plantilla de §6 (o está declarado como excepción: README, `10`, `14`, `l00`).
- [ ] Encabezado con objetivo y **`Vigencia:`**; índice de salto rápido si pasa de ~400 líneas.
- [ ] Tono semi formal y cálido, tuteo latinoamericano, humor casi ausente (§2).
- [ ] Emoji funcional en `##`, ninguno en `###`, y solo los callouts de §9.3.
- [ ] **Ningún comando ni flag queda sin explicar** (§4.2). Ningún bloque de código sin desglose.
- [ ] El problema se plantea antes que el servicio (§4.1) y cada decisión lleva su porqué (§4.3).
- [ ] Sin prosa telegrama: una o dos frases aisladas por sección como mucho (§3).
- [ ] Tablas solo para comparar o mapear, máximo cuatro columnas, sin celdas que necesiten explicación.
- [ ] No asume que el lector conoce AWS ni introduce mapeos AWS→GCP (§3.1).
- [ ] Nombres del baseline de §5.1 respetados; sin `latest`, sin `*`, sin rangos de versión de provider.
- [ ] Se nombra explícitamente cuando una respuesta común de entrevista es una sobregeneralización.
- [ ] Todo lo que cobra por hora aparece con precio y unidad, o con la cuota de Always Free que lo cubre (💰), y toda exclusión del lab dice por qué y dónde se practica en su lugar (§7.1).
- [ ] Ningún precio ni URL sin verificar (§10.1).
- [ ] En labs: teardown escrito junto al recurso, errores reproducidos antes de corregirlos, checklist de salida ejecutable y cierre con **🏁 La señal de que quedó bien**.
- [ ] Cierra con **Preguntas rápidas** (10–15; apéndices 6–12), sin respuestas, con reparto distinto al del documento vecino (§8.2).
- [ ] No introduce ejercicios graduados 🟢🟡🟠🔴: lo único ejecutable del curso es la rutina de recurso de `A04` (§8.1).
- [ ] Si tocaste alguna pregunta, actualizaste `14-respuestas.md` en la misma edición.
- [ ] Cierra con **Referencias oficiales**: URLs completas, verificadas, una por concepto, solo documentación oficial de Google (salvo la excepción de Terraform); terceros en subsección opcional aparte.
- [ ] Enlaces internos a los documentos con los que más se toca, y ningún enlace interno roto (§10.2).
- [ ] No contradice ningún documento anterior (§11).
