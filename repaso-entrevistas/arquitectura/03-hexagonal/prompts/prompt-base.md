# Prompt base: arquitectura hexagonal para refresco técnico y entrevistas

Este documento es el contrato de contenido de `03-hexagonal/`. La forma manda
`guia-de-estilo-y-convenciones.md`; este archivo fija qué cubre cada documento, qué confusión debe
desmontar y qué relación tiene con los demás.

**Audiencia:** alguien que ya programa backend y se prepara para entrevistas de Backend Senior, Tech
Lead o Arquitecto, con Java como perfil base. Puede reconocer HTTP, una transacción y DDD básico; aquí aprende a mantener
esas cosas fuera del núcleo cuando son detalles.

> **Vigencia:** 2026-09-28.

**Salto rápido:** [1](#1--inventario-definitivo) · [2](#2--cómo-leer-una-ficha) · [01](#3--bloque-01--fundamentos-y-modelo-mental) · [02](#4--bloque-02--núcleo-aplicación-y-dominio) · [03](#5--bloque-03--adaptadores-de-entrada) · [04](#6--bloque-04--adaptadores-de-salida-y-operación) · [05](#7-️-bloque-05--plataformas-y-práctica) · [06](#8--bloque-06--talleres) · [9](#9--simulaciones-y-solucionarios)

## 1. 📦 Inventario definitivo

```text
03-hexagonal/
├── README.md
├── prompts/
│   ├── guia-de-estilo-y-convenciones.md
│   └── prompt-base.md
├── 01-fundamentos-y-modelo-mental/        5 capítulos + simulación + respuestas
├── 02-nucleo-aplicacion-y-dominio/         7 capítulos + simulación + respuestas
├── 03-adaptadores-de-entrada/              5 capítulos + simulación + respuestas
├── 04-adaptadores-de-salida-y-operacion/   7 capítulos + simulación + respuestas
├── 05-plataformas-y-practica/              6 capítulos + simulación + respuestas
└── 06-talleres/                           bloque opcional: 11 talleres + solucionario + laboratorio/
    ├── README.md
    ├── 01-contrato-openapi-y-suite.md
    ├── 02-frontend-minimo-react.md
    ├── 03-caso-java-spring-boot.md … 07-caso-php-laravel.md
    ├── 08-colas-jms-activemq-artemis.md … 11-lotes-spring-batch.md
    ├── 12-respuestas.md
    └── laboratorio/   contrato/ scripts/ frontend/ java/ nestjs/ go/ python/ php/ payments-grpc/
```

**Total: 63 documentos** — 30 capítulos, 5 simulaciones, 5 solucionarios, 7 README, 11 talleres,
1 solucionario de talleres y los 4 documentos de `prompts/`. El bloque `06` se produce después del
corpus teórico, es opcional y no forma parte de su recorrido.

## 2. 🧭 Cómo leer una ficha

Cada ficha contiene: **Objetivo** (lo que debes poder afirmar), **Cubre** (el mínimo),
**🧰 Plataformas** (comparación o excepción), **Desmonta** (mitos obligatorios) y **Se toca con**
(dependencias conceptuales y enlaces futuros).

---

## 3. 🧩 Bloque `01` — Fundamentos y modelo mental

Fija vocabulario y límites. No diseña endpoints ni repositorios todavía.

### `01/01` — Qué problema resuelve la arquitectura hexagonal

- **Objetivo:** explicar qué cambio protege y qué no resuelve hexagonal.
- **Cubre:** dolor de acoplar dominio a framework; política contra detalle; regla de dependencias;
  ejemplo `CreateOrder`; coste de las cinco monedas; cuándo un monolito modular sencillo basta.
- **🧰 Plataformas:** no lleva código; tabla ligera de mecanismos de composición.
- **Desmonta:** “hexagonal es solo para microservicios” y “es una estructura de carpetas”.
- **Se toca con:** `01/02`, `02/02`, `04/04`.

### `01/02` — Regla de dependencias y dirección del código

- **Objetivo:** detectar una dependencia que apunta en la dirección equivocada.
- **Cubre:** dependencias de compilación, runtime y datos; núcleo; detalle; por qué una anotación de
  persistencia puede filtrar infraestructura; flujo entrante y saliente.
- **🧰 Plataformas:** tabla completa; código Java y Go de composición explícita.
- **Desmonta:** “si uso DI, las dependencias ya están invertidas”.
- **Se toca con:** `01/03`, `04/04`, `05/01`.

### `01/03` — Puertos y adaptadores

- **Objetivo:** diseñar un puerto por necesidad del núcleo, no por tecnología.
- **Cubre:** puertos de entrada y salida; nombres del lenguaje de negocio; adaptadores; flujo completo;
  granularidad; interfaces que sí y que no existen.
- **🧰 Plataformas:** código Java y TypeScript; tabla de convenciones de cada ecosistema.
- **Desmonta:** “cada clase necesita interfaz” y “un adapter es un wrapper genérico”.
- **Se toca con:** `02/03`, `02/04`, `03/01`, `04/01`.

### `01/04` — Hexagonal, Clean, Onion y capas

- **Objetivo:** comparar estilos sin tratarlos como religiones incompatibles.
- **Cubre:** origen de Ports and Adapters; regla común; diferencias de vocabulario, anillos y énfasis;
  arquitectura por capas correcta e incorrecta; criterio para elegir nomenclatura de equipo.
- **🧰 Plataformas:** no lleva código; matriz comparativa.
- **Desmonta:** “son exactamente lo mismo” y “las capas siempre dependen hacia abajo”.
- **Se toca con:** `01/02`, `01/05`, `05/06`.

### `01/05` — Cuándo no usarla y antipatrones

- **Objetivo:** simplificar sin romper la dirección de dependencias.
- **Cubre:** sobreabstracción; puertos espejo; modelo anémico; dominio que devuelve DTO; god use case;
  infraestructura filtrada; reglas de excepción y fecha de revisión.
- **🧰 Plataformas:** señales de alarma por ecosistema.
- **Desmonta:** “más capas significa mejor arquitectura”.
- **Se toca con:** todos los bloques; escenario obligatorio: CRUD interno pequeño donde no compensa.

---

## 4. 🧠 Bloque `02` — Núcleo, aplicación y dominio

### `02/01` — El dominio en el centro

- **Objetivo:** separar reglas de negocio de coordinación y de transporte.
- **Cubre:** entidades, value objects, invariantes, servicios de dominio y modelo rico sin DDD de
  ceremonia; qué información puede recibir el dominio.
- **🧰 Plataformas:** Java y TypeScript; tabla de tipos y mutabilidad.
- **Desmonta:** “dominio es la carpeta `model`”.

### `02/02` — Casos de uso y servicios de aplicación

- **Objetivo:** distinguir un caso de uso de un controller y de un servicio de dominio.
- **Cubre:** comando, consulta, orquestación, autorización contextual, carga, invocación de dominio y
  persistencia; tamaño; una acción de negocio por caso de uso.
- **🧰 Plataformas:** código Java, Go y Python.
- **Desmonta:** “el caso de uso contiene toda la lógica de negocio”.

### `02/03` — Puertos de entrada

- **Objetivo:** definir una API del núcleo estable ante cambios de transporte.
- **Cubre:** comandos y resultados; datos primitivos contra tipos del dominio; idempotencia de caso de
  uso; queries; interfaz o clase según lenguaje.
- **🧰 Plataformas:** comparación de contratos y validación de tipos.
- **Desmonta:** “un puerto de entrada debe reflejar el endpoint HTTP”.

### `02/04` — Puertos de salida

- **Objetivo:** expresar capacidades requeridas por el núcleo sin revelar proveedor o protocolo.
- **Cubre:** repositorio, reloj, identidad, pagos y publicador; lectura contra escritura; contratos;
  diseño orientado a necesidad; puertos compartidos con cuidado.
- **🧰 Plataformas:** código Java y Go; dobles de prueba.
- **Desmonta:** “el puerto se llama como la tecnología: `JpaRepositoryPort`”.

### `02/05` — Transacciones y límites de consistencia

- **Objetivo:** ubicar el límite transaccional sin hacer que el dominio dependa del ORM.
- **Cubre:** application service como frontera; unidad de trabajo; rollback; consistencia entre puertos;
  qué cambia en mensajería; transacciones declarativas como detalle.
- **🧰 Plataformas:** Spring, Node/TS, Go y Python, con qué queda explícito.
- **Desmonta:** “la transacción pertenece al repositorio”.

### `02/06` — Validación, errores y resultados

- **Objetivo:** decidir qué se valida en borde, aplicación y dominio.
- **Cubre:** forma, autorización, invariantes; errores de negocio; excepciones contra resultados;
  traducción una vez; mensajes seguros.
- **🧰 Plataformas:** tipos resultado, excepciones y errores como valores.
- **Desmonta:** “toda validación va en el controller”.

### `02/07` — Eventos de dominio y efectos secundarios

- **Objetivo:** evitar que una regla de negocio llame infraestructura de forma escondida.
- **Cubre:** evento de dominio contra integración; recolección y publicación posterior; consistencia;
  handlers; límite con outbox.
- **🧰 Plataformas:** código Java y Python; tabla de mecanismos.
- **Desmonta:** “un evento de dominio es un mensaje de Kafka”.

---

## 5. 📥 Bloque `03` — Adaptadores de entrada

### `03/01` — HTTP como adaptador de entrada

- **Objetivo:** traducir HTTP sin filtrar su semántica al caso de uso.
- **Cubre:** controller delgado; request/response DTO; autenticación; mapeo de errores; paginación;
  idempotencia en el borde; qué no debe cruzar.
- **🧰 Plataformas:** Spring Boot, NestJS, Go y FastAPI; código Java y TypeScript.
- **Desmonta:** “el controller llama al repositorio porque es simple”.

### `03/02` — Mensajería, consumidores y comandos

- **Objetivo:** modelar un consumidor como otro adaptador de entrada.
- **Cubre:** deserialización; deduplicación; reintento; ACK; comando; error transitorio contra negocio;
  no contaminar el núcleo con metadatos del broker.
- **🧰 Plataformas:** comparación de clientes y contexto de mensaje.
- **Desmonta:** “el handler del broker es el caso de uso”.

### `03/03` — Jobs, CLI y procesos batch

- **Objetivo:** reutilizar los mismos casos de uso desde disparadores no HTTP.
- **Cubre:** scheduler, CLI, lote, reanudación, locking, parámetros, observabilidad y límites de lote.
- **🧰 Plataformas:** Spring, Node/TS, Go y Python; código Go y Python.
- **Desmonta:** “un cron necesita su propia lógica de negocio”.

### `03/04` — Autenticación, autorización y contexto de actor

- **Objetivo:** colocar identidad y política de autorización sin acoplar el dominio al JWT.
- **Cubre:** identidad autenticada; actor; permisos de borde y reglas de negocio; propagación de
  contexto; auditoría; pruebas.
- **🧰 Plataformas:** tabla completa; sin implementar un sistema de seguridad.
- **Desmonta:** “autorización siempre vive en el controller”.

### `03/05` — DTO, mapeo y presentación de errores

- **Objetivo:** saber cuándo un DTO protege una frontera y cuándo es ceremonia vacía.
- **Cubre:** request, command, response; anti-corruption mapping; versionado; problema details;
  serialización; evitar exponer entidades.
- **🧰 Plataformas:** mappers manuales y generados; coste de cada uno.
- **Desmonta:** “puedo devolver la entidad JPA porque tiene JSON”.

---

## 6. 📤 Bloque `04` — Adaptadores de salida y operación

### `04/01` — Persistencia, repositorios y mapeo

- **Objetivo:** persistir estado sin volver el modelo de dominio una proyección del ORM.
- **Cubre:** contrato del repositorio; mapeo; identidad; lazy loading; N+1; queries; modelos separados;
  cuándo la separación no compensa.
- **🧰 Plataformas:** JPA, Prisma/ORM, sqlc/SQL y SQLAlchemy candidatos; código Java y Go.
- **Desmonta:** “Repository es una interfaz del framework”.

### `04/02` — Clientes HTTP, gRPC y servicios externos

- **Objetivo:** encapsular una integración ajena detrás de una capacidad del negocio.
- **Cubre:** timeouts, errores, contratos externos, mapeo, idempotencia, fallback y anti-corruption
  layer; qué error llega al núcleo.
- **🧰 Plataformas:** cuatro clientes; código Java y Python.
- **Desmonta:** “el caso de uso puede usar el SDK del proveedor directamente”.

### `04/03` — Publicación de eventos y outbox

- **Objetivo:** publicar efectos de integración sin doble escritura ingenua.
- **Cubre:** evento de dominio, evento de integración, outbox, dispatcher, reintento, idempotencia,
  orden y observabilidad; frontera con el bloque de mensajería.
- **🧰 Plataformas:** candidatos por plataforma y código Java.
- **Desmonta:** “guardar y publicar son atómicos porque están en el mismo método”.

### `04/04` — Composition root e inyección de dependencias

- **Objetivo:** construir el grafo de objetos en un borde único y visible.
- **Cubre:** wiring; ciclo de vida; configuración; módulos; DI automática contra explícita; pruebas;
  dónde vive el framework.
- **🧰 Plataformas:** capítulo comparativo principal; código de las cuatro plataformas.
- **Desmonta:** “inyectar una dependencia hace hexagonal al código”.

### `04/05` — Configuración, observabilidad y resiliencia

- **Objetivo:** tratar configuración, logs, métricas y resiliencia como detalles que rodean el núcleo.
- **Cubre:** config tipada; secretos; correlación; trazas; timeout; retry; circuit breaker; métricas
  por caso de uso; no filtrar contexto de framework.
- **🧰 Plataformas:** tabla completa, con código Java y Go.
- **Desmonta:** “observabilidad es responsabilidad exclusiva de infraestructura”.

### `04/06` — Testing por anillos y contratos

- **Objetivo:** probar reglas y fronteras con la menor infraestructura necesaria.
- **Cubre:** pruebas de dominio, casos de uso con dobles, adaptadores con integración, contratos,
  tests arquitectónicos y testcontainers; qué detecta cada nivel.
- **🧰 Plataformas:** herramientas candidatas, verificadas antes de escribir.
- **Desmonta:** “si mockeo todo, ya probé hexagonal”.

### `04/07` — Evolución y migración desde un monolito

- **Objetivo:** extraer un núcleo protegible de código acoplado sin reescribir de golpe.
- **Cubre:** puntos de dolor; seams; strangler interno; envolver detalles; migrar repositorio;
  branch by abstraction; pruebas de caracterización; criterio de parada.
- **🧰 Plataformas:** tabla de refactoring por ecosistema; sin bloques extensos.
- **Desmonta:** “hay que mover todo a nuevas carpetas antes de cambiar una dependencia”.

---

## 7. ⚙️ Bloque `05` — Plataformas y práctica

### `05/01` — Qué cambia entre plataformas

- **Objetivo:** fijar baseline y ejes comparativos: tipos, DI, transacciones, test, contexto y build.
- **Cubre:** tabla maestra; baseline; qué es mecanismo de lenguaje y qué es framework.
- **Desmonta:** “hexagonal se implementa igual en todos los lenguajes”.

### `05/02` — Java y Spring Boot

- **Objetivo:** implementar hexagonal con Spring sin que Spring posea el núcleo.
- **Cubre:** paquetes; beans; transacciones; JPA; tests; anotaciones filtradas; composición.

### `05/03` — Node y TypeScript

- **Objetivo:** usar tipos y módulos sin confundir compilación con validación runtime.
- **Cubre:** NestJS/Fastify candidatos; async; DI; validación; errores; pruebas.

### `05/04` — Go

- **Objetivo:** aprovechar interfaces pequeñas y wiring explícito sin crear una capa por paquete.
- **Cubre:** `context`, errores, composición, SQL, tests y organización por dominio.

### `05/05` — Python

- **Objetivo:** separar el núcleo pese al tipado gradual, ORM y ejecución asíncrona.
- **Cubre:** FastAPI, Pydantic, SQLAlchemy candidatos; protocolos; errores; tests.

### `05/06` — Matriz de decisión y plantilla de servicio

- **Objetivo:** elegir una profundidad hexagonal proporcional y una plantilla que no copie dominio.
- **Cubre:** matriz por volatilidad, integraciones, equipo, riesgo y vida útil; service template;
  criterios de simplificación; revisión periódica.
- **Desmonta:** “la mejor arquitectura es la más pura”.

---

## 8. 🧪 Bloque `06` — Talleres

Implementan el sistema de ejemplo siguiendo §10 y §11 de la guía. `01` es prerrequisito de todo;
`03` lo es de `08`–`11`. El lector hace los que quiera.

### `06/01` — Contrato OpenAPI y suite

- **Objetivo:** fijar el contrato antes de que exista ningún backend, y que la suite sea el criterio
  de terminado de los cinco sabores.
- **Cubre:** repaso de diseño de API con OpenAPI 3.1 (recursos, verbos, códigos, `problem+json`,
  idempotencia con `Idempotency-Key`, paginación por cursor); Swagger UI; colección `hurl` con las
  rutas `v1` (parte 1) y `v1.1` (parte 2) corrida contra un mock del contrato; compose de
  PostgreSQL, MongoDB y Redis; semilla de §11; `lab.py` con `up`, `down`, `seed` y `suite`.
- **Desmonta:** "el contrato se documenta al final, a partir del código".
- **Se toca con:** `02/03`, `03/01`, `03/05`.

### `06/02` — Frontend mínimo en React

- **Objetivo:** ver el frontend como *driving adapter* y el cliente HTTP como adaptador con dos
  implementaciones.
- **Cubre:** login/logout, catálogo, crear pedido, pagar, ver pedido, cancelar; cliente HTTP detrás
  de una interfaz; MSW como implementación mock; URL base como única configuración.
- **Desmonta:** "el frontend depende del backend para existir".

### `06/03`–`06/07` — Un sabor por taller

- **Objetivo común:** implementar las tres partes de §10.2 y mostrar dónde empuja cada framework en
  contra de la frontera.
- **Qué contrasta cada uno:**
  - `06/03` Java + Spring Boot: contenedor DI, proxies transaccionales, JPA con modelo separado,
    ArchUnit como regla de dependencias.
  - `06/04` TypeScript + NestJS: tokens para interfaces borradas, validación runtime, transacción
    compartida en Prisma, promesas con dueño.
  - `06/05` Go (`net/http`, `pgx`, driver oficial de Mongo): composición manual en `main`,
    interfaces junto al consumidor, `sql.Tx` explícito, errores como valores.
  - `06/06` Python + FastAPI: `Protocol` como puerto, `Depends` solo en el borde, SQLAlchemy con
    sesión controlada, Pydantic estricto en DTO.
  - `06/07` PHP + Laravel: Eloquent como *active record* que no es el dominio, service container
    como composition root, `DB::transaction` alrededor del caso de uso, form requests como
    validación de borde.
- **Desmonta:** "hexagonal se implementa igual en todos los lenguajes" y, en `06/07`, "con un ORM
  activo no se puede hacer hexagonal".
- **Se toca con:** `05/02`–`05/05` (el sabor es la versión ejecutable del capítulo) y `04/07`.

### `06/08` — Colas con JMS y ActiveMQ Artemis

- **Objetivo:** ubicar un consumidor JMS como adaptador de entrada del mismo puerto que usa HTTP y
  decidir cuándo confirmar, reintentar o apartar.
- **Cubre:** `OrderRequested` por `orders.inbound` desde otro sistema; respuesta por `orders.reply`
  con `JMSCorrelationID`; `@JmsListener` que traduce a `CreateOrderCommand`; ACK tras commit
  (`CLIENT_ACKNOWLEDGE`, sesión transaccionada, `JmsTransactionManager`); redelivery y
  `JMSXDeliveryCount`; DLQ y política de reintentos; deduplicación por `operationId`; consumidores
  competidores; contrato del mensaje en AsyncAPI 3; provocaciones: caída entre commit y ACK,
  mensaje envenenado, dos consumidores sobre la misma redelivery.
- **Desmonta:** "el handler del broker es el caso de uso" y "ACK y commit son lo mismo".
- **Se toca con:** `03/02`, `02/05`, `02/03`.

### `06/09` — Tópicos con Kafka

- **Objetivo:** sacar la outbox a un log y consumirla con garantías reales.
- **Cubre:** dispatcher que publica `OrderCreated` y `OrderCancelled` en `orders.events`
  particionado por `orderId`; worker de notificaciones y proyección `orders_summary` en groups
  distintos; `GET /reports/orders-summary`; orden por clave; at-least-once y deduplicación por
  `eventId`; commit de offset tras el efecto; rebalance con dos instancias; reconstrucción de la
  proyección desde el offset 0; Kafka en KRaft, un contenedor; provocaciones: caída tras aplicar y
  antes del commit de offset, productor sin clave, borrar y reconstruir la proyección.
- **Desmonta:** "la outbox garantiza exactly once" y "un tópico es una cola con otro nombre".
- **Se toca con:** `04/03`, `02/07`, `03/02`.

### `06/10` — gRPC

- **Objetivo:** sustituir el `PaymentGateway` determinista por un proveedor gRPC real sin tocar
  `AuthorizePayment`.
- **Cubre:** `payments-grpc` (servidor Java pequeño, mismo comportamiento de §11 más latencia y
  fallos inyectables por metadata); `.proto` como contrato; dinero sin `double`; deadline entrante
  propagado y nunca ampliado; `UNAVAILABLE`/`DEADLINE_EXCEEDED` → `UnknownResult`, nunca `Rejected`;
  `Idempotency-Key` en metadata; stub in-process para las pruebas del adaptador. 🔥 gRPC como
  entrada: `OrderService.CreateOrder` sobre el mismo puerto; `google.rpc.Status` ↔ `problem+json`.
- **Desmonta:** "timeout significa que no hubo cobro".
- **Se toca con:** `04/02`, `04/05`, `02/04`.

### `06/11` — Lotes con Spring Batch

- **Objetivo:** reutilizar casos de uso desde un lote reanudable y desde la CLI sin duplicar
  política.
- **Cubre:** caso de uso nuevo `AdjustStock`; job `stockAdjustment` que lee `stock-YYYY-MM-DD.csv`
  por chunks, valida y cuyo `ItemWriter` llama al puerto; job `dailyClose`; el jar con
  `--job=... --file=...` como CLI lanzada desde `lab.py`; chunk como transacción pequeña;
  `JobRepository` en Postgres como checkpoint; restart desde el último chunk confirmado; skip
  policy como cuarentena; `JobExecutionAlreadyRunningException` como lease; `dry-run` con writer
  que no escribe; provocaciones: matar el job a mitad y reiniciar, dos réplicas del mismo
  `JobInstance`, CSV con una línea corrupta entre mil.
- **Desmonta:** "un cron necesita su propia lógica de negocio" y "una transacción larga garantiza el
  lote".
- **Se toca con:** `03/03`, `02/05`.

### `06/12` — Respuestas

- **Objetivo:** solucionario único de las preguntas y ejercicios de `06/01`–`06/11`, con enunciado
  literal y tres capas, como los de bloque.

## 9. 🧪 Simulaciones y solucionarios

Cada bloque cierra con su simulación y un solucionario. Escenarios obligatorios: un endpoint que
filtra JPA al dominio; consumidor que usa metadatos del broker en la lógica; pago externo que cambia
su contrato; transacción con evento perdido; migración gradual de un monolito; y un CRUD donde la
respuesta correcta sea eliminar abstracciones.
