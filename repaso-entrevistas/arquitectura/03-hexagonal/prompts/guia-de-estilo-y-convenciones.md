# ✍️ Guía de estilo, tono y convenciones

## Arquitectura hexagonal — repaso para entrevistas de Backend Senior, Tech Lead y Arquitecto

Esta guía es la fuente de verdad editorial de `03-hexagonal/`. Manda sobre los
cinco bloques teóricos, sobre el bloque `06-talleres/` y sobre cualquier documento que se añada después. El objetivo no es que el lector
pueda dibujar seis hexágonos: es que pueda **proteger el dominio de las dependencias, nombrar cada
frontera y defender el coste de mantenerla**.

> **Vigencia:** 2026-09-28.

**Salto rápido:** [1](#1--principio-rector) · [2](#2--tono) · [3](#3-️-idioma-y-forma) · [4](#4--pedagogía) · [5](#5--eje-de-plataformas) · [6](#6--plantilla-del-capítulo-nn-temamd) · [7](#7-️-tipos-de-documento) · [8](#8--preguntas-y-dificultad) · [9](#9--referencias-y-coherencia) · [10](#10--bloque-06--talleres) · [11](#11--nombres-fijos-del-laboratorio) · [12](#12--checklist-de-cierre)

---

## 1. 🧭 Principio rector

**Todo párrafo debe ayudar a distinguir política de detalle, ubicar una dependencia o defender por
qué una frontera compensa.** Si no hace una de esas tres cosas, sobra.

```text
Un tutorial de hexagonal  → te enseña las capas y el dibujo.
Un libro de framework     → te enseña las anotaciones.
Este repaso               → te enseña qué no debe conocer el núcleo,
                            dónde vive cada decisión y qué cuesta sostenerla.
```

La regla se formula sin misticismo: las dependencias de código apuntan hacia la política de negocio;
el dominio no importa HTTP, ORM, broker, framework ni detalles de despliegue. Los puertos expresan
lo que el núcleo necesita o ofrece; los adaptadores traducen el mundo exterior. No es obligatorio
tener interfaces por cada clase, ni una carpeta llamada `hexagonal` hace hexagonal a un proyecto.

Cada capítulo debe responder también: **¿qué simplifica esta separación y qué ceremonia introduce?**
Las cinco monedas son: complejidad cognitiva, código de traducción, pruebas, evolución y operación.
No se dice “añade complejidad” sin señalar quién la paga y dónde aparece.

### 1.1 Qué queda fuera

- No es una introducción a programación orientada a objetos, HTTP, SQL ni mensajería. Se usan como
  detalles que entran por un adaptador.
- No es DDD completo. Agregados, contextos acotados y event sourcing solo se explican hasta donde
  ayudan a diseñar el núcleo y sus límites.
- No es un curso de Spring, NestJS, Go, FastAPI o Laravel. En los capítulos las plataformas son
  evidencia comparativa, no el centro del temario. Los talleres del bloque `06` (§10) sí
  implementan el caso de estudio, pero enseñan la frontera, no el framework.
- No promete que hexagonal arregle fronteras de negocio malas, latencia de red ni una base de datos
  compartida. Puede hacer esos problemas más visibles; no los elimina.

---

## 2. 🎤 Tono

- **Español latinoamericano neutro y tuteo.** Cercano, preciso y sin tono de manual corporativo.
- **Honesto con la ceremonia.** Un CRUD interno de tres pantallas puede no justificar puertos de
  salida, mappers y dobles propios. Se dice con claridad.
- **Sin absolutos falsos.** “El dominio nunca conoce infraestructura” es una regla de diseño; no se
  convierte en “nunca puede existir una dependencia compartida”. Se declaran las excepciones y su
  fecha de revisión.
- **Sin guerras de arquitectura.** Clean, Onion, Layered y Hexagonal se comparan por dirección de
  dependencias y coste, no por logotipos.
- **Sin guerra de lenguajes.** Java recibe detalle porque es el perfil base, no porque sea
  superior. A cada plataforma se le reconoce lo que resuelve y lo que deja explícito.
- **Un solo desdramatizador seco por documento, como máximo.** Esto es material de entrevista, no
  una conversación de chat.

---

## 3. 🗣️ Idioma y forma

- Los términos del oficio que son nombres propios se conservan en inglés: *port*, *adapter*,
  *composition root*, *dependency rule*, *repository*, *unit of work*, *anti-corruption layer*.
  La primera aparición incluye traducción breve entre paréntesis si ayuda; después no se fuerza.
- **Código en inglés, comentarios del código en español.** Todo lo ejecutable o versionado va en
  inglés: identificadores, paquetes, rutas HTTP, nombres de tabla y columna, claves JSON, variables
  de entorno, nombres de contenedor, mensajes de excepción y datos semilla. Los comentarios dentro
  del código, incluidos los de un `docker-compose.yml` o un `openapi.yaml`, van en español con
  tildes. La API es `/orders`, nunca `/pedidos`.
- **Un solo nombre canónico por concepto, y es el del código.** La prosa habla en español del caso
  de uso, pero cuando nombra el identificador usa el del código, en backticks. El mapa fijo es:

  | En la prosa | Identificador canónico | Aparece como |
  |---|---|---|
  | crear pedido | `CreateOrder` | caso de uso, `CreateOrderCommand`, `OrderCreated` |
  | autorizar pago | `AuthorizePayment` | caso de uso; puerto `PaymentGateway`; `PaymentResult` |
  | reserva de inventario | `InventoryReservation` | agregado; `ReserveInventory`, `InsufficientInventory` |
  | cancelar pedido | `CancelOrder` | caso de uso; `OrderCancelled` |
  | notificación | `Notifier` | puerto de salida; `PendingPublications` como outbox |
  | pedido | `Order` | agregado; `Orders` como puerto de persistencia; `OrderRecord` como registro ORM |
  | cliente | `Customer`, `customerId` | identidad de negocio, nunca `clienteId` |
  | actor | `Actor` | contexto de aplicación, nunca el JWT |

  No se escribe `CrearPedido` ni `PedidoRepository` en ningún documento: si el código dice
  `CreateOrder`, la prosa dice "crear pedido" o `CreateOrder`.
- Markdown, nunca HTML. Código pequeño, completo y con nombres del dominio de ejemplo.
- La prioridad visual es: diagrama ASCII → tabla de decisión → lista → prosa. La prosa explica el
  porqué; una tabla no sustituye el razonamiento.
- Diagramas en bloques `text`; simples y direccionales. Por ejemplo:

  ```text
  HTTP ─► adaptador de entrada ─► caso de uso ─► puerto de salida ─► PostgreSQL
                                       │
                                    dominio
  ```

- Tablas solo comparan dimensiones. Tres o cuatro columnas es la norma. No se usan para narrar.
- Un emoji funcional en encabezados `##`; ninguno en `###`. Los encabezados siguen una jerarquía
  real, no son decoración.

---

## 4. 🧱 Pedagogía

Se explica “como para un bebé” en el único sentido útil: sin saltos de razonamiento y sin ambigüedad,
no con menos profundidad. El andamio fijo es:

1. El síntoma concreto: qué cambio duele o qué prueba no se puede hacer.
2. La frontera: qué decisión es política y cuál es detalle.
3. El mecanismo: puerto, caso de uso, adaptador, mapper o composición.
4. El precio: qué abstracción, prueba o traducción se acaba de introducir.
5. El veredicto: cuándo usarlo, cuándo simplificarlo y qué vigilar.

Cada patrón se muestra con un flujo completo, no con interfaces huérfanas. El código debe atravesar
un caso de uso y mostrar dónde se construyen las dependencias. Los ejemplos usan de forma constante
un sistema de pedidos y pagos: `CreateOrder`, `AuthorizePayment`, `InventoryReservation` y
notificación, con los nombres canónicos de §3. Si el ejemplo no cabe ahí, se explica por qué. Es el
mismo sistema que se implementa en los talleres del bloque `06` (§10): los capítulos lo describen,
los talleres lo ejecutan.

### 4.1 Errores que se desmontan siempre

- “Hexagonal son tres carpetas.”
- “Todo necesita una interfaz.”
- “El repositorio es el dominio.”
- “El ORM vive en infraestructura, así que puede devolver entidades de dominio sin más.”
- “Una prueba unitaria prueba la arquitectura.”
- “Dependency injection equivale a arquitectura hexagonal.”

---

## 5. 🧰 Eje de plataformas

El orden fijo de comparación es **Java · Node/TS · Go · Python**. La tabla obligatoria de plataformas
tiene siempre las cuatro filas y estas columnas:

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|

No se nombran librerías de memoria: antes de publicar una se comprueba existencia, mantenimiento,
nombre y documentación primaria. La baseline se fija una sola vez en `05/01` y luego se enlaza.

Los talleres de sabor (`06/03`–`06/07`) amplían el eje a **cinco sabores**: Java · Node/TS · Go ·
Python · PHP. PHP/Laravel no entra en los capítulos, que se cerraron con cuatro filas; entra en el
taller porque aporta el contraste de un framework con *active record* (Eloquent) donde el reto es
que el modelo de dominio no sea la entidad del ORM. La tabla de plataformas de un taller de sabor
tiene cinco filas y la misma cabecera. Los talleres de integración (`06/08`–`06/11`) son **solo
Java**: el patrón no cambia por lenguaje, el perfil base es Java y cinco toolchains de JMS,
Kafka, gRPC y batch no enseñarían nada que no enseñe una.

El código comparativo solo entra donde aclara un coste real. Un bloque por lenguaje para demostrar
que todos pueden definir una interfaz no enseña nada; la composición, el manejo de contexto, las
transacciones y la traducción de errores sí suelen enseñar algo.

---

## 6. 📄 Plantilla del capítulo `NN-tema.md`

Cada capítulo, salvo los que el contrato declare conceptuales, sigue este orden:

```text
problema → modelo mental → diseño y flujo → implementación mínima
→ 🧰 cuatro plataformas → ⚖️ comparación o decisión → ⚠️ errores frecuentes
→ veredicto → referencias → 🧠 24–26 preguntas sin respuesta
```

- El primer párrafo dice qué decisión se aprende a tomar.
- La sección de plataformas declara explícitamente si no aplica y por qué.
- `## ⚠️ Errores frecuentes` contiene sobregeneralizaciones reales de entrevista, no consejos vagos.
- `## 🧠 Preguntas` no contiene respuestas ni pistas. Cada pregunta lleva dificultad `🟢`, `🟡` o
  `🟠`, de menor a mayor complejidad, y se copia literal al solucionario.
- Cada capítulo termina con referencias directas y verificadas, no con URLs inventadas ni enlaces a
  páginas índice cuando existe una fuente específica.

---

## 7. 🗂️ Tipos de documento

### Capítulo

Enseña una decisión concreta y contiene 24–26 preguntas. Tiene introducción, veredicto, referencias
y navegación al siguiente documento cuando exista.

### Simulación

No repite capítulos. Incluye 30–45 preguntas transversales `S#`, un bloque “las que descolocan” y
4–6 escenarios. Cada escenario declara qué fuerza: una frontera, un trade-off y una respuesta que
un candidato senior debe priorizar.

### Taller

Documento `NN-tema.md` dentro de `06-talleres/`, con código versionado en `06-talleres/laboratorio/`.
No forma parte del recorrido teórico: cada taller se puede hacer solo, en una tarde, y el lector
elige cuáles hace. Su forma se fija en §10. Lleva `## 🧠 Preguntas` (10–15) y `## 🧪 Ejercicios`
graduados 🟢🟡🟠🔴, más 🔥 y 💀 fuera del conteo; las respuestas viven en `06-talleres/12-respuestas.md`
con el enunciado literal.

### Solucionario

Cada respuesta conserva el enunciado literal y usa las tres capas:

```text
⏱️ 30 segundos  → respuesta inicial, precisa y defendible
🗣️ 2 minutos    → contexto, alternativa y coste
🔬 El detalle    → matiz para estudiar, no para recitar
```

Los solucionarios se actualizan en la misma tanda que las preguntas. No hay respuestas inline en los
capítulos.

Forma fija de los seis solucionarios: un `##` por documento de origen (`## 03 · Puertos de entrada`,
`## 08 · Simulación de entrevista`), separados por `---`; cada enunciado como `###` con **la
numeración de su documento** (1–24 en un capítulo, `S1`–`S30` en la simulación, nunca corrida por
bloque); las tres capas en párrafos separados por una línea en blanco; salto rápido al principio y
navegación al final. En las simulaciones, las preguntas `S#` van como elementos de lista: una línea
`S1.` suelta se funde en un solo párrafo con la siguiente.

---

## 8. 🧠 Preguntas y dificultad

- `🟢`: definición precisa, reconocimiento de una frontera o un flujo sencillo.
- `🟡`: comparación, diagnóstico o decisión con un trade-off explícito.
- `🟠`: escenario incompleto, migración, desacuerdo entre equipos o excepción que obliga a priorizar.

La distribución varía entre capítulos para no producir plantillas mecánicas. Cada capítulo incluye al
menos dos preguntas de plataforma cuando tenga sección de plataformas; los puramente conceptuales
declaran su excepción.

---

## 9. 🔗 Referencias y coherencia

- Toda URL externa se comprueba antes de escribirla y debe respaldar exactamente la afirmación.
- Los enlaces internos solo se crean hacia archivos existentes. Una dependencia futura se menciona
  en prosa, y se convierte en enlace cuando su destino existe.
- Un concepto tiene una definición dueña. Los capítulos vecinos lo enlazan o lo usan, no lo
  reescriben.
- Se revisan nombres: `useCase de uso`, `puerto de entrada`, `puerto de salida`, `adaptador de entrada`,
  `adaptador de salida`, `núcleo`, `dominio` e `infraestructura` no se alternan caprichosamente.

---

## 10. 🧪 Bloque 06 · Talleres

El bloque `06-talleres/` implementa el sistema de ejemplo de los capítulos. Enseña a **palpar**
dónde queda cada frontera cuando el framework empuja en contra; no enseña el framework. **Todo el
bloque es opcional** y lo declara su README; cada taller lo vuelve a declarar en su primer párrafo.

### 10.1 Inventario y dependencias

```text
06-talleres/
├── README.md                             mapa, dependencias y "todo aquí es opcional"
├── 01-contrato-openapi-y-suite.md        contrato OpenAPI 3.1, Swagger UI, suite hurl, compose, semilla
├── 02-frontend-minimo-react.md           cliente HTTP como adaptador; opcional incluso dentro del bloque
├── 03-caso-java-spring-boot.md           ┐
├── 04-caso-typescript-nestjs.md          │
├── 05-caso-go.md                         ├ talleres de sabor: uno o varios, independientes entre sí
├── 06-caso-python-fastapi.md             │
├── 07-caso-php-laravel.md                ┘
├── 08-colas-jms-activemq-artemis.md      ┐
├── 09-topicos-kafka.md                   ├ talleres de integración: solo Java; dependen de 01 y 03
├── 10-grpc.md                            │
├── 11-lotes-spring-batch.md              ┘
├── 12-respuestas.md                      solucionario único del bloque
└── laboratorio/
    ├── contrato/    openapi.yaml · asyncapi.yaml · proto/ · hurl/ · docker-compose.yml · seed/
    ├── scripts/     lab.py — Python 3, solo biblioteca estándar
    ├── frontend/
    ├── java/  nestjs/  go/  python/  php/
    └── payments-grpc/                    servidor de pagos del taller 10
```

Dependencias: `01` es prerrequisito de todo; `03` lo es de `08`–`11`. Nada más. Ningún taller
referencia el código de otro sabor, aunque sí puede contrastarlo en prosa. El mapa para el lector,
con recorridos según el perfil, es [`06-talleres/README.md`](../06-talleres/README.md).

### 10.2 El contrato manda

El alcance del caso de estudio se fija una sola vez, en `01` y en `laboratorio/contrato/openapi.yaml`.
Un sabor está **terminado** cuando la misma colección `hurl` que pasan los demás pasa contra él
cambiando solo la URL base. Eso convierte el frontend y la suite en el *driving adapter* compartido:
la prueba de que los cinco núcleos son intercambiables no es una opinión, es un comando que termina
en verde.

Los talleres de sabor no añaden endpoints. Los de integración sí añaden los suyos (`/reports/...`,
`/batches/...`) al `openapi.yaml`, etiquetados por taller, en su propia tanda; `asyncapi.yaml` nace
en `08` y `proto/` en `10`.

Las tres partes de un taller de sabor son las mismas en los cinco:

| Parte | Qué se construye | Evidencia que cierra la parte |
|---|---|---|
| 1 · Núcleo | catálogo, `CreateOrder` con reserva atómica, `AuthorizePayment` contra un `PaymentGateway` determinista, `login`/`logout` con JWT revocable | suite `v1` en verde |
| 2 · Extensión funcional | `CancelOrder`: máquina de estados, liberación de reserva, `OrderCancelled` entregado por `Notifier` vía outbox | suite `v1.1` en verde y `git diff --stat` sin cambios en adaptadores existentes |
| 3 · Cambio interno | catálogo de productos a MongoDB; pedidos, reservas, pagos y outbox siguen en PostgreSQL | la misma suite `v1.1` en verde sin tocar `domain/`, `application/` ni `inbound/` |

Los talleres de integración tienen una funcionalidad propia cada uno, asíncrona por naturaleza, y
la misma regla de evidencia: `git diff --stat -- domain application` se pega literal y muestra que
el núcleo no cambió o cambió solo por el caso de uso nuevo que el taller declara.

| Taller | Funcionalidad | Lo que se palpa |
|---|---|---|
| [`08`](../06-talleres/08-colas-jms-activemq-artemis.md) colas | `OrderRequested` llega por la cola `orders.inbound` desde otro sistema y responde por `orders.reply` con `JMSCorrelationID` | ACK tras commit, redelivery, DLQ, deduplicación por `operationId`, consumidores competidores; contrato en AsyncAPI 3 |
| [`09`](../06-talleres/09-topicos-kafka.md) tópicos | la outbox publica en `orders.events` particionado por `orderId`; consumen un worker de notificaciones y una proyección `orders_summary` | orden por clave, at-least-once, commit de offset tras el efecto, rebalance, reconstrucción desde el offset 0 |
| [`10`](../06-talleres/10-grpc.md) gRPC | `payments-grpc` sustituye al `PaymentGateway` determinista detrás del mismo puerto | `.proto` como contrato, deadlines propagados, `UNAVAILABLE` → `UnknownResult`, metadata de idempotencia, stub in-process |
| [`11`](../06-talleres/11-lotes-spring-batch.md) lotes | `stockAdjustment` desde CSV del proveedor y `dailyClose`, con Spring Batch; el jar con argumentos es la CLI | chunk = transacción pequeña, `JobRepository` = checkpoint, restart, skip policy, `JobExecutionAlreadyRunningException` = lease |

### 10.3 Plantilla del taller

```text
qué enseña este taller → prerrequisitos y versiones exactas → mapa de carpetas
→ partes en orden (dominio → puertos → casos de uso → adaptadores → composición → suite)
→ evidencia por parte → 🧰 plataformas (cinco filas en los de sabor; no aplica en los de integración)
→ teardown → 📚 referencias → 🧠 preguntas → 🧪 ejercicios
```

- El mapa de carpetas es el mismo en los cinco sabores, adaptado solo a la convención de rutas del
  ecosistema (`src/main/java/...`, `src/`, `internal/`, `app/`):

  ```text
  domain/                  Order, Product, Money, InventoryReservation, eventos, errores propios
  application/             casos de uso, puertos de entrada y de salida, Actor
  infrastructure/
  ├── inbound/http/        controllers, DTO, mappers, traducción de errores, autenticación
  ├── inbound/jms/         solo desde el taller 08
  ├── inbound/batch/       solo desde el taller 11
  ├── outbound/postgres/   Orders, InventoryReservations, PendingPublications
  ├── outbound/mongo/      Products (solo desde la parte 3)
  ├── outbound/redis/      TokenRevocationStore
  ├── outbound/payment/    PaymentGateway determinista; grpc/ desde el taller 10
  ├── outbound/kafka/      solo desde el taller 09
  └── config/              composition root, configuración tipada, arranque y cierre
  ```

- **Vibecoding declarado.** El código se genera con un asistente; el taller no lo comenta línea a
  línea. Explica las decisiones arquitectónicas —dónde está la frontera, por qué ese puerto, qué
  pagó la ceremonia, qué empujó el framework en contra— y muestra solo los recortes que las
  demuestran. Cada recorte sigue el andamio de §4.
- **Ningún comando ni flag queda sin explicar.** Después de cada bloque de comandos va el desglose
  en viñetas de lo que hace cada parte. Un bloque suelto es un error de estilo.
- **Orquestación en Python 3, solo biblioteca estándar.** `laboratorio/scripts/lab.py` es el "shell
  con esteroides" común a macOS, Linux y Windows: `up`, `down`, `seed`, `suite`, y los provocadores
  de fallo de cada taller. En el texto se invoca como `python3 laboratorio/scripts/lab.py ...` y se
  desglosa igual que un comando. No hay scripts `bash`, PowerShell ni Groovy; `hurl` sigue siendo la
  suite de contrato.
- **El problema antes que la herramienta.** Cada adaptador se introduce por el dolor que resuelve
  (§4), no por el orden de la documentación del framework.
- **Los errores se provocan a propósito.** Al menos uno por parte: un import prohibido que la regla
  de arquitectura detecta, un `db` fuera del `tx`, una entidad ORM que se cuela al controller, un
  consumidor que muere entre commit y ACK. Se muestra el fallo y después la corrección.
- **Teardown junto al recurso.** Lo que se levanta en una sección se apaga en esa sección; el
  compose común se apaga al final de `01` y se vuelve a levantar al empezar cada taller.
- **Versiones exactas, verificadas el día de escritura.** Nunca `latest`, `^`, `~` ni rangos donde
  el taller fija un valor. Se anota la fecha de verificación.

### 10.4 Qué no hace un taller

- No enseña el framework: no explica qué es un bean, un módulo Nest, un `Depends`, un service
  provider, un `JmsListener` o un `ItemWriter` más allá de lo que hace falta para ubicar la
  frontera.
- No reabre decisiones de los capítulos: si hay que matizar una, se enlaza el capítulo y se dice qué
  cambia en este ecosistema.
- No añade endpoints, entidades ni reglas fuera de lo que su ficha del prompt base declara.
- No compara rendimiento entre sabores ni entre brokers. Compara mecanismo, ceremonia y dónde
  empuja cada herramienta.

---

## 11. 🔒 Nombres fijos del laboratorio

No se inventan valores nuevos. Lo que no esté aquí lo fija el taller que lo necesite, en su tanda, y
se añade a esta sección en la misma edición. Los valores de brokers, gRPC y batch los fijan `08`–`11`.

| Qué | Valor |
|---|---|
| Prefijo de todo recurso | `hex-` |
| Proyecto compose | `hex-lab` |
| Contenedores | `hex-postgres` · `hex-mongo` · `hex-redis` · `hex-swagger` · `hex-mock` |
| Puertos en el host | PostgreSQL `15432` · MongoDB `17017` · Redis `16379` (no chocan con el laboratorio de bases de datos, que usa los estándar) · Swagger UI `18080` · mock del contrato `14010` |
| Base PostgreSQL | `hex_orders`, usuario `hex`, contraseña `hex-lab-pass` (solo desarrollo) |
| Base MongoDB | `hex_catalog`, colección `products` |
| Puertos de los backends | Java `8081` · NestJS `8082` · Go `8083` · FastAPI `8084` · Laravel `8085`; cada sabor tiene su orden en `lab.py` (`java`, `nestjs`, `go`, `python`, `php`) con `--catalog postgres\|mongo` y `--test` |
| Frontend | `5173`; todo backend permite CORS desde `http://localhost:5173` con `Authorization`, `Content-Type` e `Idempotency-Key`, y expone `Location` e `Idempotent-Replay` |
| Prefijo de la API | `/api/v1` |
| JWT | HS256, secreto `hex-lab-dev-secret-change-me-0123456789` (39 bytes: HS256 exige al menos 32), claims `sub`, `email`, `role`, `jti`, `exp`; acceso 15 min; revocación por `jti` en Redis (`hex:revoked:<jti>`) con TTL igual al tiempo restante |
| Usuarios semilla | `ana@hex.local` / `ana-12345` con rol `customer` · `ops@hex.local` / `ops-12345` con rol `operator` |
| Productos semilla | `SKU-001` Mechanical keyboard 49.90 (stock 20) · `SKU-002` USB-C cable 9.90 (100) · `SKU-003` 27" monitor 222.00 (5) · `SKU-004` Webcam 59.00 (**0**) · `SKU-005` Workstation 1499.00 (3) |
| Moneda | `USD`, importes como decimal con dos cifras, nunca `double` |
| Regla del `PaymentGateway` determinista | total `> 1000.00` → `Rejected`; total `== 666.00` → `UnknownResult`; resto → `Authorized` |
| Errores HTTP | `application/problem+json` (RFC 9457) con `type`, `title`, `status`, `detail`, `instance` y un `code` estable propio |
| Broker JMS (taller 08) | `hex-artemis` (`apache/artemis:2.57.0-alpine`, perfil compose `jms`: `lab.py up --jms`); usuario `hex` / `hex-lab-pass`; puertos en el host `61616` (Core/JMS), `61613` (STOMP, lo habla `lab.py`), `8161` (consola); colas anycast `orders.inbound` (peticiones), `orders.reply` (respuestas, `JMSCorrelationID`), `DLQ` (la del broker, tras 10 entregas fallidas); contrato en `contrato/asyncapi.yaml`; cabecera de laboratorio `hexChaos=crash-after-commit`; segunda instancia Java con `lab.py java --port 8091` |
| Kafka (taller 09) | `hex-kafka` (`apache/kafka:4.3.1`, KRaft un nodo, perfil compose `kafka`: `lab.py up --kafka`); puerto en el host `19092` (listener `HOST`), `9092` dentro del contenedor; tópico `orders.events`, 3 particiones, clave `orderId`, réplica 1; grupos `hex-notifications` y `hex-orders-summary`; tablas `orders_summary` y `applied_events` (esquema común); `GET /api/v1/reports/orders-summary` (tag `reports`, `x-suite: taller-09`, `hurl/taller-09/`); `lab.py java --events kafka [--unkeyed] [--chaos crash-before-offset-commit]`, `seed --kafka`, `kafka topic|groups|tail|rebuild` |
| gRPC (taller 10) | `payments-grpc` (proyecto `laboratorio/payments-grpc/`, `lab.py payments-grpc`): gRPC en `19090`, fallos por HTTP en `19091` (`POST /faults`, `lab.py grpc fault none|latency|unavailable`); contrato `contrato/proto/payments.proto` (`hex.payments.v1.PaymentService.Authorize`, `Money` como texto); metadata `idempotency-key`; `hex.payment.provider=deterministic|grpc` (`lab.py java --payment grpc`), `hex.payment.deadline-ms=2000`; canal `spring.grpc.client.channel.payments.target=static://localhost:19090`; `UNAVAILABLE`/`DEADLINE_EXCEEDED` → `PENDING` |
| Lotes (taller 11) | jobs `stockAdjustment` (parámetro `file`, CSV `sku,delta,reason` en `laboratorio/batch/in/stock-YYYY-MM-DD.csv`, cuarentena `<archivo>.quarantine.csv`) y `dailyClose` (parámetro `date`, informe en `laboratorio/batch/out/daily-close-YYYY-MM-DD.csv`); chunk `100`, `skip-limit` `10`, `hex.batch.chaos=crash-on-marker` (línea con `reason=CRASH`); actor del lote `batch@hex.local` (`00000000-0000-4000-8000-00000000ba7c`, operator); tablas `BATCH_*` de Spring Batch 6.0.5 en `hex_orders` (`contrato/seed/schema-batch.sql`, las aplica `seed`); `GET /api/v1/batches/{executionId}` (tag `batches`, `x-suite: taller-11`); `lab.py batch sample|run|status|recover` |

`SKU-004` sin stock existe para provocar `InsufficientInventory`; `SKU-005` existe para provocar el
rechazo del pago; `SKU-003` a `222.00` existe para que tres unidades sumen `666.00`, el importe que
ejercita el resultado incierto sin un tercero. La suite da de alta `SKU-006` y `SKU-101`; ningún
backend los trae de semilla. Usuarios con UUID fijos `11111111-1111-4111-8111-111111111111` (ana)
y `22222222-2222-4222-8222-222222222222` (ops). Imágenes: `postgres:17.11-alpine`, `mongo:8.0.20`,
`redis:7.4.11-alpine`, `swaggerapi/swagger-ui:v5.33.0`, `stoplight/prism:5.15.10`,
`apache/artemis:2.57.0-alpine`, `apache/kafka:4.3.1`; `hurl` 8.0.1.

---

## 12. ✅ Checklist de cierre

- [ ] Responde una decisión de diseño, no solo define vocabulario.
- [ ] Distingue política de detalle y nombra la dirección de dependencias.
- [ ] Muestra el coste concreto de la separación propuesta.
- [ ] Incluye flujo, veredicto, errores frecuentes y referencias verificadas.
- [ ] La tabla de plataformas tiene cuatro filas o declara por qué no aplica.
- [ ] Las 24–26 preguntas no tienen respuesta inline y están copiadas al solucionario.
- [ ] Los enlaces internos existen; los externos son directos y comprobados.
- [ ] Usa el sistema de ejemplo y la terminología canónica de §3: código en inglés, comentarios en
      español, ningún `CrearPedido` ni `/pedidos`.

Solo para talleres:

- [ ] Declara en su primer párrafo que es opcional y de qué talleres depende.
- [ ] Sigue la plantilla de §10.3 y el mapa de carpetas fijo.
- [ ] Todos los nombres, puertos, credenciales y semillas son los de §11.
- [ ] Ningún bloque de comandos queda sin desglose; la orquestación es `lab.py`; ninguna versión es `latest` ni un rango.
- [ ] Las tres partes cierran con la suite en verde y el `git diff --stat` literal.
- [ ] Al menos un error provocado a propósito por parte, con su corrección.
- [ ] Teardown junto al recurso.
- [ ] 10–15 preguntas y ejercicios 🟢🟡🟠🔴 copiados literalmente a `06-talleres/12-respuestas.md`.
