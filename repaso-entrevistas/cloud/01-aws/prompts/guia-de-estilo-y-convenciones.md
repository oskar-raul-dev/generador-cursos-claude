# ✍️ Guía de estilo, tono y convenciones
## AWS Core Refresh — repaso para entrevistas y serie práctica de labs

Esta guía es la fuente de verdad editorial de `repaso-aws-entrevistas/`. Cualquier
chat que produzca o edite un `.md` de este curso la sigue. Su objetivo es que los
veintiún documentos —trece teóricos, cuatro labs, dos apéndices, el encuadre de la
serie práctica y el README— se lean como escritos por la misma mano y apunten al
mismo lugar: **que el lector pueda explicar y defender una decisión de arquitectura
en AWS, no que recuerde nombres de servicios**.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que
mañana tiene una entrevista de arquitectura y pasado mañana tiene que diseñar de
verdad el sistema del que habló.

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien reconozca, explique, compare y decida.**

No enseñamos AWS "completo": el catálogo tiene más de doscientos servicios y
memorizarlos no hace a nadie mejor arquitecto. Repasamos el vocabulario, los
mecanismos y los matices que separan a quien entiende el modelo de quien aprendió la
lista. En la serie práctica, además, formamos una capacidad concreta: **encender
infraestructura desde la CLI, romperla a propósito, diagnosticarla y destruirla con
certeza**.

El filtro para cada párrafo es este: **¿esto ayuda a reconocer, explicar, comparar o
decidir?** Si no, sobra. Aunque esté muy bien escrito.

Y el corolario, repetido tantas veces como haga falta:

> Cada comando se explica. Cada flag se explica. Cada decisión responde a
> "¿por qué estamos haciendo esto y qué pasaría si no?".

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, de colega a colega. Piensa en alguien
que ya se quemó con esto —un `AccessDenied` que no era de IAM, un `DELETE_FAILED` a
las once de la noche, una factura con un NAT Gateway olvidado— y te lo explica con
paciencia y sin solemnidad de manual corporativo.

Es un cambio deliberado respecto de la versión anterior de esta guía, que pedía
sobriedad absoluta y prohibía todo emoji. La sobriedad de fondo se conserva —esto
sigue siendo material de entrevista, no una charla— pero el registro helado producía
documentos que se leían como una hoja de referencia y no como una explicación.

Cómo se ve en la práctica:

- **Tuteo latinoamericano, siempre.** Le hablas al lector de "tú": *"fíjate en qué
  cambia el `Replacement` de la tabla"*, *"si esto te suena raro, es porque todavía
  no vimos el policy evaluation; aguanta dos secciones"*. Nada de voseo, nada de
  "usted", nada de impersonal permanente ("se debe configurar…") que enfría el texto.
- **Semi formal.** Cercano, pero no chat. Frases completas, puntuación correcta,
  cero abreviaturas de mensajería.
- **Humor mínimo y seco.** Un 😉 bien puesto para desdramatizar una fricción real
  —el precio del control plane de EKS, la fe ciega en `--force`— y nada más. Regla
  práctica: **como mucho un desdramatizador por documento**, y si no fluye solo, se
  borra. Este curso no es el de Docker: aquí el humor es la excepción, no el registro.
- **Honesto sobre las simplificaciones.** Cuando la respuesta común de entrevista es
  una sobregeneralización —"DynamoDB es eventually consistent", "Multi-AZ nunca sirve
  lecturas", "un Change Set garantiza que el deploy funciona"— se nombra la
  simplificación y se da la versión precisa. **Este es el recurso pedagógico central
  del curso**, por encima de la analogía y del ejemplo.
- **Honesto sobre el dinero.** Cada recurso que cobra por hora se nombra con su
  precio y su unidad. No hay eufemismos tipo "costo reducido": o es $0.00, o es
  $0.045/h, o se dice que no se verificó.
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca infantilizamos.
  "Como para un bebé" significa **cero ambigüedad**, no menos profundidad — ver §4.
- **Sin relleno motivacional.** Sin "¡tú puedes!", sin "vas a dominar AWS". Quien lee
  ya sabe por qué está repasando.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no sea código
  o salida de terminal.
- **Los nombres de servicios, features y términos del stack se quedan en inglés**
  cuando son el nombre real de la cosa: *Region*, *Availability Zone*, *Security
  Group*, *Change Set*, *stateful*, *eventually consistent*, *hot partition*,
  *fan-out*, *visibility timeout*, *cold start*, *drift*. Traducirlos forzadamente
  ("zona de disponibilidad", "conjunto de cambios") confunde y no es lo que el lector
  va a ver en la consola, en la CLI ni en los mensajes de error. Los que ya tienen
  traducción asentada —región, cola, rol, política— pueden alternar con naturalidad;
  lo importante es no inventar vocabulario.
- **Markdown siempre.** Nada de HTML embebido.
- **Estructura visual primero, pero la prosa ya no es el último recurso.** El orden
  de preferencia sigue siendo diagrama ASCII → tabla → lista → párrafo *para exponer
  una relación entre cosas*. Pero el **porqué** de una decisión se escribe en prosa:
  una tabla no puede explicar por qué un `DeletionPolicy: Retain` te deja un bucket
  huérfano después de un `delete-stack` aparentemente exitoso. La versión anterior de
  esta guía decía "prosa mínima" y produjo documentos donde el mecanismo estaba, pero
  la razón no.
- **Nada de prosa telegrama.** Una frase corta y sola, con líneas en blanco a ambos
  lados, es un buen golpe de ritmo. Tres seguidas ya no son ritmo: son un telegrama, y
  el lector deja de encontrar el argumento porque no hay párrafo donde buscarlo.
  Regla práctica: **una frase aislada por sección, dos si la sección es larga**.
- **Diagramas ASCII en bloques ` ```text `.** Es el recurso visual principal del
  curso, y se usa sin timidez para jerarquías, flujos de tráfico, arquitecturas y
  máquinas de estados. Simples: cajas, flechas, texto. Sin arte ASCII elaborado.
- **Tablas solo para comparar o mapear**, con tres o cuatro columnas como norma:
  "SG vs NACL", "Multi-AZ vs read replica", "qué cobra por hora y qué no",
  necesidad→servicio. **La excepción legítima es la matriz que enfrenta cuatro
  alternativas a un criterio** —SQS vs SNS vs EventBridge vs Kinesis en `07`, las cuatro
  estrategias de DR en `11`—, donde cinco columnas son la forma natural del contenido y
  partirlas en dos tablas lo empeora. **Si necesitas explicar una celda, ya no es una
  tabla**: es una lista con subtítulos o un par de párrafos. Nunca se narra en tabla.
- **Salida de terminal literal.** Cuando se muestra lo que imprime un comando, se
  muestra tal como sale, en bloque ` ```text `, sin embellecer y sin recortar la parte
  incómoda. El error real enseña más que el error editado. Los identificadores de
  cuenta se anonimizan siempre como `111122223333`, y los ARN mantienen su forma real.
- **Encabezados con emoji, con moderación.** Uno por sección `##` numerada, ninguno en
  las subsecciones `###` — con una excepción declarada: los encabezados de la sección de
  ejercicios de labs y apéndices llevan su marcador de dificultad (§8.2), porque ahí el
  emoji **es** el dato.
 El emoji es funcional: señala de qué tipo es la sección
  (🧭 encuadre, 🧱 mecanismo, ⚖ comparación, 🩺 diagnóstico, 💰 costo, 🧪 verificación,
  📋 checklist de salida, 🏁 cierre de lab, 📚 referencias). Un documento que parece un teclado de emojis pierde autoridad.

---

## 4. 🎓 Pedagogía: "como para un bebé"

Esta sección es la que más define el curso desde esta versión de la guía, y viene
prestada del curso `docker-container-legacy`. El principio se enuncia así:

> **"Como para un bebé" significa cero ambigüedad, no menos profundidad.**

No es escribir más simple: es no dejar ningún hueco donde el lector tenga que
adivinar. Se explica qué es un execution role, en qué se diferencia de una
resource-based policy y qué error exacto sale cuando confundes uno con el otro. No se
dice "asigna el rol correcto" y se sigue adelante.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar el servicio, muestra el dolor que
   resuelve. *"Tu Lambda escribe en DynamoDB, el reintento la invoca dos veces y
   ahora tienes el mismo movimiento de inventario contado dos veces. ¿Qué le pones
   delante?"*
2. **El mecanismo después.** Ahora sí, el nombre y la definición mínima: lo justo
   para usarlo hoy, no el capítulo completo del User Guide.
3. **El comando o el template que corre.** El fragmento más pequeño que demuestra el
   punto, con su salida esperada.

Presentar el servicio antes que el problema produce gente que sabe recitar "SQS
desacopla productores de consumidores" y no sabe cuándo elegir SQS en vez de
EventBridge.

### 4.2 Ningún comando ni ningún flag queda sin explicar

Esta es la regla más importante de la sección y no admite excepciones.

Cada comando de la CLI que aparezca en un lab o en un apéndice se acompaña de qué
hace, qué significan sus flags no obvios y qué pasa si los omites o los pones mal.
Los flags obvios (`--profile`, `--region` una vez explicados) no se repiten en cada
aparición, pero **el primero de su tipo en el curso se explica entero**.

```bash
aws cloudformation create-change-set \
  --stack-name inv-lab-data \
  --change-set-name add-ttl \
  --change-set-type UPDATE \
  --template-body file://storage.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

- `--change-set-type UPDATE` le dice a CloudFormation que el stack ya existe. Si
  pones `CREATE` sobre un stack vivo obtienes `AlreadyExistsException`; si omites el
  flag, el default es `CREATE` y el error te llega igual.
- `--template-body file://` lee el archivo local. El prefijo `file://` no es
  decorativo: sin él, la CLI interpreta la ruta como el contenido literal del
  template y falla con un error de parseo que no menciona el archivo.
- `--capabilities CAPABILITY_NAMED_IAM` es el reconocimiento explícito de que el
  template crea recursos IAM con nombre propio. Sin él, CloudFormation rechaza el
  change set con `InsufficientCapabilitiesException` — no es un permiso de IAM, es una
  confirmación que la API te exige a ti.

Ese nivel es el estándar. Un bloque de comandos sin desglose posterior es un error de
estilo, por más correcto que sea el comando.

### 4.3 Explica el porqué, no solo el cómo

Un paso sin justificación es un paso que el lector no puede adaptar cuando su caso
real difiera del ejemplo. Cada decisión relevante lleva su porqué, aunque sea media
línea entre paréntesis: por qué el lab usa `Code.ZipFile` inline y no un bucket de
artefactos, por qué la tabla es on-demand y no provisioned, por qué el lab evita el
NAT Gateway en lugar de enseñarlo.

Cuando el porqué es económico o histórico y no técnico —que en AWS pasa seguido— se
dice también: *"el lab no monta el proyecto en EKS porque el control plane cuesta
$0.10/h y no te enseña ni una línea de Kubernetes que no aprendas gratis con `kind`"*.

### 4.4 Nada de cajas negras prematuras

El curso enseña primero el mecanismo y después la comodidad:

- primero la CLI cruda (`aws cloudformation create-stack`, `describe-stack-events`),
  **después** —y solo si simplifica de verdad— envoltorios como AWS SAM o CDK;
- primero el template YAML completo, **después** los módulos y nested stacks;
- primero leer el evento crudo de un event source mapping, **después** el framework
  que lo abstrae.

No es que esas herramientas sean malas. Es que ocultan exactamente lo que el curso
quiere enseñar, y quien entiende el mecanismo aprende la capa de arriba en una tarde.

### 4.5 Analogías con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan
diciendo dónde se rompen. Una VPC se parece a una red privada de datacenter *hasta
que descubres que el routing entre subnets no se puede bloquear con route tables*.
Una analogía que no se cierra genera bugs conceptuales que aparecen cinco documentos
después.

Cuidado especial con las tres más peligrosas del temario, que se desmontan en el
mismo párrafo en que aparecen:

- **una read replica no es un backup**;
- **DynamoDB no es "un MongoDB de AWS"**;
- **un Security Group no es un firewall de subnet** (eso es el NACL, y es stateless).

### 4.6 Densidad calibrada y sin techo de longitud

Esta guía **retira la regla anterior de "brevedad ante todo, 10–15 minutos de
lectura"**. Un documento dura lo que necesite para no dejar huecos. A cambio:

- Un concepto nuevo por vez. Si un bloque de código introduce tres cosas
  desconocidas, se parte en tres bloques.
- Repetir lo importante está bien. Los conceptos que sostienen el curso —regional vs
  zonal vs global, quién administra qué, stateful vs stateless, qué cobra por hora—
  reaparecen con otras palabras. La repetición espaciada funciona; la enciclopedia no.
- Ninguna sección teórica supera las dos pantallas sin un diagrama, una tabla, un
  comando o una salida real.
- **Todo documento de más de ~400 líneas abre con un índice de salto rápido** (§6.2),
  para que siga sirviendo como chuleta de repaso aunque haya crecido.

### 4.7 Cierra los bucles

Si abres un paréntesis —*"esto lo vemos en `05`"*, *"el teardown de esto está en
L04"*— tiene que cerrarse en algún documento del curso, y con enlace real. Un
pendiente que nunca se resuelve es ruido y el lector deja de confiar en las promesas
del texto. El mapa de referencias cruzadas entre documentos es parte del producto.

---

## 5. 💻 Idioma del código, comandos y recursos

> **Regla normativa: todo lo que se ejecuta o se versiona va en inglés —nombres de
> recurso, logical IDs, tags, variables de entorno, nombres de stack, funciones y
> tablas— y todos los comentarios van en español.**

| Elemento | Idioma | Ejemplo |
|---|---|---|
| Nombres de servicio, feature y recurso AWS | Inglés (nombre oficial) | `Security Group`, `Change Set`, `Availability Zone` |
| Logical IDs y claves en YAML/JSON | Inglés | `AppBucket`, `EventsTable`, `PK`, `SK` |
| Nombres de stack, función, tabla, cola | Inglés, kebab-case | `inv-lab-data`, `inv-lab-projector`, `inv-lab-events` |
| Comentarios dentro de bloques de código | Español | `# el TTL borra en un plazo, no al segundo` |
| Narrativa alrededor del código | Español | todo el texto fuera de los bloques |
| Términos técnicos consolidados | Inglés sin traducir | *stateful*, *eventually consistent*, *drift* |

### 5.1 Nombres estables de la serie práctica

Estos nombres son el baseline del laboratorio y no cambian entre documentos. Si un
lab necesita otro, lo declara y explica por qué.

| Elemento | Valor fijado |
|---|---|
| Región del lab | `us-east-1` |
| Perfil de CLI | `inv-lab` |
| Tag de rastreo obligatorio | `Project=inv-lab` |
| Stack de datos (`L02`) | `inv-lab-data` |
| Stack de aplicación (`L03`) | `inv-lab-app` |
| Tabla de eventos | `inv-lab-events` |
| Funciones | `inv-lab-api`, `inv-lab-projector`, `inv-lab-alert` |
| Cuenta de ejemplo en salidas | `111122223333` |

**Nunca uses `latest`, `*` ni rangos donde el curso fija un valor exacto**, ni en
runtimes de Lambda ni en versiones de la CLI. Un `python3.x` en un ejemplo destruye la
reproducibilidad que el curso intenta enseñar.

---

## 6. 🧱 Plantilla de los documentos temáticos (`01`–`12`)

1. **Título** — `# NN — Tema` (dos dígitos, sin emoji en el título).
2. **Blockquote de encabezado** — objetivo del documento en una o dos líneas, qué se
   asume leído, y **`Vigencia:`** con la fecha en que se verificaron los enlaces y el
   comportamiento de los servicios descritos. Ese campo es obligatorio: quien abre
   `04` sin pasar por el README tiene que saber qué tan reciente es lo que lee.
3. **Índice de salto rápido** — si el documento pasa de ~400 líneas (§6.2).
4. **Secciones `##` numeradas**, una por concepto o servicio, con emoji funcional.
   Cuando el documento cubre bloques claramente separables (`03` separa storage de
   SQL, `05` separa IAM de encryption) se usan divisores `# Parte I — …` en romanos,
   **manteniendo la numeración arábiga de `##` continua** a través de las partes.
5. **⚠️ Errores frecuentes** — sección opcional pero recomendada: la confusión típica
   de entrevista sobre ese tema, con la versión precisa al lado.
6. **🧠 Preguntas rápidas** — cierre obligatorio, sin respuestas visibles (§8.1).
   **Un capítulo teórico no lleva ejercicios**: si el contenido pide ejecutar algo, va a
   un lab o a un apéndice.
7. **📚 Referencias oficiales** — cierre obligatorio (§9).

**Excepciones declaradas a la plantilla:**

- `README.md` — índice, mapa mental y tabla de asociaciones.
- `10-preguntas-entrevista-y-mapa-mental.md` — simulación de entrevista completa:
  preguntas `P#` sin respuesta inline (van al solucionario) y escenarios de
  arquitectura que **sí** conservan su solución desarrollada, porque son ejemplos
  resueltos y no autochequeo de memoria.
- `13-respuestas.md` — solucionario centralizado. No lleva "Preguntas rápidas" ni
  referencias propias.
- `l00-idea-lab-practico.md` — encuadre e introducción de la serie práctica (§7.1).

### 6.2 Índice de salto rápido

Formato fijo, justo después del blockquote de encabezado:

```markdown
**Salto rápido:** [Region](#2--region) · [Availability Zone — AZ](#3--availability-zone--az) ·
[VPC — Virtual Private Cloud](#4--vpc--virtual-private-cloud) · [Subnet](#6--subnet) ·
[Preguntas rápidas](#-preguntas-rápidas)
```

**Cómo se calcula un ancla de GitHub**, porque es donde se rompen estos índices: se
pasa el encabezado a minúsculas, se eliminan los caracteres que no son letra, número,
espacio, guion o guion bajo —lo que se lleva por delante el punto de la numeración, el
emoji, los backticks y los dos puntos— y por último los espacios restantes se convierten
en guiones. Cada carácter borrado **deja su espacio**, y de ahí salen los guiones dobles:

| Encabezado | Ancla |
|---|---|
| `## 2. 🧱 Region` | `#2--region` |
| `## 3. 🧱 Availability Zone — AZ` | `#3--availability-zone--az` |
| `## 8. 🧱 \`Ref\`` | `#8--ref` |
| `## 🧠 Preguntas rápidas` | `#-preguntas-rápidas` |

Fíjate en el último: un encabezado que empieza por emoji genera un ancla que **empieza
por guion**. Verifica los anclas al escribirlos; un índice con enlaces rotos es peor que
no tener índice.

---

## 7. 🧪 La serie práctica: labs (`lNN-`) y apéndices (`aNN-`)

Los labs y los apéndices siguen la plantilla de §6 con los añadidos de abajo, y sin
ninguna excepción de tono ni de pedagogía: aquí la regla de §4.2 —ningún comando ni
flag sin explicar— se aplica con más rigor que en ninguna otra parte, porque son los
documentos que el lector ejecuta contra una cuenta que le cobra.

### 7.1 La doctrina de reparto es materia editorial, no solo de alcance

**Regla de arquitectura del curso, y se enuncia en cada lab que la toque:**

> En la nube se practica lo que **solo** existe en la nube. Todo lo demás se practica
> en local con contenedores, gratis y con un ciclo de iteración de segundos.

Un tema entra en el laboratorio de pago solo si cumple al menos una condición: lo
hace cumplir AWS y nadie más (IAM, routing de VPC), el fallo real difiere del emulado
(`ROLLBACK_COMPLETE`, `DELETE_FAILED`, throttling), solo se conoce pagando (Cost
Explorer, budgets) o es la costura entre tu código y AWS (execution role,
resource-based policy).

Y la contrapartida se escribe con la misma claridad: **cuando el curso excluye algo
—EKS, ECS, RDS, Kafka, un microservicio de negocio— dice por qué, cuánto costaría y
dónde se practica en su lugar.** Una exclusión sin justificación se lee como un hueco
del temario; una exclusión justificada es contenido. El desarrollo completo de esta
doctrina vive en `l00-idea-lab-practico.md` y el resto de documentos remite ahí en
vez de reabrir la discusión.

### 7.2 Labs `lNN-tema.md`

Título `# LNN — Tema`. Son acumulativos y se hacen en orden. Además de lo de §6:

- **Cabecera con contrato económico y temporal:** costo esperado con su unidad,
  duración estimada, prerrequisitos (qué lab anterior debe estar hecho) y qué queda
  encendido al terminar.
- **Teardown escrito antes que el despliegue.** Ningún lab introduce un recurso sin
  que el documento diga, en ese mismo punto, cómo se destruye y cómo se verifica que
  murió. Si el recurso sobrevive a un `delete-stack`, se dice ahí, no en L04.
- **Reproducir el error antes de arreglarlo.** Cuando el lab enseña un fallo
  —`DELETE_FAILED` por un bucket no vacío, un `AccessDenied` por trust policy— se
  provoca a propósito, se muestra la salida literal y solo después la corrección.
- **📋 Checklist de salida** en formato `- [ ]` antes del cierre, con comprobaciones
  ejecutables. No son ejercicios: son criterios de terminado verificables, y conviven con
  la sección de ejercicios de §8.2 sin sustituirla.
- **🧪 Ejercicios** graduados (§8.2), después de las preguntas rápidas.
- **🏁 La señal de que quedó bien** — una frase de cierre que describe el estado
  correcto: *"`aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=inv-lab`
  devuelve una lista vacía y Cost Explorer confirma $0.00 a las 48 horas"*.

### 7.3 Apéndices `aNN-tema.md`

Título `# ANN — Tema`. Material de consulta, sin orden ni prerrequisitos. No llevan
costo, duración ni checklist de salida. Abren siempre con índice de salto rápido
(son de consulta: nadie los lee linealmente) y organizan el contenido en secciones
cortas e independientes, cada una autosuficiente. Sí llevan "Preguntas rápidas", "🧪 Ejercicios" (§8.2) y
"Referencias oficiales".

---

## 8. 🧠 Preguntas en los capítulos, 🧪 ejercicios en labs y apéndices

Este curso reparte el aparato de evaluación en dos mitades que no se mezclan, y conviene
tener la regla delante antes de escribir cualquier cierre de documento:

```text
capítulos teóricos (01–13)  →  SOLO preguntas rápidas. Nunca ejercicios.
                               Respuestas SIEMPRE en 13-respuestas.md.

labs (L01–L04) y apéndices  →  preguntas rápidas + 🧪 ejercicios graduados,
(A01–A02)                      con 🔥 opcionales y 💀 boss fight cuando lo pida
                               el contenido. Los ejercicios NO van al solucionario.
```

**Por qué esta división y no la del repositorio.** `CLAUDE.md` fija como norma por defecto
de 20 a 30 ejercicios graduados por sección, y admite expresamente que la guía de cada
curso **reemplace o reparta ese aparato de otra forma, siempre que lo diga y diga por
qué**. Esto es esa divergencia declarada, y la razón es que aquí conviven dos tipos de
documento con objetivos distintos: los capítulos teóricos son repaso para una entrevista
—se contestan en voz alta, sin computadora y sin cuenta de AWS—, mientras que los labs y
los apéndices son lo único ejecutable del curso, y ahí un ejercicio sí tiene dónde
correrse. Poner ejercicios en un capítulo teórico obligaría al lector a encender
infraestructura para estudiar teoría, que es exactamente lo que la doctrina de reparto de
[`L00`](../l00-idea-lab-practico.md) prohíbe.

### 8.1 Preguntas rápidas — cierre obligatorio de todo documento

Son preguntas para contestar de memoria o razonando, no trabajos para resolver con
código. Cierran **todos** los documentos: los teóricos, los labs y los apéndices.

- **Cantidad: 10 a 15 por documento temático o lab, y de 6 a 12 en un apéndice**,
  calibrada por cuántas cosas distintas enseña el documento y se pueden comprobar por
  separado — nunca por su longitud. La banda admite desbordarse **cuando el documento
  cubre varias Partes o es un catálogo**, y hoy hay dos casos declarados: `05` llega a 17
  porque abarca IAM, Cognito, KMS, secretos y Organizations, y `A02` llega a 12 porque
  cada trampa de costo es comprobable por su cuenta. Fuera de esos dos, subir de 15 exige
  poder decir qué comprueba cada pregunta nueva que no comprobara ya otra.
- **Directas y verificables.** Cada pregunta tiene respuesta corta y objetiva
  localizable en el propio documento. Nunca "reflexiona sobre…".
- **Reparto sugerido**, para que la sección entrene algo más que memoria:
  aproximadamente la mitad de definición o distinción ("¿SG tiene reglas DENY?"), un
  tercio de decisión o comparación ("¿cuándo usarías un VPC Endpoint en lugar de un
  NAT Gateway?") y el resto de diagnóstico ("¿cómo depurarías una conexión EC2 → RDS
  que falla?"). **Dos documentos vecinos no deberían tener el mismo reparto.**
- **Sin respuesta en el documento, con solucionario centralizado.** Todas las
  respuestas, explicadas, viven en `13-respuestas.md`, agrupadas por documento y
  numeradas igual que la pregunta original (la pregunta 3 de `04` se responde en la
  entrada "04 → 3"), **y con el enunciado copiado literalmente**, no parafraseado: es lo
  que permite localizar una respuesta buscando el texto de la pregunta. Quien agregue,
  elimine o reordene una pregunta **debe reflejar el mismo cambio en `13-respuestas.md`
  en la misma edición**.
- **Orden libre**, por relevancia de entrevista, no correlativo a las secciones.

### 8.2 Ejercicios — solo en labs y apéndices

Van **después** de las preguntas rápidas y antes del cierre del documento. Heredan la
mecánica del curso `docker-container-legacy`, del que esta guía desciende, con la banda
recalibrada y una restricción propia que allí no existía: **aquí cada ejercicio corre
contra una cuenta que factura**.

- **Cantidad: 10 a 16 por lab y 8 a 12 por apéndice**, contando solo los obligatorios.
  Es una banda deliberadamente más baja que los 20–35 del curso de Docker, y el motivo es
  el costo del ciclo: allí un ejercicio se reintenta en cuarenta segundos con `docker
  build`, aquí un despliegue tarda minutos y se paga. La cifra concreta la decide el
  contenido, no la longitud: la pregunta es *"¿cuántas cosas distintas enseña este
  documento que se puedan comprobar por separado?"*.
- **La escala, completa.** Los cuatro primeros escalones son obligatorios y cuentan para
  la banda; los dos últimos no.

  | | Nivel | Qué pide |
  |---|---|---|
  | 🟢 | Fácil | Reproducir con otro valor lo que el lab acaba de mostrar |
  | 🟡 | Intermedio | Aplicar el mecanismo a un recurso o servicio distinto |
  | 🟠 | Difícil | Combinar dos mecanismos, diagnosticar o decidir entre alternativas |
  | 🔴 | Muy difícil | Abierto o adversarial: se entrega algo roto y hay que razonarlo |
  | 🔥 | Extra | Ampliaciones fuera del alcance base, y las que sí cuestan dinero |
  | 💀 | Boss fight | Encadena todo el lab —o toda la serie— en un solo encargo |

- **Reparto orientativo:** alrededor de 30 % 🟢, 30 % 🟡, 25 % 🟠 y 15 % 🔴, con un escalón
  de margen. Un lab que se pasa la mitad del tiempo rompiendo cosas a propósito carga
  hacia 🟠 y 🔴; un apéndice de referencia carga hacia 🟢 y 🟡. **Que dos documentos
  vecinos tengan idéntico reparto es señal de que el segundo se copió en vez de
  calibrarse.**
- **El 💀 se decide, no se reparte.** Sale de preguntarse *"¿hay aquí un trabajo que solo
  se resuelva encadenando todo lo anterior?"*. Si lo hay, empieza con un sistema roto o
  un encargo completo, cruza al menos tres secciones y se entrega como artefacto —un
  script, un informe, un template que despliega—. Si al escribirlo te cabe en tres
  líneas, era un 🔴 con mejor nombre y no un boss.
- **Regla propia de este curso: todo ejercicio declara su costo y su teardown.** Cada
  enunciado dice `$0.00` o el precio con su unidad, y el que crea algo dice cómo se
  destruye y cómo se comprueba que murió. Un ejercicio que enciende un recurso que cobra
  por hora va marcado como 🔥 y nunca cuenta para los obligatorios: el tronco de la serie
  se completa entero sin gastar más de lo que declara `L00`.
- **Cada ejercicio cierra con su criterio.** Una línea **`Objetivo:`** con lo que hay que
  haber entendido, o una **`Pregunta:`** que solo se pueda contestar habiéndolo hecho.
  Nunca "despliega un stack" a secas.
- **Los ejercicios no van al solucionario.** `13-respuestas.md` es exclusivamente para las
  preguntas rápidas y las `P#` de `10`. Un ejercicio se verifica con su `Objetivo:` y con
  la salida real del comando, no comparando contra una respuesta escrita — y si necesita
  una respuesta modelo para tener sentido, es que estaba mal planteado y era una pregunta.
- **Enganchados al laboratorio.** Se usan los nombres vigentes del baseline de §5.1
  (`inv-lab-data`, `inv-lab-events`, el perfil `inv-lab`), nunca `foo` ni "tu stack".
- **Predecir antes de ejecutar.** En los 🟠 y 🔴 conviene pedir explícitamente que
  anticipes la salida y después compares. Es donde aparecen los modelos mentales rotos, y
  es el músculo que esta serie entrena.
- **Exenciones declaradas.** Quedan fuera del aparato de ejercicios, y solo estas tres:
  `l00-idea-lab-practico.md`, que es el encuadre de la serie y no ejecuta nada —lleva
  preguntas, no ejercicios—; `13-respuestas.md`, que es el solucionario y no lleva ni
  preguntas ni ejercicios; y el **boss fight de `A01`**, que no existe a propósito: es un
  apéndice de referencia sobre una herramienta, y no hay en él ningún trabajo que solo se
  resuelva encadenando todo lo anterior. Inventarle uno produciría el 🔴 con mejor nombre
  que esta sección prohíbe.
- **Formato**, con el conteo de obligatorios en el título:

  ```markdown
  ## 🧪 Ejercicios (12)

  ### 🟢 Fácil — …  (1–4)
  #### 🟢 Ejercicio 1 — …
  … enunciado …
  **Objetivo:** …

  ### 🟡 Intermedio — …  (5–8)
  ### 🟠 Difícil — …  (9–11)
  ### 🔴 Muy difícil — …  (12)
  ### 🔥 Opcionales y ampliaciones
  ### 💀 Boss fight — …
  ```

---

## 9. 🧷 Vocabulario visual: reglas y callouts

Vocabulario deliberadamente más reducido que el de los cursos narrativos del
repositorio, pero ya no limitado a tres recursos.

### 9.1 Regla o mnemotecnia (bloque `text`)

Para una asociación mental que vale la pena aislar, en especial con forma de
comparación o ecuación corta. Se etiqueta antes con una línea breve: "Regla:",
"Regla mental:", "Regla de entrevista:" o "Regla de arquitectura:".

```text
Peering → conexión directa uno-a-uno
TGW     → hub-and-spoke a escala
```

### 9.2 Frase de respuesta correcta (blockquote `>`)

Para la única frase que un entrevistado debería decir en voz alta, normalmente
después de mostrar la simplificación incorrecta. Sirve igual para blindar contra la
mala respuesta ("Nunca respondas: > …") que para dar la buena ("Mejor: > …"). También
admite etiqueta corta de énfasis —"Regla importante:", "Punto importante:"— cuando lo
que sigue es una única frase definitoria o correctiva.

Prueba práctica: si cabe en una oración y corrige o fija un concepto, va en
blockquote; si es lista, ecuación o comparación de dos o más líneas, va en bloque
`text`.

### 9.3 Callouts admitidos

Se usan en blockquote, con negrita en la etiqueta, y solo cuando aportan. Ninguno es
obligatorio en ningún documento.

- ⚠️ **Advertencia.** Ignorarlo rompe algo en producción, cuesta dinero o produce una
  respuesta de entrevista objetivamente incorrecta. Uso escaso; nunca decorativo.
- 🧠 **Modelo mental.** La frase que hay que llevarse, no el detalle.
- 💡 **Truco o atajo** que ahorra tiempo real (un `--query` de JMESPath que evita
  cinco comandos, un waiter en vez de un bucle).
- 🩺 **Diagnóstico.** El comando que confirma o descarta una hipótesis.
- 💰 **Costo.** Lo que cobra ese recurso, con unidad y con qué lo dispara. Obligatorio
  la primera vez que un documento introduce algo que cobra por hora.
- 📝 **Contexto.** Por qué AWS hace algo raro, o qué cambió recientemente y por qué la
  respuesta "clásica" que el lector pueda encontrar en fuentes viejas ya no aplica.
- 📚 **Referencia inline.** El enlace útil justo donde nace la duda, sin esperar al
  cierre.

**Escala de dificultad 🟢🟡🟠🔴🔥💀.** Se usa **solo** en la sección de ejercicios de labs y
apéndices (§8.2), donde clasifica cada ejercicio y su encabezado de rango. Fuera de esa
sección no aparece: un capítulo teórico no gradúa nada porque no tiene ejercicios que
graduar.

**Marcadores ✅ y ❌.** Se admiten como señal de sí/no dentro de tablas y de bloques
` ```text ` de comparación —el "ALLOW ✅ / DENY ❌" con el que `01` contrasta Security
Group y NACL es el uso canónico—. Nunca como decoración en prosa ni en un encabezado.

Fuera de esta lista, de ✅/❌, de la escala de dificultad de los ejercicios y de los
emojis de encabezado de §3, **no se usan otros emojis**. Nada de 🪦, 💸, ⭐ ni 🚨: esos sí
pertenecen a los cursos narrativos del repositorio.

### 9.4 Autopsia de un fallo

Cuando un lab documenta un fallo real —y varios lo hacen— la estructura es:

1. Síntoma, con la salida literal del comando.
2. Qué lo provocó, hasta la línea del template o la sentencia de la policy.
3. La hipótesis y el comando que la confirma o la descarta.
4. La corrección, distinguiendo el parche que desbloquea hoy de la solución que uno
   haría con calma.
5. La prevención: la comprobación, el tag o el checklist que evita la repetición.

Dos reglas de método que atraviesan la serie práctica: **una variable a la vez** y
**reproducir antes de reparar**. Y los anti-patrones se nombran sin piedad:
`"Effect": "Allow", "Action": "*"` "para salir del paso", `--force` como primer
reflejo, borrar el stack desde la consola cuando la CLI falla.

---

## 10. 📚 Bibliografía, referencias y enlaces

### 10.1 Enlaces externos

- **Solo documentación oficial de AWS** en la sección de referencias: `docs.aws.amazon.com`,
  `aws.amazon.com/<servicio>/pricing/`, la calculadora, los anuncios de
  `aws.amazon.com/about-aws/whats-new/` y la **Amazon Builders' Library**
  (`aws.amazon.com/builders-library/`), que es material técnico de AWS y no un blog de
  terceros. El curso no cita libros, blogs de terceros ni videos.
- **Herramientas de terceros que el laboratorio local usa** (LocalStack, MinIO,
  Redpanda, Keycloak) van en una **subsección aparte marcada como opcional**, nunca
  mezcladas con la documentación oficial.
- **URLs completas y clicables**, nunca solo el dominio, y **una URL por concepto
  cubierto**, no un enlace genérico al User Guide entero cuando existe la página
  específica. Si el documento explica `DeletionPolicy`, el enlace es a la página de
  `DeletionPolicy`, no a la portada de CloudFormation.
- **No se inventan URLs.** Un enlace que no se pudo verificar no se escribe: se cita
  el nombre exacto de la página y se deja el enlace al índice del servicio. Inventar
  una ruta plausible de `docs.aws.amazon.com` es el error más caro de este curso,
  porque parece correcta hasta que alguien la abre en una entrevista.

### 10.2 Enlaces internos entre documentos

Son parte del producto, no un adorno, y hacen cumplir §4.7.

- **Formato:** enlace Markdown relativo al archivo, con el número del documento en el
  texto visible:

  ```markdown
  ver [`05` — policy evaluation](05-seguridad-iam-kms-secretos.md)
  ```

- **Con ancla cuando la sección destino existe y es estable:**

  ```markdown
  [`09` §22 — Change Sets](09-cloudformation-iac.md#22--change-sets)
  ```
- **Cada documento temático enlaza al menos a los dos documentos con los que más se
  toca**, y todo lab enlaza al documento teórico que sustenta lo que practica y al
  apéndice que lo complementa.
- **Al renombrar un archivo o un encabezado se revisan los enlaces entrantes en la
  misma edición.** Un enlace roto dentro del propio curso es peor que un enlace
  externo caído: el externo tiene disculpa, el interno no.
- **Los enlaces externos se comprueban con el código de estado, no a ojo.** La
  documentación de AWS mueve páginas sin avisar y responde a una URL muerta con un `302`
  hacia el índice de la guía, no con un `404`: un enlace que aterriza en la portada del
  User Guide en vez de en la página concreta cuenta como roto y hay que buscar su
  reemplazo.

### 10.3 Vigencia

El README declara la fecha de revisión general y **cada documento la repite en su
blockquote de encabezado**. Cuando un documento incorpora un cambio reciente de AWS
—Regional NAT Gateway, Multi-AZ DB cluster con readers, el fin del free tier de doce
meses en julio de 2025— se marca con 📝 en el propio texto, para que quien repasa sepa
que puede no coincidir con las respuestas "clásicas" de fuentes más viejas.

---

## 11. 🔗 Coherencia entre documentos

- **No contradecir documentos anteriores.** Si `03` establece que una read replica es
  para read scaling y Multi-AZ para HA, `10` puede matizarlo, nunca contradecirlo.
- **Terminología estable.** Si `01` dice "Internet Gateway (IGW)", el resto del curso
  no lo llama "gateway de Internet" ni abrevia distinto.
- **Los labs son acumulativos y lo declaran.** Cada lab dice en su cabecera qué deja
  encendido y el siguiente asume exactamente ese estado. Si un lab rompe la cadena, lo
  dice explícitamente.
- **Los nombres del baseline de §5.1 mandan.** Cualquier desviación se declara con ⚠️
  en el documento que la introduce.
- **Fuentes de verdad, en orden:** (1) **esta guía y los demás documentos de `prompts/`**,
  que según la regla de precedencia de `CLAUDE.md` mandan sobre las normas por defecto del
  repositorio en todo lo que declaren explícitamente; (2) `CLAUDE.md` de la raíz, para todo
  lo que esta guía no toca; (3) `l00-idea-lab-practico.md` para el alcance y la doctrina de
  reparto de la serie práctica; (4) `README.md` para orden de lectura y mapa; (5) documentos
  ya publicados; (6) decisiones explícitas del chat actual.

---

## 12. ✅ Checklist antes de dar por cerrado un `.md`

- [ ] Sigue la plantilla de §6 (o está declarado como excepción: README, `10`, `13`, `l00`).
- [ ] Encabezado con objetivo y **`Vigencia:`**; índice de salto rápido si pasa de ~400 líneas.
- [ ] Tono semi formal y cálido, tuteo latinoamericano, humor casi ausente (§2).
- [ ] Emoji funcional en `##`, ninguno en `###`, y solo los callouts de §9.3.
- [ ] **Ningún comando ni flag queda sin explicar** (§4.2). Ningún bloque de código sin desglose.
- [ ] El problema se plantea antes que el servicio (§4.1) y cada decisión lleva su porqué (§4.3).
- [ ] Sin prosa telegrama: una o dos frases aisladas por sección como mucho (§3).
- [ ] Tablas solo para comparar o mapear, máximo cuatro columnas, sin celdas que necesiten explicación.
- [ ] Nombres del baseline de §5.1 respetados; sin `latest`, sin `*`, sin rangos.
- [ ] Se nombra explícitamente cuando una respuesta común de entrevista es una sobregeneralización.
- [ ] Todo lo que cobra por hora aparece con precio y unidad (💰), y toda exclusión del lab dice por qué y dónde se practica en su lugar (§7.1).
- [ ] En labs: teardown escrito junto al recurso, errores reproducidos antes de corregirlos, checklist de salida ejecutable y cierre con **🏁 La señal de que quedó bien**.
- [ ] Cierra con **Preguntas rápidas** (10–15; apéndices 6–12), sin respuestas, con reparto distinto al del documento vecino (§8.1).
- [ ] Si es lab o apéndice: **🧪 Ejercicios** graduados (10–16 en un lab, 8–12 en un apéndice), cada uno con su `Objetivo:`, su costo y su teardown; 🔥 y 💀 fuera del conteo (§8.2).
- [ ] Si es capítulo teórico: **no lleva ejercicios**, solo preguntas.
- [ ] Si tocaste alguna pregunta, actualizaste `13-respuestas.md` en la misma edición.
- [ ] Cierra con **Referencias oficiales**: URLs completas, verificadas, una por concepto, solo documentación oficial; terceros en subsección opcional aparte.
- [ ] Enlaces internos a los documentos con los que más se toca, y ningún enlace interno roto (§10.2).
- [ ] No contradice ningún documento anterior (§11).
