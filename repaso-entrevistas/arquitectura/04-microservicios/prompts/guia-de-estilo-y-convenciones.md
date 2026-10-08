# ✍️ Guía de estilo, tono y convenciones

## Microservicios — repaso para entrevistas de Backend Senior, Tech Lead y Arquitecto

Esta guía es la fuente de verdad editorial de `04-microservicios/` y manda sobre **los cinco
bloques teóricos** (`01-fundamentos-y-descomposicion`, `02-comunicacion`, `03-datos-y-consistencia`,
`04-operacion-y-resiliencia`, `05-plataformas`) y sobre el bloque **opcional** de talleres,
`06-talleres/` (§13 y §14). Cualquier chat que produzca o edite un `.md` de este corpus la sigue. Su objetivo es que todos los documentos se lean como escritos por la misma
mano y apunten al mismo lugar: **que puedas nombrar el patrón, escribirlo en la plataforma que te
toque, y decir en voz alta qué te cuesta**.

Desciende de la guía de
[`arquitectura/01-bases`](../../01-bases/prompts/guia-de-estilo-y-convenciones.md),
de la que hereda el tono, la pedagogía del andamio, el vocabulario visual, la plantilla de capítulo,
las tres capas de respuesta y las reglas de enlace. Toma de
[`bases/01-bases`](../../../bases/01-bases/prompts/guia-de-estilo-y-convenciones.md)
la idea del **eje políglota** y la reformula. **Diverge en seis puntos declarados** —§4.2, §4.4, §5,
§5.5, §6 y §10.1— por una razón de fondo: aquel corpus enseña a **razonar** un sistema distribuido, y
este enseña a **implementarlo**, en cuatro plataformas que resuelven el mismo patrón con esfuerzos muy
distintos. La de §5.5 (código de dominio en inglés) es de 2026-09-29 y la trajo el bloque de
talleres: un corpus que ejecuta código no puede tener dos convenciones de nombres.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que mañana tiene una
entrevista donde le van a preguntar cómo implementó una saga, y pasado mañana tiene que revisar el
pull request donde alguien la implementó mal.

> **Vigencia:** 2026-09-29.

**Salto rápido:** [1](#1--principio-rector) · [2](#2--tono) · [3](#3-️-idioma-y-forma-de-la-narrativa) · [4](#4--pedagogía-como-para-un-bebé) · [5](#5--el-eje-de-las-cuatro-plataformas) · [6](#6--plantilla-de-los-capítulos-nn-temamd) · [7](#7--los-tipos-de-documento) · [8](#8--preguntas-y-respuestas) · [9](#9--vocabulario-visual-reglas-y-callouts) · [10](#10--bibliografía-referencias-y-enlaces) · [11](#11--coherencia-entre-documentos) · [12](#12--checklist-antes-de-dar-por-cerrado-un-md) · [13](#13--bloque-06--talleres) · [14](#14--nombres-fijos-del-laboratorio)

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien reconozca el patrón, sepa con qué se implementa en su
plataforma, compare las alternativas y diga el precio en voz alta.**

No enseñamos "microservicios" como catálogo. El catálogo de Richardson tiene más de setenta patrones
y recitarlos es la señal más clara de que alguien estudió para el examen. Repasamos **los patrones
que de verdad se escriben**, y para cada uno, lo que cambia entre escribirlo en Spring Boot,
en NestJS, en Go o en FastAPI.

```text
Un curso de microservicios  → te enseña el catálogo de patrones.
El corpus de arquitectura   → te enseña a decidir si los quieres.
Este repaso                 → te enseña a escribirlos, con qué librería,
                              y qué te cuesta en cada plataforma.
```

El filtro para cada párrafo es este: **¿esto ayuda a reconocer el patrón, a implementarlo, a
compararlo o a defender la decisión?** Si no, sobra. Aunque esté muy bien escrito.

Y el corolario, repetido tantas veces como haga falta:

> Cada patrón se muestra implementado, no solo descrito. Cada implementación se nombra con su
> librería concreta. Cada decisión responde a "¿por qué esto y no lo otro, y qué pierdo al
> elegirlo?".

Un patrón descrito sin su implementación no está explicado: está catalogado. Un patrón implementado
en un solo lenguaje está explicado a medias, porque la mitad de su dificultad real es **cuánto
trabajo te deja a ti** la plataforma que usas.

### 1.1 Qué NO es este corpus

Cinco cosas quedan fuera por decisión editorial, y se declaran aquí para que ningún documento las
prometa. De los corpus que las cubren, **solo `arquitectura/01-bases` es prerrequisito**; los demás
son sugerencias de estudio: se enlazan como ampliación, ningún documento exige haberlos leído y lo
mínimo que haga falta de ellos se resume donde se usa.

- **No es el corpus de arquitectura.** La decisión *monolito contra microservicios*, los estilos de
  despliegue, DDD estratégico y táctico, CAP, event sourcing y la teoría de EDA son de
  [`arquitectura/01-bases`](../../01-bases/). Aquí se **asume esa
  decisión tomada** y se entra a implementarla. Cuando un capítulo necesita el razonamiento, lo
  enlaza; no lo reescribe.
- **No es el corpus de monolito ni el de hexagonal.** El monolito modular, sus límites internos y el
  diagnóstico del monolito distribuido desde dentro son de
  [`arquitectura/02-monolito`](../../02-monolito/); la estructura interna de un servicio con puertos y
  adaptadores, de [`arquitectura/03-hexagonal`](../../03-hexagonal/). Aquí se usan y se enlazan: el
  monolito distribuido entra como antipatrón que hay que reconocer en entrevista (`01/04`), y la
  estructura hexagonal, como la forma por defecto del servicio por dentro (`01/05`).
- **No es el corpus de APIs y protocolos.** La semántica de HTTP, los códigos de estado, TLS, la
  idempotencia según el RFC y qué obliga la norma son de
  [`bases/04-apis-protocolos`](../../../bases/04-apis-protocolos/). Aquí se
  explica **cómo se usan entre servicios**, y por qué una API interna no se diseña como una pública.
- **No es un curso de Spring.** `@RestController`, el contenedor, los proxies, Spring Cloud por
  dentro y Spring Batch son de
  [`frameworks/01-spring-boot`](../../../frameworks/01-spring-boot/). Aquí Spring aparece **como una de
  las cuatro plataformas**, al mismo nivel que NestJS o Go.
- **No es un curso de Kubernetes ni de nube.** El manifiesto, la VPC, el balanceador gestionado y el
  IAM concreto son de [`cloud/01-aws`](../../../cloud/01-aws/),
  [`cloud/02-gcp`](../../../cloud/02-gcp/) y [`cloud/03-azure`](../../../cloud/03-azure/). Aquí entra Kubernetes solo hasta donde
  implementa un patrón —`Service` como descubrimiento, `readinessProbe` como health check— y se dice
  dónde se practica en serio.

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, de colega a colega. Piensa en alguien que ya pasó por
esto —la saga que dejó dos pedidos a medias un viernes, el reintento que duplicó cuarenta cobros, el
servicio "independiente" que no se podía desplegar sin desplegar otros tres— y te lo explica con
paciencia y sin solemnidad de manual corporativo.

Cómo se ve en la práctica:

- **Tuteo latinoamericano, siempre.** Le hablas al lector de "tú": *"cuando te pregunten esto, lo
  que buscan es aquello"*. Nada de voseo, nada de "usted", nada de impersonal permanente.
- **Semi formal.** Cercano, pero no chat. Frases completas, puntuación correcta, cero abreviaturas
  de mensajería.
- **Humor mínimo y seco.** Como mucho **un desdramatizador por documento**, y si no fluye solo, se
  borra. Este corpus se lee antes de una entrevista.
- **Honesto sobre la ceremonia.** Cuando un patrón sobra, se dice que sobra. *"Un service mesh para
  seis servicios es un segundo sistema que mantener"* es contenido; *"el mesh da observabilidad y
  mTLS"* es un folleto.
- **Honesto sobre las simplificaciones.** Cuando la respuesta común de entrevista es una
  sobregeneralización —"cada microservicio tiene su base de datos", "con Kafka tienes exactly-once",
  "el circuit breaker evita la caída en cascada", "gRPC es más rápido"— **se nombra la simplificación
  y se da la versión precisa**. La sección `## ⚠️ Errores frecuentes` existe para esto.
- **Honesto sobre el precio.** Todo patrón se nombra con lo que cuesta, en las **cinco monedas** de
  §4.2. Nada de "añade algo de complejidad": se dice qué complejidad, dónde y quién la paga.
- **Honesto sobre los números.** Este temario está lleno de cifras que circulan sin origen —"gRPC es
  siete veces más rápido", "el sidecar añade un milisegundo", "Java arranca en treinta segundos"—.
  Una cifra se escribe **solo si se dice de dónde sale y qué no mide**; si no se puede, se da el
  orden de magnitud y se dice de qué depende. **Nunca se cita como propio un benchmark que no
  corrimos**, y nunca se compara rendimiento sin nombrar el perfil de carga: casi todo lo que este
  corpus describe pasa el 95 % del tiempo esperando red o base de datos, y ahí el lenguaje casi no
  aparece en la cuenta.
- **Honesto sobre las modas.** Este temario arrastra más folclore que ningún otro del repositorio.
  Cuando algo se hizo por moda y se deshizo después —nano-servicios, el ESB rebautizado, el mesh en
  equipos de tres personas, "serverless para todo"— se cuenta con su fecha y su corrección.
- **Sin absolutos falsos.** Nada de "siempre" ni "nunca" salvo cuando es literalmente cierto
  (*exactly-once no existe de extremo a extremo*; *dos servicios que comparten tabla no son dos
  servicios*).
- **Neutral entre plataformas, e igual de exigente con las cuatro.** Nada de guerras de lenguajes:
  se comparan mecanismos, no gustos. Java recibe más espacio porque es el perfil base
  (§5.1), no porque sea mejor, y **eso se dice**. Y a Java se le señalan sus costes —arranque,
  memoria, verbosidad del cableado— con la misma franqueza que al GIL de Python.
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca infantilizamos. "Como para un
  bebé" significa **cero ambigüedad**, no menos profundidad — ver §4.
- **Sin relleno motivacional.** Quien lee ya sabe por qué está repasando.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no sea código.
- **Los nombres de patrón y término del oficio se quedan en inglés** cuando son el nombre real de la
  cosa: *saga*, *outbox*, *service discovery*, *circuit breaker*, *bulkhead*, *sidecar*, *strangler
  fig*, *backpressure*, *service mesh*, *canary*, *blue-green*, *feature flag*, *dead letter queue*.
  Traducirlos a la fuerza confunde y no es lo que el lector va a oír en la entrevista. Los que ya
  tienen traducción asentada —cola, evento, contrato, despliegue, reintento— se usan en español con
  naturalidad. **La primera vez que aparece un término en inglés, se da su traducción entre
  paréntesis**; después ya no.
- **Los nombres de librería, framework y herramienta se escriben como se escriben ellos**:
  `Resilience4j`, `NestJS`, `Fastify`, `chi`, `FastAPI`, `Debezium`, `Temporal`, `OpenTelemetry`,
  `Pact`, `Testcontainers`. Con su capitalización real, no "resilience 4J" ni "nest".
- **Markdown siempre.** Nada de HTML embebido.
- **Estructura visual primero, pero la prosa no es el último recurso.** El orden de preferencia es
  diagrama ASCII → tabla comparativa → lista → párrafo *para exponer una relación entre cosas*. El
  **porqué** de una decisión se escribe en prosa: una tabla no puede explicar por qué el reintento
  ciego convierte una degradación en una caída.
- **Nada de prosa telegrama.** Una frase corta y sola, con líneas en blanco a ambos lados, es un
  buen golpe de ritmo. Tres seguidas son un telegrama. Regla práctica: **una frase aislada por
  sección, dos si la sección es larga**.
- **Diagramas ASCII en bloques ` ```text `.** Son el recurso visual principal para topologías,
  secuencias de saga, cadenas de fallo y árboles de decisión. Simples: cajas, flechas, texto. Sin
  arte ASCII elaborado. Para una secuencia entre servicios, el formato fijo es:

  ```text
  Pedidos          Inventario        Pagos
     │ reservar()      │                │
     ├────────────────►│                │
     │                 │ 200 OK         │
     │◄────────────────┤                │
     │ cobrar()                         │
     ├─────────────────────────────────►│
     │                        402 rechazado
     │◄─────────────────────────────────┤
     │ compensar: liberar()             │
     ├────────────────►│                │
  ```

- **Tablas solo para comparar o mapear**, con tres o cuatro columnas como norma. La tabla de las
  cuatro plataformas tiene su formato fijo en §5.2. **Si necesitas explicar una celda, ya no es una
  tabla.** Nunca se narra en tabla.
- **Encabezados con emoji, con moderación.** Uno por sección `##` numerada, **ninguno en las
  subsecciones `###`**, sin excepciones. El emoji es funcional y señala de qué tipo es la sección:

  | Emoji | Tipo de sección |
  |---|---|
  | 🎯 | El problema (apertura obligatoria) |
  | 🧱 | El patrón o mecanismo |
  | 🧰 | Cómo se implementa en las cuatro plataformas |
  | ⚖️ | Comparación entre alternativas |
  | 💰 | El precio, cuando merece sección propia |
  | 🧭 | Cómo se elige |
  | 🩺 | Diagnóstico de un fallo |
  | 🔭 | Dónde aparece de verdad |
  | 🪦 | Lo que ya no se usa |
  | ⚠️ | Errores frecuentes (obligatoria) |
  | 🧠 | Preguntas (obligatoria) |
  | 📚 | Referencias (obligatoria) |

---

## 4. 🎓 Pedagogía: "como para un bebé"

> **"Como para un bebé" significa cero ambigüedad, no menos profundidad.**

No es escribir más simple: es no dejar ningún hueco donde el lector tenga que adivinar. Se explica
qué tabla exactamente tiene el outbox, quién la lee, cada cuánto, qué pasa si el lector se cae a
mitad y por qué el mensaje puede llegar dos veces igualmente. No se dice "el outbox garantiza la
publicación" y se sigue adelante.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar el patrón, muestra el dolor que resuelve. *"Guardas el
   pedido en tu base y publicas `OrderPlaced` en el broker. Entre las dos líneas, el proceso
   muere. El pedido existe y nadie se enteró. Y si inviertes el orden, publicas un pedido que no
   existe."*
2. **El mecanismo después.** Ahora sí, el nombre y la definición mínima: lo justo para usarlo hoy.
3. **El código o el diagrama que lo demuestra**, con la viñeta que dice qué mirar en él.

Presentar el patrón antes que el problema produce gente que sabe recitar "el outbox garantiza
atomicidad" y no sabe cuándo *no* usarlo — que es exactamente lo que la entrevista pregunta.

Por eso **`## 1. 🎯 El problema` es la sección de apertura obligatoria de todo capítulo**.

### 4.2 Ningún bloque de código sin desglose, y ningún patrón sin precio

**Primera mitad: el código.** Ningún bloque aparece sin una frase antes que diga qué demuestra y sin
viñetas después que digan qué mirar en él. Un bloque `java` o `go` suelto es un error de estilo.

Los bloques son **mínimos**: la firma, la anotación y las tres líneas que importan, nunca una clase
completa con getters ni un `main()` con imports. Si un bloque introduce tres cosas desconocidas, se
parte en tres bloques. En los talleres la regla es la misma aunque el código completo exista en
`laboratorio/`: el taller muestra **recortes**, y cada recorte lleva su desglose (§13.3). Y cuando el mismo patrón se muestra en varias plataformas, **los bloques son
comparables entre sí**: mismo caso, mismos nombres, mismo recorte — lo que cambia es lo que la
plataforma te obliga a escribir, y eso solo se ve si lo demás no cambia.

**Segunda mitad: el precio.** Toda afirmación de beneficio lleva su contrapartida en la misma
sección. **Divergencia declarada respecto de arquitectura**, que fijaba cuatro monedas: aquí son
**cinco**, porque en un corpus de implementación el esfuerzo de escribir y mantener el patrón es un
coste de primera clase y es lo que más varía entre plataformas.

```text
latencia · consistencia · operación · dinero · esfuerzo de implementación
```

*"El outbox compra que el evento se publique sí o sí, y lo paga con una tabla más, un proceso que la
vacía, latencia de publicación de cientos de milisegundos, entrega al-menos-una-vez que obliga a
idempotencia aguas abajo, y —según la plataforma— entre una anotación y doscientas líneas de
cableado propio"* está completo. *"El outbox resuelve la doble escritura"* no lo está.

> **💰 Costo** es obligatorio la primera vez que un capítulo introduce un patrón cuyo precio no es
> obvio.

### 4.3 Explica el porqué, no solo el cómo

Cada decisión relevante lleva su porqué, aunque sea media línea entre paréntesis: por qué el
reintento necesita jitter y no solo backoff, por qué el timeout se calcula desde el p99 del
dependiente y no a ojo, por qué la saga coreografiada se vuelve ilegible a partir de cuatro pasos,
por qué el identificador de correlación se propaga por encabezado y no por el cuerpo.

Cuando el porqué es **histórico** —que en este temario pasa constantemente— se dice también: *"el
descubrimiento del lado del cliente con Eureka era la respuesta correcta cuando no había una
plataforma debajo que resolviera nombres; con Kubernetes, el `Service` ya lo hace y el registro en
la aplicación pasó a ser una pieza que mantener sin necesidad"*.

### 4.4 Ancla en la librería concreta, no en la abstracción

**Divergencia declarada respecto de arquitectura**, que anclaba todo concepto en Spring, y respecto
de APIs y protocolos, que anclaba en `curl` y prohibía explicar un concepto a través de un
framework. Aquí es al revés y es la razón de ser del corpus: **un patrón de microservicios se
aprende de verdad cuando sabes qué librería lo trae y qué te deja a ti**.

- No se escribe "se configura un circuit breaker": se escribe `Resilience4j` con su anotación, o
  `opossum` envolviendo la llamada, o `sony/gobreaker` cableado a mano, o `pybreaker` como
  decorador en código síncrono (con `asyncio`, `purgatory`: el `call_async` de `pybreaker` es de
  Tornado, como comprobó el taller `06/05`).
- No se escribe "se propaga el contexto de traza": se escribe el `traceparent` de W3C, el SDK de
  OpenTelemetry de cada plataforma, y **dónde se pierde** —el `ThreadLocal` que no cruza a un pool,
  el `AsyncLocalStorage` de Node, el `context.Context` que alguien no pasó en Go—.
- No se escribe "se define el contrato": se escribe el `.proto`, el `openapi.yaml` o el pacto de
  Pact, y quién genera qué a partir de él.

**La librería se nombra con su nombre exacto y su papel**, nunca "una librería de resiliencia". Y
cuando una plataforma **no tiene** la pieza, se dice que no la tiene y qué se hace en su lugar: esa
ausencia es contenido de primera, no una nota al pie.

> **⚠️ Advertencia:** nombrar una librería obliga a haber comprobado que existe, que se mantiene y
> que hace lo que dices. Una librería inventada o abandonada es el error más caro de este corpus,
> porque parece autoridad hasta que alguien la busca delante de un entrevistador. Ver §10.1.

### 4.5 Analogías con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan diciendo dónde se
rompen. Cuidado especial con las cinco más peligrosas del temario, que se desmontan en el mismo
párrafo en que aparecen:

- **un microservicio no es "un servicio pequeño"** (es uno dueño de sus datos y desplegable solo);
- **una saga no es "una transacción distribuida"** (no hay aislamiento, y por eso existen las
  anomalías que hay que diseñar a mano);
- **el circuit breaker no protege al servicio caído** (protege al que llama, y a veces acelera la
  caída del caído cuando todos reabren a la vez);
- **gRPC no es "HTTP más rápido"** (es un contrato compilado sobre HTTP/2, y su ventaja principal no
  suele ser el ancho de banda sino el contrato);
- **el service mesh no "te quita la resiliencia del código"** (te mueve una parte, y te añade un
  plano de control que se cae con su propia elegancia).

### 4.6 Densidad calibrada, con techo de longitud

- **Banda objetivo: 200 a 350 líneas por capítulo.** Un capítulo que pasa de 400 se poda o se parte,
  y la decisión se declara en el README del bloque. **Los capítulos de `05-plataformas` tienen banda
  propia: 250 a 400 líneas**, porque su trabajo es precisamente recorrer un ecosistema entero; el
  techo duro sigue siendo 450 y por encima se parte.
- Un concepto nuevo por vez.
- Repetir lo importante está bien. Los conceptos que sostienen el corpus —idempotencia, entrega
  al-menos-una-vez, propagación de contexto, el precio de la red— reaparecen con otras palabras.
- Ninguna sección supera las dos pantallas sin un diagrama, una tabla, un bloque de código o un
  veredicto.
- **Todo documento de más de ~400 líneas abre con un índice de salto rápido** (§6.2).

### 4.7 Cierra los bucles

Si abres un paréntesis —*"esto se ve en `03/04`"*, *"el tracing está en `04/04`"*— tiene que cerrarse
en algún documento del corpus, y con enlace real.

**Mientras el documento destino no exista, la referencia se escribe en prosa y sin enlace**, nunca
apuntando a un archivo que no está. Y ojo con el atajo habitual: en este corpus **los README se
escriben al final**, así que tampoco sirven de destino provisional. La mención queda en prosa y
**se convierte en enlace real cuando su destino se escribe**. Un enlace roto dentro del
propio corpus es peor que un enlace externo caído: el externo tiene disculpa, el interno no.

---

## 5. 💻 El eje de las cuatro plataformas

> **Regla normativa: el eje de comparación de este corpus son cuatro plataformas —Java, Node/TS, Go
> y Python—, y lo que se compara es qué te da hecho cada una para implementar el mismo patrón.**

**Divergencia declarada respecto de arquitectura**, que no tenía eje de lenguajes porque comparaba
decisiones, y respecto de `bases/01-bases`, que comparaba cinco lenguajes por su librería
estándar. Aquí la librería estándar casi no importa: **lo que implementa el patrón es el framework y
su ecosistema**, y por eso el eje son plataformas y no lenguajes.

**Por qué no hay JavaScript.** En `bases/01-bases` JavaScript se ganaba su sitio por lo que *le falta*
a su librería estándar, y esas ausencias cambiaban la respuesta. Aquí no: los frameworks de
microservicios de ese ecosistema —NestJS, Fastify, tRPC, los SDK de gRPC y OpenTelemetry— se
escriben y se documentan en TypeScript, y una fila de JavaScript diría *"igual que TS"* en los
quince capítulos. Lo que sí cambia la respuesta —bucle de eventos, un solo hilo, `worker_threads`,
`AsyncLocalStorage`— **es del runtime de Node, no del lenguaje**, y entra como propiedad de la
plataforma. De ahí la etiqueta: **Node/TS**, no "TypeScript".

### 5.1 Las cuatro plataformas y su reparto

El corpus compara **cuatro plataformas, siempre en este orden**: **Java · Node/TS · Go · Python**.
El orden es fijo en todas las tablas y en todos los bloques de código, y no se altera aunque en un
capítulo concreto una de ellas sea más interesante.

Cada una tiene un papel declarado, y el papel explica cuánto espacio recibe:

| Plataforma | Papel en el corpus | Cuánto espacio |
|---|---|---|
| **Java** | La plataforma del perfil base, y la que más te **da hecho**: Spring Boot y compañía traen el patrón detrás de una anotación. Es donde se muestra el ejemplo completo. | El grueso |
| **Node/TS** | El contraste de **runtime**: un hilo, bucle de eventos, contexto que se propaga con `AsyncLocalStorage`. Framework con opinión (NestJS) o sin ella (Fastify), y la diferencia se nota en cada patrón. | Alto |
| **Go** | El contraste de **filosofía**: casi nada te viene hecho, y eso es a propósito. Es donde el patrón se ve desnudo —`context.Context` con su deadline, la goroutine, el `select`—, y donde gRPC es ciudadano de primera. | Alto |
| **Python** | El contraste de **modelo de ejecución**: `asyncio` frente a WSGI, el GIL, y un ecosistema donde la pieza suele existir pero fuera del framework (Celery, `tenacity`, `pybreaker`). | Medio |

**Java recibe más espacio porque es el perfil base, no porque sea mejor**, y cada capítulo
que lo haga lo dice sin ceremonia. La contrapartida está en §2: a Java se le nombran sus costes con
la misma franqueza que a los demás.

### 5.2 La tabla de las cuatro plataformas

Es el recurso propio de este corpus y aparece en **todo capítulo que presente un patrón
implementable** —es decir, en casi todos—. Formato fijo: la plataforma en la primera columna, el
orden de §5.1, **una fila por plataforma, nunca una columna por plataforma**.

```markdown
| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | `Resilience4j` con `@CircuitBreaker`, métricas a Micrometer | Elegir los umbrales, y saber que el proxy no aplica en llamadas internas |
| **Node/TS** | `opossum`, o un interceptor de NestJS | El estado vive en el proceso: con varias instancias, cada una decide por su cuenta |
| **Go** | Nada en la librería estándar; `sony/gobreaker` es una struct | Cablearlo en cada cliente, y propagar el `context.Context` |
| **Python** | `pybreaker` como decorador en código síncrono, `purgatory` con `asyncio`; `tenacity` para el reintento | Elegir la librería según el modelo de ejecución, y el estado por proceso |
```

- **Nunca más de tres columnas además de la plataforma.** Si necesitas cuatro, el contenido no es
  una tabla: son cuatro subsecciones.
- **Excepción declarada: la matriz patrón × plataforma.** Cuando lo que se compara no es **un**
  patrón entre plataformas sino **todos** los patrones a la vez —la tabla maestra de
  `05-plataformas/01` y la matriz de esfuerzo de `05-plataformas/06`—, el eje de las filas es el
  patrón y las plataformas van en columnas. Es la única forma legible de presentar once patrones por
  cuatro plataformas, y solo se admite en esos dos sitios.
- La columna **"lo que te deja a ti"** es obligatoria y es la que rinde. Una tabla que solo lista
  librerías es un directorio, no una comparativa.
- Si una plataforma **no tiene** la pieza, la fila lo dice y dice qué se hace en su lugar. Nunca se
  omite una fila: cuatro filas siempre, aunque una diga "no existe, y se hace a mano así".
- **Excepción declarada: los talleres.** El laboratorio corre en tres plataformas —Java, Go y
  Python— (§13.1), así que la tabla 🧰 de un taller tiene **tres filas** y una línea debajo que
  remite al capítulo donde está la fila de Node/TS. Es la única tabla del corpus con menos de cuatro.

### 5.3 Cuándo se escribe código de cada plataforma, y cuándo basta la tabla

Escribir los cuatro bloques de código en cada patrón haría capítulos de mil líneas. La regla:

```text
Tabla de las cuatro   → siempre.
Bloque de código      → Java por defecto, siempre que el patrón se escriba.
                        Las otras tres, solo cuando el código cambia la respuesta.
```

**El código de una plataforma se escribe cuando su forma es distinta, no cuando es la misma con otra
sintaxis.** Un `@Retryable` de Java y un decorador de `tenacity` enseñan lo mismo: sobra el segundo.
Pero el `context.Context` de Go propagándose por la firma de cada función **sí** enseña algo que la
anotación esconde, y entonces se escribe.

**Java se puede omitir, pero se declara.** Hay capítulos donde lo que Java hace es una anotación que
el corpus ya mostró y son otras dos plataformas las que enseñan algo —el WebSocket con estado, el
contexto de traza que se pierde en el bucle de eventos—. Ahí se escriben esas dos y el capítulo dice
en una línea por qué Java no aparece y dónde está su equivalente. Lo que no se hace es omitirlo en
silencio: quien lee va a una entrevista de Java y lo busca primero.

Cuando un bloque se omite, **la fila de la tabla lo cubre** y el texto no promete lo que no está.

### 5.4 Versiones y baseline

Este corpus nombra librerías, y las librerías se mueven. Por eso:

- **La baseline de versiones se declara en `05-plataformas/01` y en el README del corpus**, no en
  cada capítulo.
- **Ningún capítulo fija un número de versión menor** salvo que el comportamiento cambie con él, y
  entonces se dice qué cambió y en qué versión.
- **Nunca se escribe `latest`** ni un rango donde el corpus fija un valor exacto.
- Lo que sea reciente al escribir —virtual threads cambiando el argumento del bulkhead, el mesh sin
  sidecar, gRPC-Web— se marca con 📝 para que quien repasa sepa que puede no coincidir con las
  respuestas "clásicas" de fuentes más viejas.

### 5.5 Idioma del código y sistema de ejemplo

> **Regla normativa: todo lo que se ejecuta o se versiona va en inglés —tipos, anotaciones, clases,
> métodos y campos del dominio, estados, servicios, topics y tablas—; la prosa y los comentarios
> dentro del código van en español.**

**Divergencia declarada respecto de arquitectura**, que dejaba el dominio en español
(`Pedido`, `reservar()`, `pedidos.confirmados`). Hasta 2026-09-28 este corpus heredaba esa regla; se
cambió el 2026-09-29 por tres razones: el bloque de talleres ejecuta código y ahí manda el
`CLAUDE.md` del repositorio ("todo lo ejecutable o versionado en inglés"); el curso hexagonal, que
comparte el caso de estudio, ya escribe así; y mantener dos convenciones —capítulos en español,
talleres en inglés— obligaba a una excepción permanente que se paga cada vez que alguien escribe un
documento nuevo. **La prosa no cambia:** "el servicio de pedidos", "la reserva", "el cobro" siguen
siendo español correcto; lo que va en inglés es el identificador, en backticks o dentro de un
bloque de código.

| Elemento | Idioma | Ejemplo |
|---|---|---|
| Nombres de patrón | Inglés (nombre canónico) | *saga*, *outbox*, *sidecar* |
| Tipos, anotaciones y API de framework | Inglés (son API real) | `@CircuitBreaker`, `context.Context`, `BaseModel` |
| Clases, métodos y campos del dominio | Inglés | `Order`, `reserve()`, `status` |
| Estados y enumerados del dominio | Inglés, mayúsculas | `PENDING`, `CONFIRMED`, `PAID` |
| Comentarios dentro del código | Español | `// aquí ya no hay vuelta atrás` |
| Nombres de servicio, cola, topic y tabla de dominio | Inglés | `orders`, `inventory`, `orders.placed` |
| Piezas técnicas genéricas: tablas de infraestructura, encabezados, métricas | Inglés | `outbox_events`, `processed_messages`, `traceparent` |
| Prosa, títulos y enunciados | Español | "el servicio de pedidos publica el hecho" |
| Términos del oficio consolidados | Inglés sin traducir | *backpressure*, *eventually consistent* |

**El sistema de ejemplo es único y no se cambia por capítulo.** Es el mismo dominio de comercio
electrónico del corpus de arquitectura, recortado a cinco servicios:

```text
                    ┌───────────┐
      cliente ──────► api-gateway│
                    └─────┬─────┘
          ┌───────────────┼───────────────┐
     ┌────▼────┐    ┌─────▼─────┐   ┌─────▼─────┐
     │ orders  │    │  catalog  │   │ customers │
     └────┬────┘    └───────────┘   └───────────┘
          │ (async, topic orders.placed)
     ┌────▼───────┐        ┌──────────┐
     │ inventory  │        │ payments │
     └────────────┘        └──────────┘
```

| Concepto | Nombres fijados |
|---|---|
| Servicios | `orders`, `catalog`, `customers`, `inventory`, `payments`, `api-gateway`; cuando un capítulo necesita más, `shipping`, `notifications` y `billing` |
| Agregados y entidades | `Order`, `OrderLine`, `Customer`, `Product`, `InventoryReservation`, `Payment` |
| Identificadores | `OrderId`, `CustomerId`, `ProductId`; en capítulos, valores tipo `ORD-00042`, `SKU-017`, `CUS-00007`; en talleres, UUID para pedidos y clientes y `SKU-001`…`SKU-005` para productos (§14) |
| Estados de pedido | `PENDING`, `CONFIRMED`, `PAYMENT_PENDING`, `PAID`, `PAYMENT_REJECTED`, `SHIPPED`, `CANCELLED` |
| Estados de reserva y de stock | `RESERVED`, `RELEASED`; stock `AVAILABLE` |
| Eventos | `OrderPlaced`, `InventoryReserved`, `InventoryReservationFailed`, `InventoryReleased`, `PaymentAuthorized`, `PaymentRejected`, `OrderCancelled`, `OrderShipped` |
| Comandos | `ReserveInventory`, `AuthorizePayment`, `ReleaseInventory` |
| Topics y colas | `orders.placed`, `inventory.reservations`, `payments.results`, y sus `.dlq` |
| Tablas de infraestructura | `outbox_events`, `processed_messages` |
| Host de ejemplo | `api.example.com`; interno, `orders.svc.cluster.local` (en talleres, el DNS de Compose: `orders`, `inventory`) |

**Qué significa cada estado, porque aquí está la trampa.** `CONFIRMED` es **stock reservado y pago
en curso**, no "el cliente confirmó". El hecho de que el cliente cerró el pedido se llama
`OrderPlaced` y deja el pedido en `PENDING`. Antes del 2026-09-29 los capítulos llamaban
`PedidoConfirmado` a ese hecho y `CONFIRMADO` a un estado previo a `RESERVADO`; una traducción
literal habría dado dos `CONFIRMED` con significados opuestos, que es justo el error que un
diccionario tiene que impedir.

```text
PENDING ──InventoryReserved──► CONFIRMED ──PaymentAuthorized──► PAID ──► SHIPPED
   │                              │ └── resultado incierto ──► PAYMENT_PENDING
   │                              └──PaymentRejected──► PAYMENT_REJECTED   (stock liberado)
   └──InventoryReservationFailed──► CANCELLED
```

**Diccionario inglés → español**, para leer el código con la prosa al lado:

| Código | En la prosa |
|---|---|
| `orders` · `inventory` · `payments` · `catalog` · `customers` | pedidos · inventario · pagos · catálogo · clientes |
| `shipping` · `notifications` · `billing` | envíos · notificaciones · facturación |
| `Order` · `OrderLine` · `InventoryReservation` · `Payment` | pedido · línea de pedido · reserva · cobro o pago |
| `OrderPlaced` | pedido registrado (el cliente lo cerró; la saga empieza) |
| `InventoryReserved` · `InventoryReservationFailed` · `InventoryReleased` | reserva confirmada · reserva rechazada · reserva liberada |
| `PaymentAuthorized` · `PaymentRejected` | pago aceptado · pago rechazado |
| `ReserveInventory` · `AuthorizePayment` · `ReleaseInventory` | reservar stock · cobrar el pedido · liberar stock |
| `PENDING` · `CONFIRMED` · `PAYMENT_PENDING` | en curso · reservado, pendiente de cobro · cobro incierto |
| `PAID` · `PAYMENT_REJECTED` · `CANCELLED` · `SHIPPED` | pagado · pago rechazado · cancelado · enviado |
| `orders.placed` · `inventory.reservations` · `payments.results` | los tres topics de la saga |

**La saga canónica del corpus** es siempre la misma, y se reutiliza en `03-datos-y-consistencia`, en
todos los capítulos que necesiten un ejemplo de flujo y en los talleres `08` y `09`: `orders`
registra el pedido y publica `OrderPlaced` → `inventory` reserva → `payments` cobra → si el cobro
falla, `inventory` libera. Un capítulo que necesite otro flujo **declara por qué** este no servía.

**Nunca uses `foo`, `Bar`, `MyService`, `service-a` ni `doSomething()`.** Un nombre sin significado
destruye exactamente la capacidad que el corpus intenta enseñar.

**Matiz sobre "tu sistema":** no vale como **nombre de ejemplo** —"tu sistema llama a tu servicio"—,
y sí vale cuando el texto se dirige al sistema real del lector, que es lo que hacen muchas preguntas:
*"¿qué servicios de tu sistema pasarías a Go?"*. La diferencia es si sustituye a un nombre que
debería ser concreto o si interpela al lector.

---

## 6. 🧱 Plantilla de los capítulos (`NN-tema.md`)

**Divergencia declarada respecto de arquitectura**: la plantilla incorpora dos secciones propias, 🧰
y ⚖️, que son las que hacen a este corpus distinto de un catálogo de patrones.

1. **Título** — `# NN — Tema` (dos dígitos, sin emoji en el título).
2. **Blockquote de encabezado** — qué cubre el documento en una o dos líneas, qué asume leído **con
   enlace**, y **`Vigencia:`** con la fecha en que se verificaron los enlaces.
3. **Índice de salto rápido** — solo si el documento pasa de ~400 líneas (§6.2).
4. **`## 1. 🎯 El problema`** — apertura obligatoria. El dolor antes que el nombre (§4.1).
5. **Secciones `##` numeradas**, una por patrón o concepto, con emoji funcional. **Numeración
   arábiga continua**, incluido el problema, que siempre es la `1`.
6. **`## N. 🧰 En las cuatro plataformas`** — **obligatoria en todo capítulo que presente un patrón
   implementable**. Lleva la tabla de §5.2 y los bloques de código que §5.3 justifique. Un capítulo
   que no la lleva declara en su encabezado por qué su contenido no se implementa (pasa en los de
   descomposición y organización, y en pocos más).
7. **`## N. ⚖️ Comparativa`** — obligatoria en todo capítulo que presente alternativas que compiten:
   HTTP contra gRPC, coreografía contra orquestación, descubrimiento en cliente contra en servidor,
   mesh contra librería. Es una tabla más un párrafo de veredicto, nunca una tabla sola.
8. **`## N. 🧭 Cómo se elige`** — recomendada cuando hay decisión. Árbol de decisión en bloque `text`
   seguido de la frase que se dice en voz alta.
9. **`## N. 🔭 Dónde aparece de verdad`** — recomendada. Dónde se topa un backend con esto fuera de
   una entrevista: la cadena de timeouts que nadie cuadró, el `Retry-After` que el cliente ignora, el
   consumidor que se quedó atrás y disparó el lag.
10. **`## ⚠️ Errores frecuentes`** — obligatoria. Tabla de dos columnas, **"Se dice" contra "Lo
    preciso"**, con entre cinco y ocho entradas.
11. **`## 📚 Para profundizar`** — cierre obligatorio (§10), máximo ocho entradas.
12. **`## 🧠 Preguntas`** — cierre obligatorio, sin respuestas visibles (§8).
13. **Pie de navegación** — una línea con **Anterior**, **Siguiente** y **Relacionado**.

### 6.1 El patrón fijo de cada concepto

Dentro de una sección `##` de patrón, el orden no varía. **Es el punto donde más diverge del corpus
de arquitectura**, porque incorpora la implementación como paso obligatorio:

```text
Qué es      → la definición mínima, en una o dos frases
Cómo va     → el mecanismo: el diagrama, la secuencia, las piezas que aparecen
Con qué     → la librería concreta en cada plataforma. NUNCA se omite.
Cuánto      → el precio en las cinco monedas de §4.2. NUNCA se omite.
Cuándo sí   → los casos donde se paga solo
Cuándo no   → los casos donde es ceremonia. NUNCA se omite.
Veredicto   → la frase que resume el criterio, en blockquote
```

**"Con qué", "Cuánto", "Cuándo no" y "Veredicto" son obligatorios**, y son lo que distingue a este
corpus de un catálogo. Un patrón sin "cuándo no" sugiere que siempre se usa, que es falso para
prácticamente todo lo que hay en el temario. La forma del veredicto:

```markdown
> **Veredicto:** el outbox se paga con una tabla, un proceso y latencia de publicación. Si tu
> publicación puede perderse sin consecuencias, no lo necesitas; si no puede, no hay alternativa
> más barata que no sea CDC.
```

Las secciones que no presentan un patrón elegible —el problema, la comparativa, el árbol de
decisión, los errores frecuentes— no llevan veredicto. Y en los capítulos que declaran **no** llevar
sección de plataformas (§6, punto 6), **el paso "con qué" decae con ella**: no hay librería que
nombrar porque no hay nada que implementar. Los otros tres obligatorios siguen siéndolo.

### 6.2 Índice de salto rápido

Formato fijo, justo después del blockquote de encabezado:

```markdown
**Salto rápido:** [01](#01--qué-es-un-microservicio) · [02](#02--descomposición-y-fronteras)
```

**Cómo se calcula un ancla de GitHub**, porque es donde se rompen estos índices: se pasa el
encabezado a minúsculas, se eliminan los caracteres que no son letra, número, espacio, guion o guion
bajo —lo que se lleva por delante el punto de la numeración, el emoji, los backticks y los
paréntesis— y por último los espacios restantes se convierten en guiones. Cada carácter borrado
**deja su espacio**, y de ahí salen los guiones dobles:

| Encabezado | Ancla |
|---|---|
| `## 4. 🧰 En las cuatro plataformas` | `#4--en-las-cuatro-plataformas` |
| `## 5. ⚖️ HTTP contra gRPC` | `#5--http-contra-grpc` |
| `## 🧠 Preguntas` | `#-preguntas` |

Fíjate en el último: un encabezado que empieza por emoji genera un ancla que **empieza por guion**.

### 6.3 Excepciones declaradas a la plantilla

- **`README.md` del corpus y de cada bloque** — índice, orden de lectura, mapa y la sección "Qué NO
  está aquí" que remite a los corpus hermanos.
- **`NN-simulacion-de-entrevista.md`** — el examen del bloque (§7.2).
- **`NN-respuestas.md`** — el solucionario del bloque (§7.3). No lleva preguntas propias, ni
  referencias, ni errores frecuentes.
- **`06-talleres/NN-tema.md`** — el taller, con su plantilla propia (§13.3).

---

## 7. 📐 Los tipos de documento

**El laboratorio existe, y es opcional.** Hasta el 2026-09-28 la decisión declarada era la
contraria: se había evaluado una serie práctica políglota —el mismo par de servicios en las cuatro
plataformas— y se descartó porque competía con los labs de AWS y GCP y porque el valor del corpus
estaba en el patrón, la comparativa y el criterio. El 2026-09-29 se revisó con otro diseño, que
esquiva las dos objeciones: el bloque `06-talleres/` **corre en local con Docker Compose**, sin nube
—así que no compite con AWS, GCP ni Azure, y esa frontera se conserva: nada de nube en los
talleres—, y **no repite el mismo servicio en cuatro plataformas**, sino que lleva un monolito a
servicios escritos cada uno en un lenguaje, para palpar lo que los capítulos solo pueden contar: la
llamada que se cuelga, el evento duplicado, la saga que nadie sabe en qué estado dejó el pedido.
Las reglas del bloque están en §13 y §14.

**El corpus teórico se sostiene sin los talleres.** Un capítulo puede mencionar el taller que
ejercita su patrón, en el pie o en una línea, pero **nunca depende de él**: nada de "esto lo verás
en el taller" como sustituto de una explicación.

Además del `README.md`, que se escribe al final de la producción, cada bloque teórico tiene
exactamente tres tipos de documento y ningún otro. El bloque `06-talleres/` tiene un cuarto tipo,
el taller (§13), y un solucionario único como los demás.

### 7.1 Capítulos `NN-tema.md`

El grueso del corpus. Siguen la plantilla de §6 sin desviaciones. Son **independientes entre sí en
lectura** pero acumulativos en vocabulario: cada uno declara en su encabezado qué asume leído, y no
vuelve a explicar lo que ya explicó otro.

### 7.2 Simulación `NN-simulacion-de-entrevista.md`

El examen del bloque, y el documento que más se parece a la entrevista real. Lleva:

- **Una sección de método** que fija cómo se usa: cronómetro a dos minutos, en voz alta, y solo
  después el solucionario.
- **Preguntas `S#` transversales**, agrupadas en bloques temáticos que cruzan capítulos. Entre 30 y
  45. Incluyen un bloque final de **"las que descolocan"**: criterio personal, conflicto con el
  entrevistador, liderazgo técnico.
- **Escenarios de diseño**, entre cuatro y seis, de quince minutos y con papel. **Cada escenario se
  elige para forzar una frontera distinta** y lo declara en una línea `**Fuerza:**`. Dos
  obligatorios en este corpus: uno donde **la respuesta correcta es no separar el servicio**, y uno
  donde **la plataforma cambia la respuesta** —el mismo patrón sale barato en una y caro en otra—.
- **Las frases que hay que tener listas** como cierre: dos o tres, en blockquote.

### 7.3 Solucionario `NN-respuestas.md`

Uno por bloque, y es el documento que hace útil a todo lo demás: **es lo que permite estudiar sin
ver la respuesta al lado de la pregunta**.

- Abre con índice de salto rápido, siempre: pasa de 400 líneas por definición.
- Se organiza por capítulo, con encabezado `# NN — Tema` por cada uno.
- **El enunciado se copia literalmente**, no se parafrasea.
- Formato de cada entrada: `**NN → P.** Enunciado literal en negrita.`
- **Respuesta en tres capas, siempre las tres y en este orden** (§8.3).

---

## 8. 🧠 Preguntas y respuestas

```text
capítulo       →  20 a 30 preguntas numeradas. Sin respuesta visible.
simulación     →  30 a 45 preguntas S# transversales + 4 a 6 escenarios.
solucionario   →  todas las respuestas, en tres capas, enunciado literal.
```

**Los capítulos no llevan sección de 🧪 Ejercicios:** en los bloques teóricos todo el peso
evaluador vive en las preguntas. **Excepción declarada: los talleres**, que llevan entre 10 y 15
preguntas y una sección de ejercicios graduados 🟢🟡🟠🔴 (más 🔥 fuera del conteo), como los labs de
los cursos de AWS y GCP (§13.3). Las respuestas de ambos van a `06-talleres/12-respuestas.md`.

### 8.1 Las preguntas de capítulo

- **Cantidad: 20 a 30**, calibrada por cuántas cosas distintas enseña el capítulo y se pueden
  comprobar por separado — nunca por su longitud.
- **Numeración arábiga continua dentro del capítulo**, reiniciada en cada capítulo.
- **Dificultad marcada al final del enunciado** con un solo emoji:

  | | Nivel | Qué pide |
  |---|---|---|
  | 🟢 | Definición | Reproducir un concepto que el capítulo enunció |
  | 🟡 | Distinción | Diferenciar dos cosas que se confunden |
  | 🟠 | Decisión | Elegir entre alternativas y justificar el precio |
  | 🔴 | Diseño o diagnóstico | Abierto: un flujo que diseñar o un fallo que explicar |

- **Reparto orientativo:** alrededor de 25 % 🟢, 25 % 🟡, 30 % 🟠 y 20 % 🔴, con un escalón de
  margen. Un capítulo de vocabulario carga hacia 🟢 y 🟡; uno de decisión —comunicación, saga,
  plataformas— carga hacia 🟠 y 🔴. **Que dos capítulos vecinos tengan idéntico reparto es señal de
  que el segundo se copió en vez de calibrarse.**
- **Orden: de menor a mayor dificultad.** Las 🔴 van al final, siempre.
- **Al menos dos preguntas por capítulo son de plataforma**, que es la aportación propia de este
  corpus: *"¿qué te da Go para esto, y qué te deja a ti?"*, *"el mismo patrón en NestJS y en Spring:
  ¿dónde vive el estado en cada uno?"*. En los capítulos de `05-plataformas`, la mayoría. **No
  aplica** a los capítulos que declaran no llevar sección de plataformas (§6, punto 6): ahí forzarla
  produce preguntas artificiales.
- **Las 🔴 piden un artefacto o una secuencia**, no una opinión: *"escribe la secuencia de la saga y
  di qué pasa si falla el paso 3"*, *"da tres hipótesis en orden de probabilidad"*, *"dibuja la
  topología y marca dónde pondrías el timeout"*.
- **Sin respuesta en el documento.** Va todo al solucionario del bloque.

### 8.2 La regla de sincronía

**Quien agregue, elimine o reordene una pregunta refleja el mismo cambio en el solucionario del
bloque en la misma edición**, con el enunciado copiado literalmente. Un solucionario desincronizado
es peor que no tenerlo.

La comprobación es mecánica y se corre antes de cerrar, desde el directorio del bloque:

```bash
for f in [0-9][0-9]-*.md; do
  case "$f" in *simulacion*|*respuestas*) continue;; esac
  n=$(sed -n '/^## 🧠 Preguntas/,$p' "$f" | grep -cE '^[0-9]+\. ')
  printf '%-45s %s\n' "$f" "$n"
done
grep -cE '^\*\*[0-9]{2} → [0-9]+\.' *-respuestas.md   # debe igualar la suma
```

### 8.3 Las tres capas de la respuesta

**Siempre las tres, siempre en este orden, siempre con su emoji.**

```text
⏱️ 30 segundos  → lo que dices primero, sin que te lo pidan. Una o dos frases.
🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más". Tres a cinco frases.
🔬 El detalle   → para estudiar, no para decir en voz alta. El matiz, la excepción,
                  la librería concreta, el número que nadie recuerda.
```

- **La capa de 30 segundos se escribe como se diría**, no como se escribiría. Si no cabe en una
  respiración, está mal. **No lleva nombres de librería**: en voz alta se nombra el patrón.
- **La capa de 2 minutos añade, no repite.** Es donde entra el precio.
- **El detalle es donde vive la plataforma**: la librería con su nombre, la diferencia entre
  ecosistemas, el caso donde la respuesta anterior no aplica.
- En las 🔴 de diseño, la capa de 2 minutos suele llevar un bloque `text` con la secuencia o la
  topología propuesta, y el detalle enumera lo que el entrevistador preguntará después.

---

## 9. 🧷 Vocabulario visual: reglas y callouts

### 9.1 Regla o mnemotecnia (bloque `text`)

Para una asociación mental que vale la pena aislar, en especial con forma de comparación o árbol de
decisión. Se etiqueta antes con una línea breve: "Regla:", "Regla mental:", "Regla de entrevista:".

```text
Síncrono  → el que llama depende de que el otro esté vivo AHORA
Asíncrono → el que llama depende de que el broker esté vivo ahora
```

### 9.2 Frase de respuesta correcta (blockquote)

Para la única frase que deberías decir en voz alta, normalmente después de mostrar la simplificación
incorrecta. El **veredicto** de §6.1 es un caso particular y usa siempre la etiqueta
`**Veredicto:**`.

Prueba práctica: si cabe en una oración y corrige o fija un concepto, va en blockquote; si es lista,
ecuación o comparación de dos o más líneas, va en bloque `text`.

### 9.3 Callouts admitidos

Se usan en blockquote, con negrita en la etiqueta. **Como mucho uno por sección `##`, y nunca dos
seguidos.**

- ⚠️ **Advertencia.** Ignorarlo produce una respuesta objetivamente incorrecta o rompe algo en
  producción. Uso escaso; nunca decorativo.
- 🧠 **Modelo mental.** La frase que hay que llevarse.
- 💡 **Truco.** El matiz que casi nadie dice y que sube la nota de la respuesta.
- 🩺 **Diagnóstico.** Cómo se confirma o descarta la hipótesis: qué mirarías primero, en qué panel,
  con qué traza.
- 💰 **Costo.** El precio del patrón en las cinco monedas de §4.2. **Obligatorio la primera vez que
  un capítulo introduce algo cuyo precio no es obvio.**
- 🧰 **Plataforma.** El apunte de ecosistema que no cabe en la tabla: lo que una plataforma hace de
  forma distinta, o directamente no hace. **Es el callout propio de este corpus** y se declara aquí
  como añadido a los heredados.
- 📝 **Contexto.** Por qué la respuesta "clásica" que el lector encontrará en fuentes viejas ya no
  aplica, o qué cambió en el ecosistema.
- 📚 **Referencia inline.** El enlace útil justo donde nace la duda.

**Escala de dificultad 🟢🟡🟠🔴.** Se usa **solo** en el enunciado de las preguntas (§8.1).

**Marcadores ✅ y ❌.** Se admiten como señal de sí/no dentro de tablas y de bloques `text` de
comparación. Nunca como decoración en prosa ni en un encabezado.

Fuera de esta lista, de ✅/❌, de la escala de dificultad y de los emojis de encabezado de §3, **no
se usan otros emojis**. Nada de 🚨, 💸, ⭐ ni 🎉. Las excepciones declaradas son 🪦 para la sección
"lo que ya no se usa", los tres de las capas de respuesta ⏱️ 🗣️ 🔬 en los solucionarios, y en los
talleres los de encabezado de §13.3 (🗂️ 🔎 🧨 🧪 🧹) y 🔥 para el ejercicio fuera del conteo.

### 9.4 Autopsia de un incidente

El recurso que mejor aprovecha que este corpus habla de sistemas que se caen. Cuando un capítulo
documenta un fallo clásico —la cascada por timeout mal puesto, el reintento que duplicó cobros, el
consumidor que se quedó atrás, el despliegue que rompió el contrato—, la estructura es:

1. **El síntoma**, tal y como lo ve el equipo a las tres de la mañana.
2. **La cadena**, en diagrama `text`: quién llamó a quién y dónde se acumuló.
3. **La causa**, incluyendo la decisión de diseño que la hizo posible.
4. **La corrección**, y si es de código, de configuración o de contrato.
5. **La generalización**: qué clase de error es y dónde más aparece.

Y los antipatrones se nombran sin piedad: el monolito distribuido, la base de datos compartida "solo
para leer", el reintento sin idempotencia, el servicio que solo hace CRUD sobre una entidad, la
librería común que obliga a desplegar a todos a la vez.

---

## 10. 📚 Bibliografía, referencias y enlaces

### 10.1 Enlaces externos y orden de autoridad

**Divergencia declarada respecto de arquitectura**, que ponía el libro primero y la documentación de
framework en tercer lugar. Aquí **la documentación de la librería sube al segundo puesto**, porque
la mitad de lo que enseña este corpus es qué trae cada ecosistema, y eso solo lo dice su
documentación. El cierre `## 📚 Para profundizar` admite, **en este orden y marcando el tipo**:

1. **Libro**, con autor, título, editorial, año y **capítulo concreto**. Sin URL. **Todo capítulo
   cita al menos uno**, y cuando hay uno que destaca se dice cuál.
2. **Documentación oficial de la librería o del framework** que el capítulo nombra —Spring, Quarkus,
   NestJS, el ecosistema de Go, FastAPI, Resilience4j, OpenTelemetry, gRPC, Pact, Debezium,
   Temporal—, con URL específica por concepto.
3. **Fuente primaria del autor del patrón** — `microservices.io` (Chris Richardson) es la referencia
   canónica del catálogo, `martinfowler.com` para los conceptos que él fijó.
4. **Especificación o proyecto de referencia neutral** cuando existe: OpenTelemetry, la
   especificación de OpenAPI o AsyncAPI, los proyectos de la CNCF.
5. **Material técnico de referencia de un proveedor**, cuando aporta el dato que no está en otro
   sitio: Amazon Builders' Library, Google SRE Book.
6. **Tutorial aplicado**, al final y marcado como tutorial. **Baeldung se cita por título entre
   comillas angulares y sin URL** (`Baeldung, «Guide to Resilience4j»`): su CDN responde `403` a
   cualquier verificación automática, así que su enlace no se puede comprobar por código de estado.
7. **Video o charla**, solo por **canal o conferencia y título, sin URL**.

**Máximo ocho entradas por capítulo.** Es un repaso, no una bibliografía.

Reglas duras, heredadas sin cambios:

- **No se inventan URLs.** Un enlace que no se pudo verificar no se escribe: se cita el nombre exacto
  de la página y se omite el enlace.
- **Se comprueban por código de estado, no a ojo**, y en la misma edición en que se escriben.
  Aterrizar en la portada del sitio en vez de en la página concreta cuenta como roto.
- **`martinfowler.com` limita la tasa**: verifícalo en serie y con encabezado de navegador, o
  devolverá `000` en paralelo y parecerá caído sin estarlo.

**Y una regla propia de este corpus, que es la más importante de §10:**

- **Ninguna librería se nombra sin haber comprobado que existe, con su nombre exacto, y que sigue
  mantenida.** Se verifica en su repositorio o en el registro de paquetes de su plataforma —Maven
  Central, npm, `pkg.go.dev`, PyPI— en la misma edición. Si una librería lleva años sin commits, se
  puede nombrar, pero **se dice que está sin mantenimiento**: eso es información, no un descarte
  automático. Lo que no se hace jamás es inventar el nombre plausible de un paquete.

### 10.2 Enlaces internos

- **Formato:** enlace Markdown relativo, con el número del documento en el texto visible:

  ```markdown
  ver [`04` — El monolito distribuido](04-el-monolito-distribuido.md)
  ```

- **Con ancla cuando la sección destino existe y es estable:**

  ```markdown
  ver [`03` §5 — orquestación](03-saga.md#5--orquestación)
  ```

- **Entre bloques, con ruta relativa al bloque:**

  ```markdown
  ver [`02-comunicacion`](../02-comunicacion/)
  ```

- **Hacia otros corpus, con ruta relativa y diciendo qué hay allí**, no solo enlazando:

  ```markdown
  La decisión de si separar el servicio está en
  [`arquitectura/01-bases/01-bases/02`](../../01-bases/01-bases/02-estilos-de-despliegue.md)
  — aquí se asume tomada y se entra a implementarla.
  ```

- **Cada capítulo enlaza al menos a los dos capítulos con los que más se toca**, y cierra con el pie
  de navegación de §6, punto 13.
- **Al renombrar un archivo o un encabezado se revisan los enlaces entrantes en la misma edición.**

Verificación mecánica, desde el directorio del bloque:

```bash
grep -oh '](\([0-9]\{2\}-[^)#]*\.md\)' *.md | sed 's/](//' | sort -u | while read -r f; do
  [ -f "$f" ] || echo "ROTO: $f"
done
```

### 10.3 Vigencia

El README del corpus declara la fecha de revisión general y **cada documento la repite en su
blockquote de encabezado**. Lo que sea reciente al escribir se marca con 📝 en el propio texto.

---

## 11. 🔗 Coherencia entre documentos

- **No contradecir documentos anteriores.** Si `01/01` establece que un servicio es dueño de sus
  datos, `03/01` puede matizar las excepciones, nunca contradecirlo.
- **Terminología estable.** Si `02/01` dice "acoplamiento temporal", el resto del corpus no lo llama
  "acoplamiento en el tiempo". Si el corpus de arquitectura ya fijó un término, este lo respeta.
  Los que se han fijado explícitamente, porque son los que más se desvían solos:

  | Se escribe | No se escribe | Por qué |
  |---|---|---|
  | *circuit breaker* | "cortacircuitos" | Nombre canónico del patrón, y es lo que usa el corpus de arquitectura |
  | contexto acotado | "bounded context" en el cuerpo | Traducción asentada; el inglés, entre paréntesis en la primera aparición |
  | encabezado | "cabecera" | Lo fijó `bases/04-apis-protocolos` |
  | apagado ordenado | "graceful shutdown" | Traducción asentada y sin ambigüedad |
  | *bulkhead*, *outbox*, *saga*, *sidecar* | traducciones forzadas | Nombres canónicos de patrón (§3) |

  La prueba para decidir en un caso nuevo: **¿es el nombre propio de un patrón o una palabra común?**
  El nombre propio se queda en inglés; la palabra común se traduce.
- **El sistema de ejemplo de §5.5 manda.** Cualquier desviación se declara en el documento que la
  introduce, con su porqué.
- **Un concepto tiene un solo dueño.** `02/01` es dueño del mapa de estilos de comunicación; `03/03`
  de la saga; `04/03` de la resiliencia; `05/01` de la tabla maestra de plataformas. Los demás usan
  y enlazan.
- **Los bloques no se repiten entre sí.** `01` da el vocabulario y las fronteras; `02` a `04`
  implementan; `05` recorre los ecosistemas y **no vuelve a explicar ningún patrón**: los enlaza.
- **La frontera con los corpus hermanos es de altitud, no de tema.** Los cuatro pueden hablar de
  idempotencia sin duplicarse:

  ```text
  arquitectura        → ¿qué decisión de sistema implica, y a qué precio?
  apis y protocolos   → ¿qué obliga el protocolo, y dónde lo dice el RFC?
  spring              → ¿cómo se escribe con este framework?
  microservicios      → ¿qué patrón es, con qué se implementa en cada plataforma,
                        y qué cambia entre ellas?
  ```

- **Fuentes de verdad, en orden:**
  1. **Esta guía y los demás documentos de `prompts/`**, que según la regla de precedencia de
     `CLAUDE.md` mandan sobre las normas por defecto del repositorio en todo lo que declaren.
  2. **`CLAUDE.md` de la raíz**, para todo lo que esta guía no toca.
  3. **`prompt-base.md`**, para el alcance y el contenido obligatorio de cada documento.
  4. **`README.md`** del corpus y del bloque, para orden de lectura y mapa.
  5. **Documentos ya publicados** — no se contradicen, se matizan.
  6. Decisiones explícitas del chat actual.

---

## 12. ✅ Checklist antes de dar por cerrado un `.md`

**Estructura**

- [ ] Sigue la plantilla de §6, o está declarado como excepción (README, simulación, solucionario).
- [ ] Encabezado con objetivo, qué asume leído **con enlace**, y **`Vigencia:`**.
- [ ] Índice de salto rápido si pasa de ~400 líneas (§6.2).
- [ ] Abre con `## 1. 🎯 El problema`, no con una definición (§4.1).
- [ ] Numeración `##` arábiga y continua; emoji funcional en `##`, **ninguno en `###`**.
- [ ] Hay sección **`🧰 En las cuatro plataformas`**, o está declarado por qué el capítulo no la
      lleva.
- [ ] Hay sección **`⚖️ Comparativa`** si el capítulo presenta alternativas que compiten.
- [ ] Cierra con pie de navegación: Anterior, Siguiente y Relacionado.

**Contenido**

- [ ] Cada patrón sigue **qué es → cómo va → con qué → cuánto → cuándo sí → cuándo no → veredicto**
      (§6.1), sin saltarse ninguno de los cuatro obligatorios.
- [ ] Toda afirmación de beneficio lleva su precio en las **cinco** monedas de §4.2.
- [ ] Ningún bloque de código sin frase antes y viñetas después; bloques mínimos y **comparables
      entre plataformas** (§4.2).
- [ ] La tabla de las cuatro plataformas tiene **las cuatro filas** y la columna "lo que te deja a
      ti" (§5.2).
- [ ] Cada librería nombrada existe, se escribe con su nombre exacto y se comprobó en esta edición
      (§10.1).
- [ ] Ninguna cifra de rendimiento sin decir de dónde sale y qué no mide (§2).
- [ ] Se nombra explícitamente cuando una respuesta común de entrevista es una sobregeneralización.
- [ ] Hay `## ⚠️ Errores frecuentes` con tabla "Se dice / Lo preciso", 5–8 entradas.
- [ ] Nada que sea territorio de arquitectura, APIs, Spring, AWS o GCP: se enlaza, no se reescribe
      (§1.1).
- [ ] Sistema de ejemplo de §5.5 respetado, con `CONFIRMED` como "stock reservado"; sin `foo`, sin
      `service-a`, sin "tu sistema".
- [ ] Entre 200 y 350 líneas (250–400 en `05-plataformas`). Si pasa del techo, se poda o se parte.

**Forma**

- [ ] Tono semi formal y cálido, tuteo latinoamericano, humor casi ausente (§2).
- [ ] Neutralidad entre plataformas: ninguna se ridiculiza, y a Java se le nombran sus costes (§2).
- [ ] Sin prosa telegrama: una o dos frases aisladas por sección como mucho (§3).
- [ ] Tablas solo para comparar o mapear, sin celdas que necesiten explicación.
- [ ] Como mucho un callout por sección `##`, nunca dos seguidos, y solo los de §9.3.
- [ ] Identificadores en inglés con los nombres de §5.5, prosa y comentarios en español (§5.5).

**Evaluación**

- [ ] Entre 20 y 30 preguntas, graduadas 🟢🟡🟠🔴, **ordenadas de menor a mayor dificultad**, sin
      respuesta visible (§8.1).
- [ ] Al menos dos preguntas de plataforma, si el capítulo lleva esa sección (§8.1).
- [ ] Reparto de dificultad distinto al del capítulo vecino.
- [ ] **Si tocaste alguna pregunta, actualizaste el solucionario del bloque en la misma edición**
      (§8.2), con el enunciado copiado literal.
- [ ] En el solucionario: las tres capas ⏱️ 🗣️ 🔬 en todas las respuestas, sin excepción.

**Referencias y enlaces**

- [ ] `## 📚 Para profundizar` presente, máximo ocho entradas, ordenadas por autoridad (§10.1), con
      al menos un libro con capítulo concreto.
- [ ] Todas las URLs verificadas por código de estado **en esta edición**.
- [ ] Baeldung citado por título sin URL; video citado por canal y título sin URL.
- [ ] Al menos dos enlaces internos a los capítulos vecinos, y ningún enlace interno roto.
- [ ] Los enlaces a otros corpus dicen **qué hay allí**, no solo enlazan.
- [ ] Ningún enlace a un documento que todavía no existe: mientras tanto, la mención va en prosa
      (§4.7).

**Coherencia**

- [ ] No contradice ningún documento anterior, y la terminología coincide con la ya fijada (§11).
- [ ] Ningún bucle abierto sin cerrar: toda promesa de "esto se ve en X" tiene su enlace.

---

## 13. 🧪 Bloque 06 · Talleres

El bloque `06-talleres/` lleva el sistema de ejemplo **de un monolito a servicios**, en local, y
provoca a propósito los fallos que los capítulos describen. Enseña a **palpar** qué pasa cuando la
frontera es la red; no enseña frameworks. **Todo el bloque es opcional** y lo declara su README;
cada taller lo vuelve a declarar en su primer párrafo, junto con sus prerrequisitos.

Hay un segundo objetivo, tan importante como el primero: el perfil senior suele tener dificultad para
**tomar una base de código que no escribió y orientarse rápido en ella**, que es lo que pide un
cambio de trabajo o una prueba técnica en vivo. Por eso cada taller tiene una sección fija de
**recorrido de la base de código** (§13.3) y ejercicios que se responden con ruta y línea.

### 13.1 Inventario y dependencias

```text
06-talleres/
├── README.md                                 mapa, dependencias, recorridos y "todo aquí es opcional"
├── 01-el-monolito-y-su-contrato.md           monolito, contrato, suite v1, compose, lab.py
├── 02-strangler-fig-con-envoy.md             Envoy delante; inventory extraído a Go
├── 03-http-entre-servicios.md                payments extraído a Python; timeout, reintento, idempotencia
├── 04-grpc.md                                inventory por gRPC; orders sale del monolito
├── 05-resiliencia-en-tres-plataformas.md     breaker, bulkhead, límite de tasa, health checks
├── 06-kafka-outbox-inbox-y-dlq.md            outbox, consumidores idempotentes, DLQ
├── 07-observabilidad-de-extremo-a-extremo.md una traza que cruza HTTP, gRPC y Kafka
├── 08-saga-coreografiada.md                  contrato v2 con 202; la saga sin dueño
├── 09-saga-orquestada.md                     la misma saga con dueño; comparación y autopsia
├── 10-contratos-y-testing.md                 opcional dentro del bloque: 03 + 04 + 06
├── 11-consultas-y-tiempo-real.md             opcional dentro del bloque: 06 + 08
├── 12-respuestas.md                          solucionario único del bloque
└── laboratorio/                     el estado del último taller escrito
    ├── estados/NN/  copia congelada del laboratorio al terminar el taller NN (`lab.py --estado NN`)
    ├── contrato/    openapi.yaml · hurl/v1 · hurl/v2 · proto/ · pacts/ · envoy/ · otel/ · docker-compose.yml · seed/
    ├── scripts/     lab.py — Python 3, solo biblioteca estándar
    ├── monolith/    ms-monolith, Java
    ├── orders/      Java (desde 04)
    ├── inventory/   Go (desde 02)
    ├── payments/    Python (desde 03)
    ├── psp-simulator/   el proveedor de pago externo, Python sin dependencias
    └── tools/       bench/ (04–05) · otel/ (agente de Java, no versionado) · cierre-09/ (parches con
                     los stubs fraud y loyalty: solo para el cierre de 09, no forman parte del sistema)
```

```text
01 ─► 02 ─► 03 ─► 04 ─► 05 ─► 06 ─► 07 ─► 08 ─► 09
                  │            │            │
                  └──────┬─────┘            │
                         ▼                  ▼
                   10 (03+04+06)      11 (06+08)
```

**Reparto de plataformas: Java, Go y Python.** Cada servicio vive en **un solo lenguaje**
—`orders` y el monolito en Java, `inventory` en Go, `payments` en Python— y la mezcla la produce el
sistema, no la repetición de cada taller tres veces. La excepción es `05`, donde implementar **lo
mismo** en las tres es el objetivo. Node/TS queda fuera de los talleres, declarado: su contraste de
runtime ya está en los capítulos y en el taller de NestJS del curso hexagonal, y una cuarta toolchain
no enseña una idea nueva.

### 13.2 El contrato manda

El monolito de partida trae un `openapi.yaml` y una **suite `hurl` que es la invariante de toda la
serie**: tiene que seguir en verde después de cada extracción, cambiando solo la URL base (primero
el monolito, después Envoy). Es el argumento del *strangler fig* convertido en un comando: el
cliente no se entera.

- **`hurl/v1`** es el contrato síncrono heredado: `POST /api/v1/orders` crea el pedido y reserva el
  stock en el mismo acto (`201`, estado `CONFIRMED`) o responde `409`. Invariante de `01` a `07`, y
  sigue en verde después, servida por la ruta síncrona con los encabezados `Deprecation` y `Sunset`.
- **`hurl/v2`** nace en `08`: `POST /api/v2/orders` responde `202 Accepted` con estado `PENDING`, y
  el cliente consulta el pedido hasta que la saga lo lleva a un estado final. Es la decisión del
  bloque: **la consistencia eventual se filtra al contrato**, y esconderla (esperar a la saga antes
  de responder) es reinventar el 2PC con peor cara. La alternativa de hacer asíncrono solo el pago
  queda como ejercicio 🟠 de `09`.

Un taller **no añade endpoints** fuera de lo que su ficha de `prompt-base.md` declara, y los que
añade se etiquetan en el `openapi.yaml` con `x-suite` y el número del taller.

### 13.3 Plantilla del taller

```text
qué enseña → prerrequisitos y versiones exactas → mapa de carpetas → recorrido de la base de código
→ partes en orden, cada una con su fallo provocado ANTES de la corrección → evidencia
→ 🧰 plataformas → teardown → ⚠️ errores frecuentes → 📚 referencias → 🧠 preguntas → 🧪 ejercicios
```

| Encabezado | Emoji |
|---|---|
| Qué enseña este taller | 🎯 |
| Prerrequisitos y versiones | 🧰 |
| Mapa de carpetas | 🗂️ |
| Recorrido de la base de código | 🔎 |
| Cada parte | 🧱, 🔀, 🔁 según sea mecanismo, corte o flujo |
| Provocaciones | 🧨 |
| Evidencia | 🧪 |
| Diagnóstico de los errores reales | 🩺 |
| Teardown | 🧹 |

- **Vibecoding declarado.** El código se genera con un asistente y el taller no lo comenta línea a
  línea: explica la decisión —dónde está la frontera, por qué ese timeout, qué se llevó la red— y
  muestra solo los recortes que la demuestran, cada uno con su desglose (§4.2). Como el código lo
  escribe un asistente, **la evidencia manda sobre la prosa**: una afirmación sin salida pegada no
  cierra un taller.
- **El recorrido de la base de código es obligatorio.** Antes de cambiar nada, una lectura dirigida
  con rutas reales: dónde está el punto de entrada, dónde se construyen las dependencias, dónde vive
  el timeout, qué configuración pisa a cuál.
- **Ningún comando ni flag queda sin explicar.** Después de cada bloque de comandos va el desglose en
  viñetas. La orquestación es `laboratorio/scripts/lab.py` (Python 3, solo biblioteca estándar): no
  hay scripts `bash` ni PowerShell. En el texto se invoca como `python3 laboratorio/scripts/lab.py ...`
  y se desglosa igual que un comando.
- **Los errores se provocan a propósito**, con órdenes de `lab.py` (`psp-slow`, `kill-consumer`,
  `cut inventory`…), siempre **antes** de la corrección, y con la salida pegada. **Toxiproxy** va
  delante de cada dependencia remota para la latencia y los cortes; nada de `sleep` en el código de
  negocio.
- **Los errores reales se documentan** en una sección 🩺 con el síntoma literal, la causa y la
  lección, igual que una autopsia (§9.4). Un taller que no encontró ninguno lo dice.
- **La evidencia es literal y fechada**: la salida de la suite, el `git diff --stat` del cambio
  (entre dos instantáneas del código, con `git diff --no-index --stat`), la fila de la base, la
  traza. Nunca una salida escrita a mano.
- **Teardown junto al recurso.** Lo que se levanta en una sección se apaga en esa sección; el compose
  común se apaga al final de cada taller y se vuelve a levantar al empezar el siguiente.
- **El laboratorio es acumulativo, y cada taller congela su estado.** Los talleres modifican el mismo
  sistema (el taller 02 quita los `JOIN` que describe el 01; el 04 saca `orders` del monolito). Por
  eso, al cerrar cada taller, su código queda copiado en `laboratorio/estados/NN/` y no se vuelve a
  tocar; `laboratorio/` a secas es siempre el estado del último taller escrito. `lab.py --estado NN
  <orden>` trabaja sobre esa copia. **El recorrido de la base de código y las rutas con número de línea
  de cada taller citan `laboratorio/estados/NN/`**, que es lo único que no cambia.
- **Versiones exactas, verificadas el día de escritura**, con la baseline del corpus (Java 25,
  Spring Boot 4.1, Go 1.27, Python 3.14). Nunca `latest`, `^`, `~` ni rangos. Cada librería se
  comprueba en su registro en la misma sesión (§10.1).
- **Ninguna cifra de rendimiento sin decir de dónde sale y qué no mide.** La única medición del
  bloque es la de `04` (HTTP contra gRPC), etiquetada "reproducción local, un solo nodo, sin red
  real".
- **Preguntas y ejercicios:** entre 10 y 15 preguntas 🟢🟡🟠🔴 ordenadas de menor a mayor, y entre 6
  y 8 ejercicios graduados, más un 🔥 opcional fuera del conteo. Al menos uno de los ejercicios es
  **de orientación en código ajeno** ("¿en qué archivo y línea se decide el offset que se
  confirma?"). Todo se copia literal a `12-respuestas.md` con las tres capas de §8.3.

### 13.4 Qué no hace un taller

- No enseña el framework: no explica qué es un bean, un `Depends` ni un `http.Handler` más allá de lo
  que hace falta para ubicar la decisión.
- No reabre decisiones de los capítulos: si hay que matizar una, enlaza el capítulo y dice qué cambió
  al correrlo.
- No usa la nube, Kubernetes ni un mesh: lo que necesita un orquestador (mesh, canary, descubrimiento
  dinámico) se queda en los capítulos `04/01`, `04/05` y `04/06`, y el taller lo dice.
- No compara rendimiento entre plataformas. Compara mecanismo, esfuerzo y dónde se rompe.

### 13.5 Checklist solo para talleres

- [ ] Declara en su primer párrafo que es opcional y de qué talleres depende.
- [ ] Sigue la plantilla de §13.3, con recorrido de la base de código.
- [ ] Todos los nombres, puertos, credenciales y semillas son los de §14.
- [ ] Ningún bloque de comandos sin desglose; la orquestación es `lab.py`; ninguna versión es
      `latest` ni un rango.
- [ ] Cada parte cierra con la suite en verde, la salida pegada y fechada.
- [ ] Al menos un fallo provocado por parte, antes de la corrección.
- [ ] Tabla 🧰 de tres filas con la línea que remite a Node/TS (§5.2).
- [ ] Teardown junto al recurso.
- [ ] 10–15 preguntas y 6–8 ejercicios, copiados literalmente a `12-respuestas.md` con las tres
      capas.
- [ ] Reparto de dificultad de preguntas **y** de ejercicios distinto al del taller vecino, calibrado
      por lo que el taller enseña (§8.1); el ejercicio de orientación en código ajeno sigue siendo 🟢.

---

## 14. 🔒 Nombres fijos del laboratorio

No se inventan valores nuevos. Lo que no esté aquí lo fija el taller que lo necesita, en su tanda, y
se añade a esta sección en la misma edición.

| Qué | Valor |
|---|---|
| Prefijo de todo recurso | `ms-` |
| Proyecto compose | `ms-lab` |
| Puertos en el host | rango `2xxxx`, para no chocar con el curso hexagonal (`1xxxx`, `808x`) ni con el laboratorio de bases de datos (puertos estándar) |
| Una base por servicio | `ms_monolith`, `ms_orders`, `ms_inventory`, `ms_payments`, en el mismo servidor PostgreSQL: la regla es de propiedad del dato, no de servidor; cada servicio tiene su usuario y no puede leer las otras bases |
| Prefijo de la API | `/api/v1`; `/api/v2` desde `08` |
| Usuarios semilla | `ana@ms.local` / `ana-12345` con rol `customer` (`11111111-1111-4111-8111-111111111111`) · `ops@ms.local` / `ops-12345` con rol `operator` (`22222222-2222-4222-8222-222222222222`) |
| Productos semilla | `SKU-001` Mechanical keyboard 49.90 (stock 20) · `SKU-002` USB-C cable 9.90 (100) · `SKU-003` 27" monitor 222.00 (5) · `SKU-004` Webcam 59.00 (**0**) · `SKU-005` Workstation 1499.00 (3) |
| Moneda | `USD`, importes como decimal con dos cifras, nunca `double` |
| Regla del `psp-simulator` | total `> 1000.00` → rechazado; total `== 666.00` → resultado incierto (no responde a tiempo); resto → autorizado |
| Errores HTTP | `application/problem+json` (RFC 9457) con `type`, `title`, `status`, `detail`, `instance` y un `code` estable propio |
| Topics (desde `06`) | `orders.placed`, `inventory.reservations`, `payments.results` y sus `.dlq`, clave `orderId` |
| Tablas de infraestructura | `outbox_events`, `processed_messages` |

`SKU-004` sin stock provoca el stock insuficiente; `SKU-005` provoca el rechazo del pago; tres
`SKU-003` suman `666.00`, el importe que ejercita el resultado incierto sin un tercero real. Con esas
tres palancas se ejercitan **todas** las ramas de una saga.

### 14.1 Fijado por `06/01` (T12, 2026-09-29)

| Qué | Valor |
|---|---|
| Contenedores | `ms-postgres` · `ms-toxiproxy` · `ms-mock` (perfil `mock`) |
| Imágenes | `postgres:17.11-alpine` · `ghcr.io/shopify/toxiproxy:2.12.0` · `stoplight/prism:5.15.10` |
| PostgreSQL | host `25432`; superusuario `ms_admin` / `ms-lab-pass`; usuarios `ms_monolith`, `ms_orders`, `ms_inventory`, `ms_payments`, todos con `ms-lab-pass` (solo desarrollo), cada uno dueño de su base y sin `CONNECT` sobre las demás |
| Toxiproxy | API en `28474`; proxy `psp` en `28185` → `host.docker.internal:28085`; cada dependencia nueva tiene su proxy, declarado en `contrato/toxiproxy/proxies.json` |
| Mock del contrato | `24010` (`lab.py mock`) |
| `ms-monolith` | `28081`; Spring Boot `4.1.1`, JDK `25`; pool HikariCP `5` con `connection-timeout` `2000` ms; `lab.py monolith [--port] [--pool N]` |
| `psp-simulator` | `28085`; Python sin dependencias; `POST /payments`, `GET /payments` (registro de cobros), `POST /admin/reset`; el importe `666.00` responde a los 3 s, y el cobro sí se registra |
| Cliente del PSP en el monolito | `ms.psp.base-url=http://localhost:28185` (vía Toxiproxy), `connect-timeout-ms` `1000`, `read-timeout-ms` `2000` |
| Reservados para los talleres siguientes | Envoy `28080` (admin `29901`) · `orders` `28082` · `inventory` `28083` (gRPC `28093`) · `payments` `28084` |
| JWT | HS256, secreto `ms-lab-dev-secret-change-me-0123456789` (38 bytes: HS256 exige al menos 32); claims `sub`, `email`, `role`, `jti`, `exp`; vida 900 s; lo emite el monolito (`customers` se queda dentro) |
| Suite | `contrato/hurl/v1/01-health` … `06-cancel`; `lab.py suite [--base-url] [--dir] [--no-seed]` siembra antes salvo `--no-seed` |
| Claves de idempotencia de la suite | prefijo `suite-v1-`; las de `lab.py storm`, prefijo `storm-` |

### 14.2 Fijado por `06/02` (T13, 2026-09-29)

| Qué | Valor |
|---|---|
| api-gateway | `ms-envoy`, imagen `envoyproxy/envoy:v1.39.1`; API en `28080`, administración en `29901`; configuración en `contrato/envoy/envoy.yaml`; clúster `monolith` con `dns_lookup_family: V4_ONLY` |
| JWT en el borde | filtro `jwt_authn`, proveedor `ms_monolith`, JWK `oct` con el secreto de §14.1 en base64url; sin token en `/health` y `POST /api/v1/auth/login`; `forward: true` y `forward_payload_header: x-jwt-payload` |
| Errores del gateway | `local_reply_config`: `401` → `UNAUTHENTICATED`, `503` → `SERVICE_UNAVAILABLE`, `504` → `GATEWAY_TIMEOUT`, todos `application/problem+json` |
| `inventory` | Go `1.27.1`, `pgx` `v5.11.0`; HTTP en `28083`; base `ms_inventory` (tablas `inventory(sku, on_hand)` y `holds(id, reference, sku, qty, status)`); `lab.py inventory [--db own\|shared]` |
| API interna de `inventory` | `GET /stock?sku=…`, `POST /holds` (`reference` = id del pedido; `201`, o `200` si se repite), `POST /holds/{reference}/release`, `POST /holds/{reference}/commit`; error `409 OUT_OF_STOCK` con `shortages` |
| Toxiproxy | proxy `inventory` en `28183` → `host.docker.internal:28083`; `lab.py slow inventory --latency MS \| --off` |
| Monolito | `ms.inventory.mode` `local` \| `remote` (`lab.py monolith --inventory`); `ms.inventory.base-url=http://localhost:28183`, `connect-timeout-ms` `500`, `read-timeout-ms` `800` (`--inventory-timeout 0` lo quita) |
| Código de error nuevo | `INVENTORY_UNAVAILABLE` (`503`) |
| Estados congelados | `laboratorio/estados/01/` y `laboratorio/estados/02/`; `lab.py --estado NN` |

### 14.3 Fijado por `06/03` (T14, 2026-09-29)

| Qué | Valor |
|---|---|
| `payments` | Python `3.14.7` con `uv` (`uv sync --python 3.14`, sin `.python-version`); `fastapi==0.141.1`, `uvicorn==0.54.0`, `httpx==0.28.1`, `psycopg[binary]==3.3.6`, `psycopg-pool==3.3.3`; HTTP en `28084`; `lab.py payments` |
| Base de `payments` | `ms_payments`, tabla `payments(id, order_id, operation_id UNIQUE, amount, status, reference)`; estados `IN_PROGRESS`, `AUTHORIZED`, `REJECTED`, `PENDING` |
| API de `payments` | `POST /payments` (`Idempotency-Key` opcional; `201`, `200` con `Idempotent-Replay` si se repite una respuesta firme, `409 PAYMENT_IN_PROGRESS`); un `PENDING` repetido vuelve a preguntar al proveedor; `GET /payments`; `GET /health`. Timeout hacia el PSP: 2 s (`PAYMENTS_PSP_TIMEOUT_S`) |
| Toxiproxy | proxy `payments` en `28184` → `host.docker.internal:28084`; `lab.py slow payments` |
| Monolito | `ms.payments.mode` `local` \| `remote` (`lab.py monolith --payments`); `base-url http://localhost:28184`, `connect-timeout-ms` `500`, `read-timeout-ms` `2500`, `propagate-key` (`--no-payment-key` lo apaga) |
| Resiliencia del monolito hacia `payments` | Resilience4j `2.4.0` programático (sin AOP): reintento 3 intentos, backoff exponencial desde 200 ms con ±50 % de jitter, sobre `ResourceAccessException` y `5xx`; circuit breaker por recuento, ventana 10, mínimo 4, 50 %, abierto 10 s, 2 llamadas en semiabierto; `4xx` ignorados |
| Código de error nuevo | `PAYMENTS_UNAVAILABLE` (`503`): seguro que no se cobró; el pedido sigue pagable |
| Estados congelados | + `laboratorio/estados/03/` |

### 14.4 Fijado por `06/04` (T15, 2026-09-29)

| Qué | Valor |
|---|---|
| Contrato gRPC | `contrato/proto/ms/inventory/v1/inventory.proto`, paquete `ms.inventory.v1`, servicio `InventoryService` (`GetStock`, `Hold`, `Release`, `Commit`); `go_package` `ms.dev/inventory/gen/ms/inventory/v1;inventoryv1`, `java_package` `dev.ms.inventory.v1` |
| `buf` | `bufbuild/buf:1.73.0` en Docker (`lab.py buf lint\|generate\|breaking`); lint `STANDARD`, breaking `FILE` contra `estados/<último>/contrato/proto`; plugins remotos `buf.build/protocolbuffers/go:v1.36.12` y `buf.build/grpc/go:v1.6.2` |
| gRPC en `inventory` | `:28093`; `google.golang.org/grpc` `v1.84.0`, `google.golang.org/protobuf` `v1.36.12`; sin stock → `FAILED_PRECONDITION` con `PreconditionFailure` (SKU) y `ErrorInfo` (`reason` `OUT_OF_STOCK`, `metadata` SKU → stock en mano); `--detach-deadline` (provocación) |
| `orders` | Spring Boot `4.1.1`, `:28082`, base `ms_orders` (sin FK a `users` ni `products`; `orders.customer_email` como foto); identidad desde `x-jwt-payload`; catálogo por `GET /api/v1/products` del monolito con *token relay*; `lab.py orders [--deadline MS] [--no-payment-key]` |
| Canal gRPC de `orders` | `spring.grpc.client.channel.inventory.target=static://localhost:28193`; deadline `ms.inventory.deadline-ms=800` por llamada |
| Toxiproxy | proxy `inventory-grpc` en `28193` → `host.docker.internal:28093` |
| Envoy | clúster `orders` (`V4_ONLY`); rutas `prefix /api/v1/orders` y `/api/v1/notifications` antes de la general |
| Códigos de error nuevos | `CATALOG_UNAVAILABLE` (`503`, en `orders`) |
| Herramientas | `tools/bench/` (Python 3.14, `grpcio==1.84.0`, `grpcio-tools==1.84.0`, `httpx==0.28.1`; `lab.py bench --n N`); `lab.py lock-stock SKU --seconds N` |
| Estados congelados | + `laboratorio/estados/04/` |

### 14.5 Fijado por `06/05` (T16, 2026-09-29)

| Qué | Valor |
|---|---|
| `orders` | Actuator: liveness `livenessState`, readiness `readinessState,db` (nunca dependencias); indicador `payments` fuera de la readiness; bulkhead de semáforo hacia `payments` `ms.payments.bulkhead.max-concurrent=4`, sin cola; orden Bulkhead → Retry → CircuitBreaker; no se reintenta un `503` con `PSP_UNAVAILABLE`; `lab.py orders --threads --bulkhead --breaker-min-calls --readiness-includes-payments` |
| `inventory` | interceptor gRPC con `golang.org/x/time` `v0.16.0`: `-rps`, `-burst` (20), `-max-inflight`; exceso → `RESOURCE_EXHAUSTED` sin tocar la base |
| `payments` | `purgatory==3.0.1` hacia el PSP: 3 fallos seguidos, abierto 10 s (`PAYMENTS_PSP_BREAKER_THRESHOLD`, `PAYMENTS_PSP_BREAKER_TTL_S`); abierto → `503 PSP_UNAVAILABLE` y se borra la intención |
| Envoy | ruta de `orders` con `retry_policy { retry_on: "connect-failure,refused-stream", num_retries: 1 }` (`lab.py envoy-retries 5xx\|safe`); chequeo activo `/actuator/health/readiness` cada 2 s, `no_traffic_interval: 2s`, `healthy_panic_threshold: 0`; access log con `attempts=%UPSTREAM_REQUEST_ATTEMPT_COUNT%` |
| Herramientas | `lab.py bench --flood N --concurrency C` (solo `Hold`); `lab.py storm --probe RUTA` |
| Códigos de error nuevos | `PSP_UNAVAILABLE` (`503`, en `payments`) |
| Estados congelados | + `laboratorio/estados/05/` |

### 14.6 Fijado por `06/06` (T17, 2026-09-29)

| Qué | Valor |
|---|---|
| Broker | `ms-kafka`, `apache/kafka:4.3.1` en modo KRaft, un nodo, host `localhost:29092` |
| Topics | `orders.events` (3 particiones, clave `orderId`) y `orders.events.dlq` (1 partición, encabezados `error` y `consumer`) |
| Grupos | `inventory` y `payments`, commit manual después del efecto, `auto.offset.reset` al principio |
| Evento | JSON con `eventId`, `type` (`OrderPlaced`, `OrderPaid`, `OrderCancelled`), `version: 1`, `occurredAt`, `orderId`, `customerId`, `total {amount, currency}`, `lines [{sku, quantity}]` |
| `orders` | tabla `outbox_events` (`published_at` nulo = pendiente); `OutboxPublisher` con `FOR UPDATE SKIP LOCKED` cada `ms.events.poll-ms=200`; `ms.events.mode=outbox\|direct`, `ms.events.chaos=none\|crash-before-publish`, `ms.events.topic=orders.events`; productor `acks=all` |
| `inventory` | `franz-go` `v1.22.1`; inbox `processed_messages (consumer, event_id)`; proyección `sales` y `GET /sales`; flags `-kafka`, `-inbox` (true), `-chaos none\|crash-after-effect` |
| `payments` | `aiokafka==0.14.0`, consumidor como tarea del proceso (`PAYMENTS_KAFKA`); `OrderCancelled` anula pagos `PENDING` → `VOIDED`; 3 intentos antes de la DLQ |
| `lab.py` | `kafka topics\|groups\|tail\|poison`; `seed --kafka` (solo con consumidores parados; `seed` a secas no toca Kafka); `inventory --no-inbox --chaos`; `orders --events-mode --events-chaos` |
| Estados congelados | + `laboratorio/estados/06/` |

### 14.7 Fijado por `06/07` (T18, 2026-09-29)

| Qué | Valor |
|---|---|
| Contenedores | `ms-otel-collector` (`otel/opentelemetry-collector-contrib:0.161.0`; OTLP/gRPC `24317`, OTLP/HTTP `24318`) · `ms-jaeger` (`jaegertracing/jaeger:2.21.0`, en memoria; interfaz y API `26686`) |
| Collector | `contrato/otel/collector.yaml`: receptor `otlp`, procesadores `tail_sampling` (decision_wait 5 s; se guarda si hay un span de `envoy` o uno de productor/consumidor) y `batch`, exportador `otlp_grpc/jaeger` |
| Envoy | `tracing` con `envoy.tracers.opentelemetry` hacia el clúster `otel_collector` (`ms-otel-collector:4317`, HTTP/2), `service_name: envoy`, muestreo 100 %; `trace=%TRACE_ID%` en el access log |
| Java | agente `opentelemetry-javaagent` `2.31.1` en `laboratorio/tools/otel/` (descargado por `mvn dependency:copy`, no versionado); `OTEL_SERVICE_NAME` `orders` / `monolith`, OTLP/HTTP a `localhost:24318`, métricas y logs del agente apagados; `opentelemetry-api` del BOM; `logging.pattern.correlation` con `trace_id` y `span_id` |
| `orders` | columna `outbox_events.trace_context`; `ms.events.propagate-trace` (`true`); `lab.py orders --no-trace-outbox` |
| `inventory` | `go.opentelemetry.io/otel` `v1.46.0`, `otelgrpc`/`otelhttp` `v0.71.0`; paquete `internal/telemetry`; flags `-otlp` y `-trace-kafka` (true); `lab.py inventory --no-trace-kafka` |
| `payments` | `opentelemetry-sdk`/`-exporter-otlp-proto-grpc` `1.45.0`, instrumentors `0.66b0`; `app/telemetry.py`; `PAYMENTS_OTLP`, `PAYMENTS_TRACE_KAFKA` (`1`); `lab.py payments --no-trace-kafka` |
| Spans de consumidor | nombre `orders.events process`; atributos `messaging.*` y `ms.event.type`, `ms.event.verdict` |
| `lab.py` | `buy [--sku --qty --then pay\|cancel\|nothing]` (manda su `traceparent`); `trace [ID] [--service --operation --list --wait]` sobre la API v3 de Jaeger |
| Estados congelados | + `laboratorio/estados/07/` (sin el `.jar` del agente) |

### 14.8 Fijado por `06/08` (T19, 2026-09-29)

| Qué | Valor |
|---|---|
| Contrato `v2` | `POST /api/v2/orders` → `202`, `Location`, estado `PENDING`; `GET /api/v2/orders/{orderId}`; claves de idempotencia con espacio propio (`v2:` delante); `openapi.yaml` `2.0.0`, operaciones con `x-suite: v2` y `x-taller: "08"` |
| `v1` obsoleto | en `/api/v1/orders*`: `Deprecation: @1790640000` (2026-09-29), `Sunset: Wed, 31 Mar 2027 00:00:00 GMT`, `Link: </api/v2/orders>; rel="successor-version"`; `deprecated: true` en el `openapi.yaml`; `ms.v1.deprecated-at`, `ms.v1.sunset-at` |
| Topics | `orders.placed`, `inventory.reservations`, `payments.results` (3 particiones, clave `orderId`), cada uno con `.dlq` (1); el consumidor aparta a `<topic>.dlq` |
| Hechos | `OrderPlaced` (`orders`) · `InventoryReserved` (con `lines` y el `total` copiado), `InventoryReservationFailed` (`shortages`), `InventoryReleased` (`released`) · `PaymentAuthorized`, `PaymentRejected` (`payment {operationId, status, reference, amount}`); los de `inventory` y `payments` llevan `causationId` |
| Grupos | `inventory` (`orders.events`, `orders.placed`, `payments.results`), `payments` (`orders.events`, `inventory.reservations`), `orders` (`inventory.reservations`, `payments.results`) |
| Outbox e inbox | `outbox_events` (con `topic`) y `processed_messages` en las tres bases; publicadores cada 200 ms en Java, Go (`internal/outbox`) y Python (`app/outbox.py`) |
| `payments` | clave hacia el PSP `saga-<orderId>`; sin respuesta a tiempo → pago `PENDING` y ningún hecho; `cramjam==2.13.0` |
| `orders` | `ms.saga.placed-topic=orders.placed`, `ms.saga.retry-on-release` (`false`); `SagaListener` con `ack-mode: record`; `KafkaErrorConfig`: 3 intentos con 200 ms y `<topic>.dlq`; el pago se registra por `operationId` |
| `inventory` | retención idempotente solo si hay filas no liberadas (`status <> 'RELEASED'`); `HoldTx`, `ReleaseTx`, `CommitTx`, `SagaStep` |
| Suite | `contrato/hurl/v2/01-happy-path` … `04-v1-deprecated`, claves con prefijo `suite-v2-`, espera con `retry: 50`, `retry-interval: 200ms` |
| `lab.py` | `buy --v2 [--wait]`; `saga-status ORDER_ID`; `orders --saga-retry-on-release`; `trace --max-lines` |
| Estados congelados | + `laboratorio/estados/08/` |

### 14.9 Fijado por `06/09` (T20, 2026-09-29)

| Qué | Valor |
|---|---|
| Modo de la saga `v2` | `ms.saga.mode=orchestration` por defecto; `choreography` = la de `06/08`, que sigue en el código; `lab.py orders --saga` |
| Tablas del orquestador | `order_sagas` (`step`, `attempts`, `next_attempt_at`, `step_started_at`, `deadline_at`, `last_error`) y `order_saga_log`, en `ms_orders` |
| Pasos | `RESERVE_INVENTORY` · `AUTHORIZE_PAYMENT` · `COMMIT_INVENTORY` · `RELEASE_INVENTORY` · `DONE` · `ESCALATED`; comandos `ReserveInventory` (gRPC `Hold`), `AuthorizePayment` (HTTP con clave `saga-<orderId>`), `ReleaseInventory` (gRPC `Release`) |
| Tiempos | sondeo `ms.saga.poll-ms=200`; *lease* 30 s; plazo por paso `ms.saga.step-deadline-seconds=20` (`0` = sin plazo); espera 250 ms × 2ⁿ con tope de 5 s; regla: plazo + *lease* < caducidad de la reserva |
| `inventory` | `-hold-ttl` (10 min por defecto; `0` = nunca), barrido cada `ttl/4` con tope de 5 s; `Commit` devuelve las líneas vendidas (0 si caducó) |
| Cierre | parches en `laboratorio/tools/cierre-09/` (`1-antifraude-orquestacion`, `1-antifraude-coreografia`, `2-fidelidad`); *stubs* `fraud` (HTTP `:28086` `POST /checks`, o Kafka → `fraud.results`) y `loyalty`; regla antifraude: más de 5 unidades en una línea |
| `lab.py` | `orders --saga --saga-deadline`; `inventory --hold-ttl`; `saga-status` con la fila y el registro del orquestador; con los parches, `fraud --mode` y `loyalty --saga` |
| Estados congelados | + `laboratorio/estados/09/` |

### 14.10 Fijado por `06/10` (T21, 2026-09-29)

| Qué | Valor |
|---|---|
| Pactos | en `contrato/pacts/`: `orders-payments.json` (V4, lo escribe Pact JVM) e `inventory-orders.json` (V3 de mensajes, escrito a mano en Go); nombres de participante `orders`, `payments`, `inventory` |
| Interacciones | `orders` → `payments`: "a payment below the PSP limit" (`given` "the PSP authorizes payments", `201`, `status` por patrón y `reference` por tipo) y "a repeated payment while the first attempt is still running" (`given` "a payment with key pact-in-progress-0001 is in progress", solo `409`); `inventory` ← `orders`: "an OrderPaid event" (`given` "an order has been paid"; `eventId`, `type`, `orderId`, `lines[*].sku`, `lines[*].quantity`) |
| Java | `spring-boot-starter-test` (BOM); `au.com.dius.pact.consumer:junit5` y `…provider:junit5` `4.7.5`; `pact.rootDir` en `maven-surefire-plugin`; `OrderEvents.payload(...)` estático |
| Go | `testcontainers-go` y `modules/postgres` `v0.44.0`, imagen `postgres:17.11-alpine`; sin `pact-go` (exige biblioteca nativa en el sistema) |
| Python | grupo `dev` de `payments` con `pact-python==3.4.1`; `payments/tests/verify_pacts.py` contra `payments` en marcha |
| `lab.py` | `test [all\|inventory\|orders\|payments]`, en ese orden: consumidores antes que proveedores |
| Estados congelados | + `laboratorio/estados/10/` |

### 14.11 Fijado por `06/11` (T22, 2026-09-29)

| Qué | Valor |
|---|---|
| Vista | `GET /api/v2/orders/overview?source=composition\|projection` (por defecto `projection`), `Server-Timing` con la duración; campos `source`, `items[] {orderId, status, paymentStatus, total}`, `paidOrders`, `paidAmount`, `degraded` |
| Composición | `orders` + `payments` `GET /payments?orderId=…&orderId=…` (una llamada), `ms.overview.composition-timeout-ms=800`; si falla, pagos `UNKNOWN` y `degraded: true` |
| Read model | tablas `order_overview` y `customer_overview` en `ms_orders`; `OverviewProjector`, grupo `orders-overview` sobre `orders.events`, inbox con consumidor `orders-overview`; `ms.overview.inbox` (`true`); estados del read model `PLACED`, `PAID`, `CANCELLED` |
| Hechos nuevos | el orquestador publica `OrderPlaced` (alta `v2`) y `OrderCancelled` (al cancelar) en `orders.events` |
| SSE | `GET /api/v2/orders/{orderId}/events` (`text/event-stream`): `snapshot` sin `id`, `step` con `id` = `order_saga_log.id`, `end` y cierre; `Last-Event-ID` reanuda; `: ping` cada ≈ 15 s; sondeo cada 200 ms |
| Envoy | ruta `^/api/v2/orders/[^/]+/events$` antes de la de `/api/v2/orders`, `timeout: 0s`, `idle_timeout: 60s` |
| Suite | + `contrato/hurl/v2/05-overview-and-follow.hurl` (clave `suite-v2-overview-0001`) |
| `lab.py` | `overview [--items]`; `follow ORDER_ID [--reconnects]`; `overview-replay [--truncate]` (con `orders` parado); `orders --overview-no-inbox` |
| Estados congelados | + `laboratorio/estados/11/` |
