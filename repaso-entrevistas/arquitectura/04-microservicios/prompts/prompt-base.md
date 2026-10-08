# Prompt base: temario de microservicios para refresco técnico y entrevistas

Este documento es el **contrato de contenido** de `04-microservicios/`: qué cubre cada archivo,
qué confusiones tiene que desmontar, qué se muestra de cada plataforma y con qué otros documentos se
toca. La forma —tono, plantilla, callouts, cantidad de preguntas— la manda
[`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md), que es normativa y gana sobre
este documento en todo lo que declare.

**Audiencia:** alguien que ya programa, ya entiende sistemas distribuidos y ya leyó
[`arquitectura/01-bases`](../../01-bases/) —o puede leerlo en
paralelo—, que se prepara para entrevistas de **Backend Senior / Tech Lead / Arquitecto** con Java como
perfil base y banca como dominio de referencia. No se explica qué es HTTP, qué es una transacción ni qué es un
contexto acotado: se enlaza. `01-bases` es el **único prerrequisito**; los demás corpus que se
enlazan (`02-monolito`, `03-hexagonal`, `bases/04-apis-protocolos`, `frameworks/01-spring-boot`, nube)
son sugerencias de estudio: ningún documento exige haberlos leído, y lo mínimo que haga falta de
ellos se resume donde se usa.

**La aportación propia de este corpus**, y lo que hay que proteger en cada documento: el patrón no se
describe, **se implementa**, y se implementa en cuatro plataformas —**Java · Node/TS · Go ·
Python**— para que se vea qué te da hecho cada una y qué te deja a ti.

**Baseline de versiones:** se fija en `05-plataformas/01` y se repite en el `README.md` del corpus.
Ningún otro documento fija versiones menores salvo que el comportamiento cambie con ellas (§5.4 de
la guía). Las librerías que este documento nombra son **candidatas**: antes de escribirlas en un
capítulo se comprueba que existen, que se escriben así y que siguen mantenidas (§10.1 de la guía).

> **Vigencia:** 2026-09-29.

**Salto rápido:** [1](#1--inventario-de-archivos) · [2](#2--cómo-se-lee-la-ficha-de-cada-documento) · [3](#3--bloque-01--fundamentos-y-descomposición) · [4](#4--bloque-02--comunicación) · [5](#5-️-bloque-03--datos-y-consistencia) · [6](#6-️-bloque-04--operación-y-resiliencia) · [7](#7--bloque-05--plataformas) · [8](#8--qué-queda-fuera-del-corpus-y-por-qué) · [9](#9-️-el-readmemd-del-corpus) · [10](#10--bloque-06--talleres)

---

## 1. 📦 Inventario de archivos

```text
04-microservicios/
├── README.md                              índice, orden de lectura, mapa y baseline
├── prompts/
│   ├── guia-de-estilo-y-convenciones.md   normativa editorial
│   └── prompt-base.md                     este documento
├── 01-fundamentos-y-descomposicion/       5 capítulos + simulación + respuestas
├── 02-comunicacion/                       7 capítulos + simulación + respuestas
├── 03-datos-y-consistencia/               5 capítulos + simulación + respuestas
├── 04-operacion-y-resiliencia/            7 capítulos + simulación + respuestas
├── 05-plataformas/                        6 capítulos + simulación + respuestas
└── 06-talleres/                           opcional: 11 talleres + respuestas + laboratorio/
```

**Nombres de archivo definitivos.** Se fijan aquí para que ningún enlace se escriba a ciegas, y no
se cambian sin actualizar los enlaces entrantes en la misma edición.

```text
01-fundamentos-y-descomposicion/
  README.md
  01-que-es-un-microservicio.md
  02-descomposicion-y-fronteras.md
  03-el-camino-desde-el-monolito.md
  04-el-monolito-distribuido.md
  05-el-servicio-por-dentro.md
  06-simulacion-de-entrevista.md
  07-respuestas.md

02-comunicacion/
  README.md
  01-estilos-de-comunicacion.md
  02-http-entre-servicios.md
  03-grpc.md
  04-http-contra-grpc.md
  05-tiempo-real-websockets-y-sse.md
  06-mensajeria-y-eventos.md
  07-contratos-y-versionado.md
  08-simulacion-de-entrevista.md
  09-respuestas.md

03-datos-y-consistencia/
  README.md
  01-base-de-datos-por-servicio.md
  02-consultas-entre-servicios.md
  03-saga.md
  04-outbox-inbox-e-idempotencia.md
  05-evolucion-de-esquema-y-migraciones.md
  06-simulacion-de-entrevista.md
  07-respuestas.md

04-operacion-y-resiliencia/
  README.md
  01-descubrimiento-y-enrutamiento.md
  02-api-gateway-y-bff.md
  03-resiliencia-en-la-practica.md
  04-observabilidad-y-trazas.md
  05-service-mesh-y-sidecar.md
  06-despliegue-y-entrega.md
  07-testing-de-microservicios.md
  08-simulacion-de-entrevista.md
  09-respuestas.md

05-plataformas/
  README.md
  01-que-cambia-entre-plataformas.md
  02-java.md
  03-node-y-typescript.md
  04-go.md
  05-python.md
  06-la-matriz-de-decision.md
  07-simulacion-de-entrevista.md
  08-respuestas.md

06-talleres/
  README.md
  01-el-monolito-y-su-contrato.md
  02-strangler-fig-con-envoy.md
  03-http-entre-servicios.md
  04-grpc.md
  05-resiliencia-en-tres-plataformas.md
  06-kafka-outbox-inbox-y-dlq.md
  07-observabilidad-de-extremo-a-extremo.md
  08-saga-coreografiada.md
  09-saga-orquestada.md
  10-contratos-y-testing.md
  11-consultas-y-tiempo-real.md
  12-respuestas.md
```

**Total: 63 documentos** — 30 capítulos + 5 simulaciones + 5 solucionarios + 5 README de bloque +
el README del corpus + los 4 de `prompts/` + los 13 del bloque `06-talleres/` (11 talleres, su
solucionario y su README). El código de `06-talleres/laboratorio/` no cuenta como documento.

---

## 2. 🧭 Cómo se lee la ficha de cada documento

Cada entrada de las secciones 3 a 7 tiene el mismo molde:

- **Objetivo** — la frase que el lector debe poder decir después de leerlo.
- **Cubre** — el contenido mínimo obligatorio. No es un índice: es el piso.
- **🧰 Plataformas** — qué entra en la sección de las cuatro plataformas: las librerías candidatas y
  **de cuáles se escribe código** (§5.3 de la guía). Si el capítulo no lleva esa sección, se declara
  aquí con su porqué.
- **Desmonta** — las sobregeneralizaciones de entrevista que ese documento tiene que atacar
  explícitamente (§2 de la guía). **Al menos una por documento.**
- **Se toca con** — los enlaces internos obligatorios, dentro y fuera del corpus.

Lo que **no** está en la ficha puede entrar si el autor lo justifica; lo que **sí** está no se puede
omitir sin declararlo en el propio documento.

---

# 3. 🧩 Bloque `01` — Fundamentos y descomposición

**Qué hace el bloque:** fija el vocabulario, las fronteras y el precio. Es el único bloque donde casi
no hay código, y eso está declarado: aquí se decide **qué servicios existen**, no cómo se escriben.
Los otros cuatro bloques lo asumen leído.

## `01/01` — Qué es un microservicio

- **Objetivo:** definir un microservicio sin decir "es un servicio pequeño", y nombrar el precio
  antes de que te lo pregunten.
- **Cubre:** la definición por **autonomía**, no por tamaño: desplegable solo, dueño de sus datos,
  falla solo · las tres propiedades que hay que poder recitar (despliegue independiente, datos
  propios, frontera de negocio) · qué **no** define un microservicio (líneas de código, número de
  endpoints, "un equipo de dos pizzas") · el precio de entrada, en las cinco monedas de §4.2 de la
  guía: la llamada local que se vuelve red, la transacción que se vuelve saga, el stack trace que se
  vuelve traza distribuida, el despliegue que se vuelve orquestación · **cuándo no**: equipo pequeño,
  dominio todavía inestable, sistema sin necesidad de escalado diferencial · el monolito modular como
  respuesta legítima y por qué es la que más puntos da en una entrevista senior · qué se gana de
  verdad: despliegue independiente, escalado diferencial, autonomía de equipo, aislamiento de fallo,
  libertad de stack — cada uno con su asterisco.
- **🧰 Plataformas:** **no lleva** sección de plataformas. Es un capítulo de definición y no hay nada
  que implementar; la comparativa entra desde `01/05`. Se declara en el encabezado.
- **Desmonta:** "los microservicios escalan mejor" · "un microservicio es un servicio pequeño" ·
  "cada microservicio es un repositorio" · "si usas Docker y Kubernetes, tienes microservicios".
- **Se toca con:** `01/02`, `01/04`, y
  [`arquitectura/01-bases/01-bases/02`](../../01-bases/01-bases/02-estilos-de-despliegue.md),
  que es dueño de la decisión *monolito contra microservicios* y no se reescribe aquí.

## `01/02` — Descomposición y fronteras

- **Objetivo:** proponer un corte de servicios y defenderlo, en papel, en quince minutos.
- **Cubre:** descomposición **por capacidad de negocio** y **por subdominio** (DDD), y en qué se
  diferencian de verdad · el contexto acotado (*bounded context*) como frontera candidata, y por qué "candidata" y no
  "igual" · heurísticas que funcionan: por razón de cambio, por volatilidad, por perfil de carga, por
  dueño de los datos, por frontera de cumplimiento normativo · los cortes que no son criterio: por
  capa (un servicio "de datos"), por entidad (un servicio por tabla), por verbo (un servicio
  "validador"), por reutilización · el test de la frontera: si dos servicios cambian siempre juntos,
  son uno · acoplamiento aferente y eferente, y cómo se mira sin herramientas caras · el corte del
  sistema de ejemplo (§5.5 de la guía) hecho paso a paso y con sus dudas declaradas · cómo se
  responde "¿cuántos microservicios harías?" sin decir un número.
- **🧰 Plataformas:** **no lleva**. La descomposición no depende de la plataforma, y decirlo
  explícitamente es contenido: es una de las pocas decisiones del corpus que no cambia entre Java y
  Go.
- **Desmonta:** "se descompone por entidades del modelo" · "un contexto acotado es un microservicio" ·
  "primero el corte técnico y luego el de negocio" · "si comparten código, comparten servicio".
- **Se toca con:** `01/01`, `01/03`, `03/01`, y
  [`arquitectura/01-bases/01-bases/06`](../../01-bases/01-bases/06-ddd-estrategico.md)
  para DDD estratégico, que es su dueño.

## `01/03` — El camino desde el monolito

- **Objetivo:** proponer una migración por fases que no pare el negocio, y decir qué se extrae
  primero.
- **Cubre:** por qué no se empieza por microservicios y sí por monolito modular · **strangler fig**:
  la fachada, la ruta que se desvía, el criterio de corte, cuánto dura de verdad · **branch by
  abstraction** para lo que no se puede desviar por ruta · la **capa anticorrupción** hacia el legado
  · el orden de extracción: primero lo que tiene frontera clara y datos propios, nunca lo que más
  duele · **los datos son lo difícil**: separar el esquema antes o después del código, la doble
  escritura, la lectura desde la fuente vieja, el punto de no retorno · cómo se mide que la fase
  funcionó (latencia, errores, y sobre todo: ¿se puede desplegar solo?) · el rollback: qué se puede
  deshacer y qué no · el caso bancario: extraer alrededor de un core que no se toca.
- **🧰 Plataformas:** ligera. Una tabla con qué ofrece cada ecosistema para la fachada y el desvío de
  tráfico —enrutamiento en el gateway frente a fachada en la aplicación—; sin bloques de código, que
  viven en `04/02`.
- **Desmonta:** "primero partimos la base de datos" · "reescribimos en paralelo y cambiamos de golpe"
  · "el strangler fig termina en seis meses" · "el legado se envuelve y ya está".
- **Se toca con:** `01/04`, `03/05`, `04/02`, y
  [`arquitectura/01-bases/05-banca/04`](../../01-bases/05-banca/04-capa-anticorrupcion.md).

## `01/04` — El monolito distribuido y los demás antipatrones

- **Objetivo:** reconocer en dos minutos que una arquitectura "de microservicios" no lo es, y decir
  por qué.
- **Cubre:** el **monolito distribuido**: todos los costes de la red y ninguno de los beneficios;
  cómo se detecta (no se puede desplegar uno solo, no se puede probar uno solo, un cambio toca tres
  repositorios) · **base de datos compartida**, incluida la variante "solo para leer" y por qué
  tampoco · **librería común** que obliga a desplegar a todos a la vez, y la línea entre compartir
  código de infraestructura y compartir dominio · **cadena síncrona larga**: cómo se multiplican las
  probabilidades de fallo y la latencia, con números · **servicios CRUD por entidad** y el servicio
  "anémico" que solo reenvía · **nano-servicios** y el coste fijo por servicio · **el ESB
  rebautizado**: lógica de negocio en el gateway · la autopsia (§9.4 de la guía) de una cadena de
  cinco saltos que se cae por un timeout mal puesto.
- **🧰 Plataformas:** una tabla de **señales de alarma por ecosistema**: el `pom` padre compartido en
  Java, el paquete `common` en npm, el módulo interno compartido en Go, el paquete privado en
  Python — y qué distingue compartir un cliente generado (bien) de compartir el modelo de dominio
  (mal).
- **Desmonta:** "compartimos la base de datos solo para lecturas" · "tenemos una librería común para
  no repetir código" · "los servicios se llaman entre sí, es normal" · "cada uno tiene su repositorio,
  entonces son independientes".
- **Se toca con:** `01/02`, `02/01`, `03/01`, `04/03`.

## `01/05` — El servicio por dentro

- **Objetivo:** describir qué hay dentro de un servicio bien hecho, y qué hace igual en las cuatro
  plataformas.
- **Cubre:** la estructura interna mínima: transporte, aplicación, dominio, adaptadores de salida, y
  por qué hexagonal rinde más aquí que en un monolito · **service template / chassis**: qué trae
  —configuración, logging estructurado, health checks, métricas, tracing, cliente HTTP con timeouts,
  apagado ordenado— y por qué se genera en vez de copiarse · configuración externalizada y los
  principios de 12-factor que siguen vigentes y los que no · **apagado ordenado** (`graceful
  shutdown`) y por qué sin él cada despliegue tira peticiones · health checks: liveness contra
  readiness, y el error clásico de comprobar la base de datos en liveness · el arranque y su coste
  según plataforma · qué **no** va dentro del servicio: la lógica de otro contexto, el acceso a la
  base de datos de otro.
- **🧰 Plataformas:** sección completa y primera del corpus. Tabla de qué te da cada una para el
  chassis: Spring Boot con Actuator; NestJS con su estructura de módulos frente a Fastify desnudo;
  Go con `net/http` y el apagado a mano; FastAPI con `lifespan`. Código de Java y de Go —el apagado
  ordenado es donde más se nota la diferencia—.
- **Desmonta:** "hexagonal es para monolitos" · "el health check comprueba que la base de datos
  responde" · "la configuración va en el `application.yml` del repositorio" · "el chassis es copiar y
  pegar el proyecto anterior".
- **Se toca con:** `04/04`, `04/06`, `05/01`, y
  [`arquitectura/01-bases/01-bases/03`](../../01-bases/01-bases/03-arquitecturas-de-aplicacion.md).

## `01/06` — Simulación de entrevista

Sigue §7.2 de la guía. **Escenarios obligatorios de este bloque:** un corte de servicios sobre un
dominio nuevo; una migración desde un monolito con base de datos compartida; y el caso donde **la
respuesta correcta es no separar**.

## `01/07` — Respuestas

Solucionario del bloque. Sigue §7.3 y §8.3 de la guía.

---

# 4. 📡 Bloque `02` — Comunicación

**Qué hace el bloque:** el corazón del corpus junto con `05`. Responde qué estilo se usa entre dos
servicios, y lo responde comparando, no enumerando. Asume leído `01`. La semántica de HTTP es
de [`bases/04-apis-protocolos`](../../../bases/04-apis-protocolos/), opcional: aquí se
resume lo mínimo y se explica **cómo se usa entre servicios**, no qué obliga el RFC.

## `02/01` — Estilos de comunicación

- **Objetivo:** dibujar el mapa completo de estilos y situar cualquier tecnología en él.
- **Cubre:** los dos ejes: **síncrono / asíncrono** y **uno-a-uno / uno-a-muchos**, con la matriz
  resultante y un ejemplo real en cada casilla · **acoplamiento temporal**: la decisión de fondo, y
  por qué es más importante que el protocolo · request-response, request-async-response, notificación
  unidireccional, publicación-suscripción, streaming · dónde caen HTTP, gRPC, WebSocket, SSE,
  webhooks, colas y topics · el coste inevitable de la red: latencia, fallo parcial, y la falacia de
  que la red es fiable (las ocho falacias, pero usadas, no recitadas) · por qué "asíncrono" no
  significa "no bloqueante" y por qué esa confusión cuesta puntos · la regla de entrada: **síncrono
  para consultas que el usuario espera, asíncrono para efectos**.
- **🧰 Plataformas:** tabla de qué significa "asíncrono" en cada una —hilos y virtual threads en
  Java, bucle de eventos en Node, goroutines en Go, `asyncio` frente a WSGI en Python— y por qué esa
  diferencia **no** cambia el estilo de comunicación pero sí el coste de implementarlo.
- **Desmonta:** "asíncrono es más rápido" · "usamos eventos para desacoplar" (sin decir de qué) ·
  "asíncrono y no bloqueante son lo mismo" · "REST es síncrono por definición".
- **Se toca con:** `02/02`, `02/06`, `04/03`, y
  [`arquitectura/01-bases/01-bases/08`](../../01-bases/01-bases/08-comunicacion-e-integracion.md).

## `02/02` — HTTP entre servicios

- **Objetivo:** diseñar y consumir una API interna sabiendo en qué se diferencia de una pública.
- **Cubre:** qué cambia en una API **interna**: consumidores conocidos, versionado negociado en vez
  de eterno, menos hipermedia, más contrato compilado · el cliente HTTP como pieza de diseño:
  **timeout de conexión y de lectura, pool de conexiones, keep-alive, reintentos, límite de
  concurrencia** — y el error de dejar todos los valores por defecto · propagación de encabezados:
  `traceparent`, identificador de correlación, identidad, `Idempotency-Key` · paginación entre
  servicios y por qué el `offset` grande se paga caro · errores: forma estable del cuerpo de error,
  qué códigos significan "reintenta" y cuáles "no insistas", `Retry-After` · contenido: JSON por
  defecto, cuándo compensa algo binario · el `N+1` distribuido y sus dos salidas (endpoint de lote o
  evento).
- **🧰 Plataformas:** tabla de clientes con sus valores por defecto **reales** —qué timeout trae de
  fábrica cada uno, que es donde están las sorpresas—: el cliente de Spring y el declarativo de
  Feign; `undici`/`fetch` y el cliente de NestJS; `net/http` con su `Transport` en Go; `httpx` y
  `requests` en Python. Código de Java y de Go.
- **Desmonta:** "el cliente HTTP ya trae timeout por defecto" · "una API interna se diseña igual que
  una pública" · "si falla, reintentamos" · "para no hacer N llamadas, montamos un endpoint que
  devuelve todo".
- **Se toca con:** `02/04`, `02/07`, `04/03`, y
  [`bases/04-apis-protocolos`](../../../bases/04-apis-protocolos/) para la
  semántica del protocolo.

## `02/03` — gRPC

- **Objetivo:** explicar qué es gRPC de verdad —contrato compilado sobre HTTP/2— y escribir un
  servicio y un cliente sin titubear.
- **Cubre:** Protocol Buffers: el `.proto` como fuente de verdad, los números de campo y por qué no
  se reutilizan, tipos escalares, `optional`, `oneof`, `repeated`, y qué significa que el formato sea
  **binario y posicional** · los **cuatro modos**: unario, streaming de servidor, de cliente,
  bidireccional, con un caso real para cada uno · **deadlines**, que es la pieza que más se ignora y
  la que más rinde: se propagan por la cadena, a diferencia del timeout de HTTP · códigos de estado
  de gRPC y su mapeo mental con los de HTTP · interceptores como equivalente de los filtros ·
  metadata · balanceo: por qué HTTP/2 multiplexado rompe el balanceo por conexión y qué se hace (L7,
  `round_robin` del lado del cliente, o mesh) · gRPC-Web y por qué el navegador no habla gRPC ·
  reflexión, `grpcurl` y el argumento de "no se puede depurar" bien contestado.
- **🧰 Plataformas:** sección grande. Generación de código y experiencia real en cada una:
  `protoc`/Buf con el plugin de Java y el arranque en Spring o Quarkus; `@grpc/grpc-js` y las
  alternativas de Connect en Node/TS; **Go, donde gRPC es ciudadano de primera** y el código generado
  es idiomático; `grpcio` y `grpcio-tools` en Python, con su asunto de `asyncio`. Código de Go y de
  Java; tabla para las cuatro.
- **Desmonta:** "gRPC es más rápido que REST" (sin decir en qué) · "gRPC no se puede depurar" · "el
  `.proto` se puede cambiar si nadie usa ese campo" · "gRPC necesita service mesh".
- **Se toca con:** `02/04`, `02/07`, `04/01`.

## `02/04` — HTTP contra gRPC

- **Objetivo:** elegir entre los dos en voz alta, con criterios, y no ganar la discusión con
  benchmarks de internet.
- **Cubre:** la comparativa dimensión por dimensión: **contrato** (OpenAPI descriptivo frente a
  `.proto` compilado), **formato** (texto frente a binario, y cuánto importa de verdad), **latencia y
  ancho de banda** con órdenes de magnitud y la advertencia de que el serializador rara vez es el
  cuello de botella, **streaming**, **tooling y depuración**, **navegador**, **versionado y
  evolución**, **curva de equipo**, **observabilidad**, **soporte de infraestructura** (proxies,
  balanceadores, WAF, API gateway) · el criterio real: gRPC hacia adentro entre servicios con
  contrato estable y equipos que lo mantienen; HTTP hacia afuera y hacia el navegador, y hacia
  adentro cuando el equipo o la infraestructura no lo sostienen · **los terceros en discordia**:
  GraphQL (y por qué su sitio es el borde, no el interior), tRPC (y por qué solo vale si ambos lados
  son TypeScript del mismo repositorio), y una mención honesta a por qué SOAP todavía aparece en
  banca · el caso mixto: gRPC interno con gateway que expone REST, y qué cuesta mantener los dos
  contratos.
- **🧰 Plataformas:** tabla de **coste de adopción por ecosistema**: cuánto trabajo es meter gRPC en
  cada una, qué tan idiomático queda el código generado, y qué falta. Es la sección que decide la
  respuesta en la práctica.
- **Desmonta:** "gRPC es 7 veces más rápido, lo dice el benchmark" · "REST es para APIs públicas y
  gRPC para internas, y ya" · "con gRPC no necesitas versionar" · "GraphQL sustituye a REST".
- **Se toca con:** `02/02`, `02/03`, `02/07`, `05/06`.

## `02/05` — Tiempo real: WebSockets, SSE y los demás

- **Objetivo:** elegir el mecanismo de empuje correcto y saber por qué casi nunca es WebSocket entre
  servicios.
- **Cubre:** el problema: el servidor tiene algo que decir y el cliente no está preguntando ·
  **polling** y long polling, con su coste y por qué a veces sigue siendo la respuesta correcta ·
  **SSE**: unidireccional, sobre HTTP normal, con reconexión y `Last-Event-ID` de regalo; el caso de
  uso que se lleva la mayoría de las necesidades reales · **WebSocket**: bidireccional, con handshake
  de actualización, sin semántica encima —lo que significa que el protocolo de mensajes te lo
  inventas tú— · **webhooks** como empuje entre sistemas, con su firma, sus reintentos y su
  necesidad de idempotencia · **streaming de gRPC** como la opción entre servicios · el problema
  transversal: **la conexión tiene estado**, y eso rompe el escalado horizontal, los despliegues
  rolling y el balanceo; qué se hace (afinidad, backplane, mover el estado fuera) · autenticación en
  una conexión larga y qué pasa cuando el token expira a la mitad · cuándo aplica de verdad en el
  sistema de ejemplo: seguimiento del pedido hacia el cliente, sí; entre `orders` e `inventory`,
  no.
- **🧰 Plataformas:** tabla completa: el soporte de WebSocket y SSE en Spring —bloqueante y
  reactivo—; `ws` y Socket.IO frente al gateway de NestJS; `gorilla/websocket` y SSE a mano en Go;
  WebSocket y SSE en FastAPI/Starlette. Código de Node/TS y de Go, que es donde más se ve la
  diferencia de modelo; **el capítulo declara por qué no hay bloque de Java** (§5.3 de la guía) y
  remite a su fila de la tabla.
- **Desmonta:** "para tiempo real, WebSocket" · "SSE es lo mismo pero peor" · "el WebSocket escala
  igual que un endpoint HTTP" · "los webhooks son fire and forget".
- **Se toca con:** `02/01`, `02/03`, `04/06`.

## `02/06` — Mensajería y eventos

- **Objetivo:** integrar dos servicios por mensajes sin inventar garantías que no existen.
- **Cubre:** **comando contra evento**, que es la distinción que más rinde: destinatario conocido y
  expectativa de efecto, frente a hecho publicado sin destinatario · cola contra topic, y el reparto
  entre consumidores · qué te da un broker y qué no: **al-menos-una-vez** como norma, orden solo
  dentro de la partición, y por qué *exactly-once* no se elige · el consumidor idempotente como
  requisito, no como mejora · reintentos, backoff, **DLQ** y qué se hace con lo que cae ahí ·
  *poison message* y el envenenamiento del consumidor · lag del consumidor: qué es, cómo se mira,
  qué significa que crezca · el esquema del mensaje y su evolución (se profundiza en `02/07`) · una
  comparativa **corta y honesta** de brokers —Kafka, RabbitMQ, SQS/SNS, Pub/Sub, NATS— remitiendo a
  [`arquitectura/01-bases/02-eventos/02`](../../01-bases/02-eventos/02-brokers-comparados.md),
  que es su dueño y no se duplica.
- **🧰 Plataformas:** tabla de cliente y abstracción por ecosistema: Spring Kafka y las
  anotaciones de escucha frente al cliente desnudo; BullMQ y los clientes de Kafka en Node/TS;
  `kafka-go`/`sarama` y Watermill en Go; Celery y los clientes de Kafka en Python. Código de Java y
  de Python, que es donde el consumidor idempotente se ve mejor.
- **Desmonta:** "con Kafka tenemos exactly-once" · "los eventos garantizan el orden" · "si falla,
  el broker reintenta y ya" · "publicamos un evento por cada cambio de estado de la entidad".
- **Se toca con:** `03/03`, `03/04`, y el bloque
  [`02-eventos`](../../01-bases/02-eventos/) del corpus de arquitectura, dueño
  de la teoría.

## `02/07` — Contratos y versionado

- **Objetivo:** cambiar un contrato en producción sin romper a nadie, y demostrarlo en CI.
- **Cubre:** el contrato como artefacto versionado, no como documentación · **compatibilidad hacia
  atrás y hacia adelante**, con la tabla de qué cambio es cuál: añadir un campo opcional, quitar uno,
  renombrar, cambiar un tipo, añadir un valor a un enumerado · **expand/contract** aplicado a
  contratos · versionado: en la ruta, en el encabezado, por contenido, y la respuesta honesta de qué
  hace la industria · qué versiona gRPC y cómo (números de campo, `reserved`) frente a qué versiona
  HTTP · **tolerant reader** y el principio de robustez, con su matiz moderno · **consumer-driven
  contracts** con Pact: qué problema resuelve que no resuelven los tests de integración, quién
  publica qué, y el *broker* de pactos en el pipeline · OpenAPI y AsyncAPI: generar el cliente desde
  el contrato frente a generar el contrato desde el código, y por qué el segundo camino pierde ·
  quién es dueño del contrato cuando dos equipos discuten.
- **🧰 Plataformas:** tabla de generación y verificación: la familia de Spring Cloud Contract y los
  generadores de OpenAPI en Java; los generadores de cliente TypeScript y Zod para validar en el
  borde; la generación desde `.proto` y las herramientas de Buf en Go; Pydantic y los generadores en
  Python. Se nombra Pact, que tiene implementación en las cuatro.
- **Desmonta:** "versionamos la API con `/v2` y ya está" · "el contrato lo genera el código" ·
  "añadir un campo nunca rompe" · "los tests de integración cubren el contrato".
- **Se toca con:** `02/03`, `02/04`, `04/07`.

## `02/08` — Simulación de entrevista

Sigue §7.2. **Escenarios obligatorios:** elegir el estilo de comunicación para tres integraciones
distintas del mismo sistema; y un caso donde **la plataforma cambia la respuesta** (gRPC entre dos
servicios de Go frente a los mismos dos en Python).

## `02/09` — Respuestas

Solucionario del bloque.

---

# 5. 🗄️ Bloque `03` — Datos y consistencia

**Qué hace el bloque:** implementa lo que el corpus de arquitectura razona en
[`03-datos`](../../01-bases/03-datos/) y
[`02-eventos`](../../01-bases/02-eventos/). Aquí no se explica qué es CAP ni
qué es event sourcing: se escribe la saga, la tabla del outbox y la migración.

## `03/01` — Base de datos por servicio

- **Objetivo:** defender la regla, nombrar sus excepciones reales y decir cómo se llega a ella desde
  un esquema compartido.
- **Cubre:** por qué es la regla que de verdad define un microservicio · qué se rompe cuando se
  comparte: el despliegue, el esquema, el rendimiento ajeno y el aislamiento de fallo · las
  excepciones honestas y acotadas: réplica de solo lectura para informes, esquema compartido durante
  una migración con fecha de caducidad, datos de referencia · **cómo se separa**: esquemas separados
  en la misma instancia → instancias separadas → tecnologías distintas, y qué se gana en cada escalón
  · las claves foráneas que desaparecen y qué las sustituye · datos duplicados a propósito: qué se
  copia, qué se referencia, y cómo se decide · persistencia políglota sin caer en el "una base de
  datos por moda".
- **🧰 Plataformas:** tabla de acceso a datos y migraciones por ecosistema: JPA frente a JDBC y las
  herramientas de migración de Java; Prisma y TypeORM en Node/TS; `database/sql`, `sqlc` y las
  migraciones en Go; SQLAlchemy y Alembic en Python. La comparación útil no es el ORM: es **quién
  versiona el esquema y cuándo corre la migración**.
- **Desmonta:** "cada servicio tiene su base de datos" (dicho sin matices) · "compartir la base de
  datos para lecturas no acopla" · "sin claves foráneas se corrompen los datos" · "cada servicio elige
  su motor y eso es bueno".
- **Se toca con:** `03/02`, `03/05`, `01/04`.

## `03/02` — Consultas entre servicios

- **Objetivo:** responder "¿y cómo hago el join si están en bases distintas?" con tres opciones y su
  precio.
- **Cubre:** el problema real: la pantalla que necesita datos de tres servicios · **API composition**:
  quién compone, dónde vive, el coste en latencia (secuencial frente a paralelo) y el fallo parcial ·
  **CQRS con vista materializada**: quién la mantiene, con qué eventos, cuánto se retrasa, qué pasa
  si se corrompe y cómo se reconstruye · **réplica de datos de referencia** como opción barata ·
  cuándo la respuesta correcta es **rediseñar la frontera**, porque la consulta está diciendo que el
  corte está mal · la consulta de informes y analítica, que no se resuelve con ninguna de las
  anteriores sino sacando los datos fuera · el precio de la consistencia eventual expresado en
  producto: qué ve el usuario y durante cuánto tiempo.
- **🧰 Plataformas:** tabla de composición concurrente —el patrón se ve distinto en cada modelo de
  ejecución—: virtual threads y `CompletableFuture` en Java; `Promise.all` en Node/TS; goroutines con
  `errgroup` en Go; `asyncio.gather` en Python. Código de las cuatro: es el caso donde los cuatro
  bloques enseñan algo distinto y §5.3 lo justifica.
- **Desmonta:** "montamos un servicio que consulta todas las bases" · "la vista materializada siempre
  está desactualizada" · "componemos en el gateway y ya está" · "CQRS es tener dos bases de datos".
- **Se toca con:** `04/02`, `03/04`, y
  [`arquitectura/01-bases/03-datos/06`](../../01-bases/03-datos/06-cqrs.md).

## `03/03` — Saga

- **Objetivo:** diseñar la saga del sistema de ejemplo en papel, con sus compensaciones y sus estados,
  y decir qué anomalías admite.
- **Cubre:** por qué no hay transacción distribuida, y por qué 2PC no es la respuesta (con su porqué
  técnico, no solo "no se usa") · **coreografía**: cada servicio reacciona a eventos; cuándo es
  elegante y cuándo se vuelve ilegible (la regla práctica: a partir de cuatro pasos, nadie sabe el
  estado global) · **orquestación**: un coordinador con la máquina de estados explícita; el riesgo de
  que el orquestador acumule lógica de negocio ajena · **compensaciones**: por qué no son rollback,
  las operaciones que no se pueden compensar (correo enviado, dinero movido a un tercero) y qué se
  hace entonces · pasos **compensables, pivote y reintentables**, y por qué ordenar los pasos así es
  la mitad del diseño · las anomalías de falta de aislamiento —lecturas sucias, actualizaciones
  perdidas— y sus contramedidas: bloqueo semántico, ficheros de versión, valor conmutativo, relectura
  · el timeout de la saga y la intervención manual como parte del diseño, no como fallo · **la saga
  canónica del corpus**, resuelta entera en coreografía y en orquestación, para comparar.
- **🧰 Plataformas:** sección grande. Tres niveles, con tabla: **a mano** (máquina de estados propia
  + outbox, posible en las cuatro), **con framework de saga** del ecosistema, y **con motor de
  workflow** —Temporal, que tiene SDK en las cuatro plataformas, y los motores BPM del mundo Java—.
  Código de Java (orquestador con máquina de estados) y de Go (la misma con `context` y deadlines).
- **Desmonta:** "la saga es una transacción distribuida" · "compensar es hacer rollback" · "con
  coreografía no hay acoplamiento" · "el orquestador es un antipatrón porque centraliza".
- **Se toca con:** `03/04`, `02/06`, y
  [`arquitectura/01-bases/02-eventos/05`](../../01-bases/02-eventos/05-saga.md),
  dueño del razonamiento.

## `03/04` — Outbox, inbox e idempotencia

- **Objetivo:** escribir el outbox y el consumidor idempotente del sistema de ejemplo, con su tabla,
  su índice y su proceso.
- **Cubre:** el problema de la **doble escritura**, con la ventana exacta donde se pierde el evento ·
  **transactional outbox**: la tabla (`outbox_events`), qué columnas tiene y por qué cada una, la
  escritura en la misma transacción, el publicador y sus dos formas (sondeo con marca de leído frente
  a CDC) · **CDC** con Debezium leyendo el log de la base de datos: qué compra —no tocas el código de
  escritura— y qué cuesta —un componente más, acoplamiento al esquema físico, el orden y las
  migraciones— · **inbox** y deduplicación en el consumidor: la tabla de mensajes procesados, la
  clave, la ventana de retención · **idempotencia** de verdad: clave natural, clave de idempotencia
  provista por el cliente, operación conmutativa, y dónde vive el registro · `Idempotency-Key` en
  HTTP entre servicios · el orden de los eventos y qué lo rompe (varias particiones, reintentos,
  paralelismo del consumidor) · por qué **al-menos-una-vez + idempotencia** es el único diseño que
  aguanta, y cómo se dice eso en una entrevista.
- **🧰 Plataformas:** tabla de qué te da cada ecosistema hecho: los módulos que traen outbox en el
  mundo Java, el patrón a mano en Node/TS, Watermill y sus componentes en Go, y las herramientas de
  Python. Debezium se nombra como pieza externa, igual para las cuatro. Código de Java (tabla +
  publicador) y de Python (consumidor idempotente).
- **Desmonta:** "el broker garantiza que el mensaje llega una vez" · "publicamos el evento después de
  hacer commit, es suficiente" · "idempotente significa que no falla si lo repites" · "con CDC ya no
  necesitas outbox" (matizado: a veces sí, a veces no, y se dice cuándo).
- **Se toca con:** `03/03`, `02/06`, `04/03`.

## `03/05` — Evolución de esquema y migraciones

- **Objetivo:** desplegar un cambio de esquema sin downtime y sin coordinar despliegues entre
  servicios.
- **Cubre:** por qué la migración es el punto donde los microservicios dejan de ser independientes si
  no se hace bien · **expand/contract** paso a paso sobre una columna que se renombra, con los
  despliegues intermedios dibujados · migraciones compatibles hacia atrás como regla dura: el código
  viejo y el nuevo conviven durante el rolling update · **backfill** de datos grandes: por lotes, con
  reanudación, sin bloquear · la migración que **no** se puede hacer así y qué se negocia entonces ·
  quién corre la migración: el arranque de la aplicación, un job aparte, o el pipeline — con el
  veredicto · el bloqueo de esquema y por qué un `ALTER` inocente para la tabla en producción ·
  versionar los datos duplicados en otros servicios cuando cambia su origen · el caso bancario: la
  ventana de mantenimiento como recurso legítimo cuando el negocio la concede.
- **🧰 Plataformas:** tabla de herramientas de migración y **de dónde se ejecutan** por ecosistema:
  las de Java integradas en el arranque, las de Prisma y TypeORM en Node/TS, las de Go como binario
  aparte, Alembic en Python. La comparación útil es el acoplamiento entre migración y despliegue.
- **Desmonta:** "la migración corre al arrancar y ya" · "renombrar una columna es un cambio menor" ·
  "paramos cinco minutos y migramos" · "cada servicio migra cuando quiere, son independientes".
- **Se toca con:** `03/01`, `04/06`, `01/03`.

## `03/06` — Simulación de entrevista

Sigue §7.2. **Escenarios obligatorios:** diseñar la saga de un flujo nuevo con sus compensaciones; y
un incidente de eventos duplicados que hay que diagnosticar y corregir.

## `03/07` — Respuestas

Solucionario del bloque.

---

# 6. 🛠️ Bloque `04` — Operación y resiliencia

**Qué hace el bloque:** lo que hay alrededor del servicio y sin lo cual no sobrevive a producción.
Es el bloque con más frontera hacia otros corpus, y cada capítulo la declara en su encabezado.

## `04/01` — Descubrimiento y enrutamiento

- **Objetivo:** explicar cómo un servicio encuentra a otro, en la plataforma que sea, y por qué hoy
  casi nunca lo resuelve la aplicación.
- **Cubre:** el problema: direcciones que cambian en cada despliegue y en cada escalado ·
  **descubrimiento del lado del cliente** (registro + cliente que consulta y balancea) frente a **del
  lado del servidor** (el cliente llama a un nombre estable y otro decide) · el registro de servicios,
  el latido y la ventana en que el registro miente · **DNS** y sus trampas: TTL, caché del resolvedor,
  la JVM que cachea para siempre si nadie la configura · **Kubernetes** como implementación
  dominante: `Service`, `Endpoints`, DNS interno, `headless` cuando el cliente quiere balancear él ·
  balanceo: round-robin, menos conexiones, aleatorio de dos, y por qué con HTTP/2 y gRPC el balanceo
  por conexión no reparte · el nombre lógico como contrato y por qué no se codifica una IP nunca ·
  📝 el arco histórico: del registro en la aplicación a la plataforma, y qué queda de Spring Cloud
  Netflix.
- **🧰 Plataformas:** tabla del cliente balanceado por ecosistema y de la caché de DNS por runtime
  —que es el detalle que muerde y es distinto en las cuatro—. Sin bloques de código: la
  configuración es de plataforma, no de lenguaje, y se remite a los corpus de nube.
- **Desmonta:** "el descubrimiento lo hace Eureka" · "Kubernetes balancea las llamadas gRPC" · "el
  DNS ya resuelve el balanceo" · "el registro sabe qué instancias están vivas".
- **Se toca con:** `02/03`, `04/05`, y los corpus de
  [AWS](../../../cloud/01-aws/) y [GCP](../../../cloud/02-gcp/) para la
  implementación gestionada.

## `04/02` — API gateway y BFF

- **Objetivo:** decir qué va en el borde y qué no, y defender un BFF sin que suene a capa extra
  gratuita.
- **Cubre:** qué resuelve un gateway: punto único de entrada, TLS, autenticación, límite de tasa,
  enrutamiento, agregación ligera, observabilidad del borde · qué **no** va nunca en el gateway:
  lógica de negocio, transformación que conoce el dominio, orquestación de sagas — el ESB
  rebautizado de `01/04` · **BFF**: uno por experiencia de cliente (web, móvil, socio), quién lo posee
  —el equipo de frontend— y por qué eso es el punto, no la tecnología · gateway frente a BFF frente a
  agregador: las tres no son lo mismo y se confunden siempre · autenticación en el borde y
  propagación de identidad hacia adentro, remitiendo a
  [`arquitectura/01-bases/04-seguridad/04`](../../01-bases/04-seguridad/04-propagacion-de-identidad.md)
  · límite de tasa: dónde se aplica, por quién, y qué devuelve · el gateway como punto único de fallo
  y qué se hace al respecto · el coste: un salto más, un equipo dueño, y una cola de peticiones de
  cambio si se centraliza mal.
- **🧰 Plataformas:** tabla de gateways y de cuándo el BFF se escribe en cada plataforma —el BFF
  suele ser Node/TS por cercanía con el frontend, y eso merece su explicación—. Se nombran los
  gateways gestionados y los de código abierto, marcando cuál es librería y cuál es producto.
- **Desmonta:** "el gateway es un balanceador" · "el BFF es una capa extra innecesaria" · "ponemos la
  validación de negocio en el gateway para no repetirla" · "con el gateway ya tenemos seguridad".
- **Se toca con:** `02/02`, `03/02`, `04/03`.

## `04/03` — Resiliencia en la práctica

- **Objetivo:** configurar timeouts, reintentos y circuit breaker con números defendibles, y explicar
  la cascada que evitan.
- **Cubre:** **timeout** como la pieza número uno: de conexión y de lectura, cómo se elige desde el
  p99 del dependiente, y el presupuesto de latencia repartido por la cadena · **reintento**: solo
  para lo idempotente, con backoff exponencial y **jitter**, con presupuesto de reintentos, y la
  tormenta que provoca sin él · **circuit breaker**: los tres estados, los umbrales, qué protege de
  verdad y qué no; el reinicio simultáneo de todos los clientes · **bulkhead**: pools separados por
  dependencia, y 📝 qué cambia con virtual threads · **rate limiter** y **load shedding**: rechazar
  temprano es un acto de resiliencia · **fallback** y degradación: qué es un fallback honesto y qué
  es esconder un fallo · **health check** bien diseñado y la diferencia entre liveness y readiness ·
  la **cadena de fallo** completa en diagrama: dependencia lenta → hilos ocupados → cola llena →
  timeouts aguas arriba → caída · la autopsia de un incidente real siguiendo §9.4 · qué se configura
  en el código y qué se delega al mesh, anticipando `04/05`.
- **🧰 Plataformas:** sección grande, la comparativa insignia del corpus. Tabla de las cuatro con
  librería, granularidad y **dónde vive el estado del circuit breaker** —por proceso en las cuatro, lo
  que cambia el comportamiento al escalar y casi nadie lo dice—. Código de Java (declarativo) y de Go
  (explícito) para que se vea el contraste completo.
- **Desmonta:** "el circuit breaker evita la caída en cascada" · "reintentamos tres veces por si
  acaso" · "el timeout por defecto está bien" · "con el mesh ya no necesitas resiliencia en el
  código".
- **Se toca con:** `02/02`, `04/05`, y
  [`arquitectura/01-bases/01-bases/09`](../../01-bases/01-bases/09-resiliencia.md).

## `04/04` — Observabilidad y trazas

- **Objetivo:** diagnosticar una latencia que aparece en producción y no se reproduce, usando trazas,
  métricas y logs correlacionados.
- **Cubre:** por qué en microservicios el stack trace ya no basta · los tres pilares y **qué
  pregunta responde cada uno**, que es la forma útil de recordarlos · **OpenTelemetry** como estándar:
  API, SDK, colector, y por qué el colector desacopla el vendedor · **traza, span, contexto**, y la
  propagación con `traceparent` de W3C · **dónde se pierde el contexto**, que es el contenido
  valioso: al cruzar a un pool de hilos, al publicar en un broker si no se inyecta en los
  encabezados del mensaje, al entrar en código asíncrono sin el mecanismo de su plataforma · logs
  estructurados con identificador de correlación y por qué el texto plano ya no sirve · métricas:
  RED para servicios, USE para recursos; percentiles y por qué la media miente · **muestreo**: por
  cabeza, por cola, y qué pierdes con cada uno · SLI, SLO y presupuesto de error, lo justo para
  hablarlo en una entrevista · el coste real de la observabilidad, que es de los mayores del sistema.
- **🧰 Plataformas:** tabla de instrumentación: agente automático frente a instrumentación manual en
  cada una, y **el mecanismo de propagación de contexto de cada runtime** —`ThreadLocal` y sus
  límites, `AsyncLocalStorage`, `context.Context`, `contextvars`—. Código de Node/TS y de Go: son
  donde el contexto se pierde de formas más instructivas; **el capítulo declara por qué no hay bloque
  de Java** (§5.3 de la guía), cuyo caso —el `ThreadLocal` que no cruza a un pool— se cuenta en prosa
  y en su fila.
- **Desmonta:** "con logs centralizados ya tienes observabilidad" · "el tracing lo pone el agente
  solo" · "medimos la latencia media" · "muestreamos al 1 % y vemos todo igual".
- **Se toca con:** `01/05`, `04/03`, `04/05`.

## `04/05` — Service mesh y sidecar

- **Objetivo:** decidir si un mesh compensa, y decir exactamente qué se mueve fuera del código.
- **Cubre:** el patrón **sidecar** y por qué existe: lo transversal se saca del proceso sin
  reescribirlo en cuatro lenguajes — que es **el argumento fuerte del mesh en un sistema políglota**,
  y por eso este capítulo vive en este corpus · plano de datos y plano de control · qué mueve el mesh:
  mTLS automático, reintentos y timeouts, circuit breaker, balanceo fino, tráfico dividido para canary,
  métricas y trazas uniformes · qué **no** mueve: la idempotencia, la semántica del reintento, el
  contrato, el dominio · **la doble configuración**: el reintento en el mesh y el reintento en la
  librería multiplican, y el diagnóstico de ese caso · el coste: latencia por salto adicional,
  memoria y CPU por instancia, un plano de control que aprender y que se cae, y una frontera nueva
  entre equipos · 📝 el modelo sin sidecar y por qué apareció · el criterio honesto: por debajo de una
  decena de servicios y con una sola plataforma, casi nunca compensa · alternativa intermedia: la
  librería compartida frente al proxy, con su tabla.
- **🧰 Plataformas:** aquí la tabla se invierte y es el mejor momento del corpus para enseñarlo: el
  mesh **iguala** las cuatro plataformas, y la comparativa es "qué te ahorra el mesh en cada una" —
  mucho en Go y Python, menos en Java, donde el ecosistema ya lo traía.
- **Desmonta:** "el mesh te da resiliencia gratis" · "con mTLS del mesh ya no hace falta autorizar" ·
  "el sidecar no añade latencia relevante" · "si tienes Kubernetes, necesitas un mesh".
- **Se toca con:** `04/03`, `04/01`, y
  [`arquitectura/01-bases/04-seguridad/05`](../../01-bases/04-seguridad/05-mtls-zero-trust-y-mesh.md),
  dueño de mTLS y zero-trust.

## `04/06` — Despliegue y entrega

- **Objetivo:** describir el pipeline de un servicio y defender una estrategia de despliegue con su
  plan de vuelta atrás.
- **Cubre:** **despliegue independiente como criterio de éxito** de toda la arquitectura: si no se
  puede desplegar uno solo, no hay microservicios · una imagen por servicio, construida una vez y
  promovida entre entornos · **rolling, blue-green, canary**, con qué hace falta para cada uno y qué
  cuesta · **feature flags** y la separación entre desplegar y activar, que es lo que de verdad
  desacopla equipos · el despliegue y la migración de esquema juntos, remitiendo a `03/05` ·
  compatibilidad durante el despliegue: dos versiones del servicio hablando con la misma cola y el
  mismo contrato · **monorepo contra polirepo**: el debate honesto, con lo que cada uno cuesta en
  CI, en refactor transversal y en propiedad · el pipeline mínimo: construir, probar, contrato,
  imagen, desplegar, verificar · versionado del servicio y trazabilidad del artefacto ·
  configuración por entorno y secretos, remitiendo a los corpus de nube.
- **🧰 Plataformas:** tabla de **empaquetado y arranque**, que es donde las cuatro difieren de
  verdad: tamaño de imagen, tiempo de arranque, memoria en reposo, compilación nativa donde existe.
  Es la tabla que sostiene la mitad del argumento de `05/06`, y se enlaza desde allí.
- **Desmonta:** "desplegamos todo junto porque es más seguro" · "canary es lo mismo que blue-green" ·
  "el monorepo acopla" · "la imagen se reconstruye en cada entorno".
- **Se toca con:** `03/05`, `04/07`, `05/01`.

## `04/07` — Testing de microservicios

- **Objetivo:** proponer una estrategia de pruebas que dé confianza sin un entorno de integración
  completo.
- **Cubre:** por qué la pirámide clásica se deforma aquí y qué la sustituye · pruebas de **unidad**
  y de **componente** (el servicio entero con sus dependencias simuladas) · pruebas de **integración**
  con dependencias reales en contenedores efímeros · **contract testing** como la pieza que evita el
  entorno completo, con Pact y con la familia del mundo Java, y quién publica y quién verifica ·
  **pruebas de extremo a extremo**: por qué se reducen al mínimo, cuáles sobreviven, y el coste real
  de mantenerlas · dobles de prueba: simulación del servidor HTTP frente al broker en contenedor ·
  datos de prueba y el problema de los datos que viven en otro servicio · pruebas en producción:
  despliegue oscuro, canary con métricas, y por qué no es una herejía · **chaos engineering** a la
  escala de un equipo normal: qué se puede probar sin herramientas caras · el test que prueba la
  idempotencia del consumidor, que casi nadie escribe.
- **🧰 Plataformas:** tabla de herramientas por ecosistema con la familia de Testcontainers, que
  existe en las cuatro y es el nivelador; simulación de HTTP y verificación de pactos en cada una.
  Código de Java y de Node/TS.
- **Desmonta:** "tenemos un entorno de integración donde probamos todo junto" · "los contract tests
  son tests de integración" · "cubrimos con end-to-end lo que no cubren los unitarios" · "no se puede
  probar un consumidor de eventos".
- **Se toca con:** `02/07`, `04/06`, `03/04`.

## `04/08` — Simulación de entrevista

Sigue §7.2. **Escenarios obligatorios:** diagnosticar una cascada de latencia con la traza delante; y
diseñar la estrategia de pruebas y despliegue de un servicio nuevo en un sistema que ya tiene ocho.

## `04/09` — Respuestas

Solucionario del bloque.

---

# 7. 🧰 Bloque `05` — Plataformas

**Qué hace el bloque:** recorre los cuatro ecosistemas de punta a punta y responde la pregunta que
ningún libro de microservicios responde: *¿qué me cuesta este patrón en mi plataforma?* **No vuelve
a explicar ningún patrón**: los enlaza a los bloques `02`–`04`. Un capítulo de este bloque que
explique qué es una saga está mal escrito.

Banda de longitud propia: **250 a 400 líneas** (§4.6 de la guía).

## `05/01` — Qué cambia entre plataformas

- **Objetivo:** enumerar los ejes en los que dos plataformas difieren de verdad, y descartar los que
  no importan.
- **Cubre:** los ejes reales: **modelo de concurrencia** (hilos, bucle de eventos, goroutines,
  corrutinas con GIL), **arranque y memoria**, **tipado y contrato**, **empaquetado y despliegue**,
  **madurez del ecosistema para cada patrón**, **propagación de contexto**, **rendimiento en el
  perfil de carga real** (E/S, no CPU) · los ejes que casi nunca importan y por qué: la velocidad
  bruta del lenguaje cuando el 95 % del tiempo es espera de red o de base de datos, y la sintaxis · la
  **tabla maestra del corpus**: patrón × plataforma, con quién te lo da hecho — se declara aquí y se
  repite reducida en `05/06` · la **baseline de versiones** del corpus, declarada y fechada · cómo
  se compara honestamente: mismo caso, mismo perfil de carga, y decir qué no mediste.
- **🧰 Plataformas:** el capítulo entero es la sección.
- **Desmonta:** "Go es más rápido, entonces es mejor para microservicios" · "Java consume mucha
  memoria" (dicho sin versión ni configuración) · "Python no sirve para producción" · "con
  TypeScript tienes seguridad de tipos en tiempo de ejecución".
- **Se toca con:** `05/06`, `04/06`, y todos los capítulos de `02`–`04` desde su tabla maestra.

## `05/02` — Java

- **Objetivo:** defender una elección dentro del ecosistema Java, y responder a "¿por qué Spring y no
  Quarkus?" sin recitar folletos.
- **Cubre:** el ecosistema: **Spring Boot** como opción por defecto y por qué lo es —la respuesta
  honesta es el ecosistema y la contratación, no la técnica—, **Quarkus** y **Micronaut** con lo que
  cambian de verdad (procesamiento en tiempo de compilación, arranque, compilación nativa), y una
  mención de las opciones más ligeras · qué trae el ecosistema para cada patrón del corpus, con enlace
  al capítulo dueño · **el modelo de ejecución**: hilo por petición, el modelo reactivo y su coste de
  legibilidad, y 📝 **virtual threads**, que cambian el argumento de bulkhead y el de reactivo · la
  **compilación nativa**: qué compra, qué cuesta y qué rompe · arranque y memoria con órdenes de
  magnitud · el mundo de las anotaciones: qué esconde el proxy y cuándo eso te muerde ·
  📝 lo que la línea actual cambió respecto de lo que el lector aprendió, remitiendo a
  [`frameworks/01-spring-boot`](../../../frameworks/01-spring-boot/), dueño del detalle de Spring.
- **Desmonta:** "Spring Boot es pesado" · "reactivo escala mejor" · "con native image arrancas en
  milisegundos y no pierdes nada" · "Quarkus es Spring pero rápido".
- **Se toca con:** `05/01`, `05/06`, y `frameworks/01-spring-boot` para todo lo que sea framework por
  dentro.

## `05/03` — Node y TypeScript

- **Objetivo:** explicar qué cambia por ser un runtime de un hilo con bucle de eventos, y elegir
  entre framework con opinión y sin ella.
- **Cubre:** el **bucle de eventos**: por qué una operación de CPU en el hilo principal tumba el
  servicio entero, y qué se hace (sacarla, `worker_threads`, otro servicio) · **NestJS** —estructura,
  inyección de dependencias, módulos, y por qué se parece a Spring a propósito— frente a **Fastify** y
  **Express** desnudos, con el criterio de elección · **tRPC** y su nicho exacto: ambos lados
  TypeScript en el mismo repositorio, y por qué no es una alternativa a gRPC entre equipos distintos ·
  **`AsyncLocalStorage`** y la propagación de contexto, que es el detalle que más se pregunta y peor
  se conoce · tipos en tiempo de compilación frente a validación en tiempo de ejecución: por qué
  `interface` no valida nada y qué hace la validación en el borde · qué trae el ecosistema para cada
  patrón, con enlaces · arranque, memoria y empaquetado · dónde este ecosistema gana de verdad: BFF,
  agregación, tiempo real.
- **Desmonta:** "Node no sirve para cargas serias" · "con TypeScript el contrato está garantizado" ·
  "NestJS es más lento que Express y por eso no lo usamos" · "async/await hace que el código sea
  concurrente".
- **Se toca con:** `04/02`, `02/05`, `05/06`.

## `05/04` — Go

- **Objetivo:** explicar por qué en Go casi todo se cablea a mano, y por qué eso es una decisión y no
  una carencia.
- **Cubre:** la filosofía: librería estándar fuerte, frameworks mínimos, dependencias contadas ·
  `net/http` como base real de producción y los enrutadores ligeros encima · **goroutines y el modelo
  de concurrencia**: barato, pero con fugas si nadie cancela · **`context.Context`**: cancelación,
  deadline y valores; se propaga por la firma de cada función, y por eso los deadlines de gRPC
  funcionan tan bien aquí — es el concepto central del capítulo · **gRPC como ciudadano de primera**
  y por qué el código generado es idiomático · errores como valores y qué significa para la
  resiliencia: no hay excepción que se propague sola hasta un manejador global · qué **no** te da el
  ecosistema y hay que escribir o traer: inyección de dependencias, circuit breaker, cliente con
  reintentos, migraciones · arranque, memoria y el binario único como ventaja operativa real ·
  dónde gana: servicios de infraestructura, alto volumen, sidecars y agentes.
- **Desmonta:** "Go no tiene frameworks porque es inmaduro" · "las goroutines son gratis" · "Go es
  más rápido, entonces todo debería ser Go" · "sin excepciones, el manejo de errores es peor".
- **Se toca con:** `02/03`, `04/03`, `05/06`.

## `05/05` — Python

- **Objetivo:** situar Python en un sistema de microservicios con honestidad: dónde brilla, dónde
  duele y qué se hace con el GIL.
- **Cubre:** el modelo de ejecución: **WSGI síncrono frente a ASGI asíncrono**, y qué implica mezclar
  código bloqueante en un manejador asíncrono —el error más común y el más caro— · el **GIL**: qué
  bloquea de verdad, por qué para trabajo de E/S importa menos de lo que dice el folclore, y 📝 qué
  está cambiando · **FastAPI** con Pydantic y la validación como contrato, frente a Django y Flask,
  con el criterio · procesos y trabajadores: el despliegue típico y por qué la memoria se multiplica
  · **Celery** y las colas de tareas, que es el patrón que Python resolvió antes que nadie ·
  qué trae el ecosistema para cada patrón del corpus, con enlaces · tipado gradual: qué garantiza y
  qué no · arranque, memoria, empaquetado y el problema de las dependencias nativas en la imagen ·
  dónde gana de verdad: servicios de datos, integración con modelos, y todo lo que ya vive en Python.
- **Desmonta:** "Python es lento y por eso no se usa en backend serio" · "el GIL impide la
  concurrencia" · "FastAPI es asíncrono, entonces todo el código es asíncrono" · "Pydantic valida en
  tiempo de compilación".
- **Se toca con:** `02/06`, `03/04`, `05/06`.

## `05/06` — La matriz de decisión

- **Objetivo:** elegir plataforma para un servicio nuevo, y responder a "¿por qué Java y no Go?" con
  criterios y sin fanatismo. Es el capítulo que más se parece a una pregunta de Tech Lead.
- **Cubre:** la **matriz patrón × plataforma** completa, con el esfuerzo relativo de implementar cada
  patrón del corpus en cada una · los criterios que deciden de verdad, en orden: **el equipo que lo
  va a mantener**, el ecosistema para el problema concreto, la operación (¿sabes desplegar y
  diagnosticar esto a las tres de la mañana?), el perfil de carga, la contratación, y muy al final el
  rendimiento bruto · **poliglotismo**: cuándo es una ventaja real —el servicio de datos en Python, el
  sidecar en Go, el BFF en TypeScript— y cuándo es deuda que se paga en herramientas duplicadas,
  observabilidad desigual y gente que no puede ayudar en el servicio de al lado · la política de
  poliglotismo como decisión de organización: qué plataformas se sostienen y quién decide añadir una ·
  el **service template** por plataforma como requisito para permitir más de una · cómo se dice todo
  esto en una entrevista sin sonar dogmático, con las frases listas · el caso bancario: por qué la
  respuesta ahí suele ser "una plataforma principal y excepciones justificadas".
- **Desmonta:** "elegimos el mejor lenguaje para cada problema" · "poliglota es una ventaja de los
  microservicios" · "cambiamos de plataforma por rendimiento" · "el lenguaje da igual, lo importante
  es la arquitectura".
- **Se toca con:** `05/01` a `05/05`, `04/06`, `01/01`.

## `05/07` — Simulación de entrevista

Sigue §7.2. **Escenarios obligatorios:** justificar la plataforma de tres servicios nuevos con
perfiles distintos; y el caso donde alguien propone reescribir un servicio en otro lenguaje por
rendimiento y **la respuesta correcta es no hacerlo**.

## `05/08` — Respuestas

Solucionario del bloque.

---

# 8. 🚫 Qué queda fuera del corpus, y por qué

Se declara aquí para que ningún documento lo prometa y ninguna sesión lo improvise.

| Queda fuera | Por qué | Dónde está |
|---|---|---|
| La decisión monolito / microservicios, estilos de despliegue, DDD, CAP, event sourcing | Es razonamiento de arquitectura; aquí se asume tomada la decisión | [`arquitectura/01-bases`](../../01-bases/) |
| La semántica de HTTP, códigos de estado, TLS, qué obliga el RFC | Es el contrato del cable, y tiene corpus propio | [`bases/04-apis-protocolos`](../../../bases/04-apis-protocolos/) |
| Spring por dentro: contenedor, proxies, autoconfiguración, Batch, Security | Aquí Spring es una de cuatro plataformas, no el tema | [`frameworks/01-spring-boot`](../../../frameworks/01-spring-boot/) |
| Kubernetes, VPC, IAM, colas gestionadas, coste de infraestructura | Es operación de nube, con laboratorio propio | [`cloud/01-aws`](../../../cloud/01-aws/) · [`cloud/02-gcp`](../../../cloud/02-gcp/) |
| OAuth2, OIDC, JWT, mTLS como patrón, zero-trust | Es seguridad de aplicación y ya tiene bloque | [`arquitectura/01-bases/04-seguridad`](../../01-bases/04-seguridad/) |
| Serverless y FaaS como estilo | Se nombra donde compite con un servicio, pero no se desarrolla | `arquitectura/01-bases` y los corpus de nube |
| Frontend, micro-frontends | Fuera del alcance del perfil | — |
| Laboratorio en la nube, Kubernetes o mesh | Los talleres corren en local con Docker Compose; lo que necesita un orquestador se queda en los capítulos (§13.4 de la guía) | cursos de nube; `04/01`, `04/05`, `04/06` |

**La regla cuando un capítulo roza una de estas fronteras:** se explica lo mínimo para que el
capítulo se sostenga solo, se dice explícitamente que el desarrollo está en el otro corpus, y se
enlaza diciendo qué hay allí (§10.2 de la guía). Nunca se reescribe.

---

# 9. 🗺️ El `README.md` del corpus

No sigue la plantilla de capítulo (§6.3 de la guía). Lleva, en este orden:

1. **Título y blockquote** con qué es el corpus, para quién, y `Vigencia:`.
2. **"Qué es esto, y qué no"**, con el bloque `text` de tres líneas que contrasta este corpus con un
   curso de microservicios y con el corpus de arquitectura.
3. **La tabla de los cinco bloques**, con qué cubre cada uno y su estado, y una fila aparte para
   `06-talleres/`, declarado opcional.
4. **La aportación propia**: el eje de las cuatro plataformas, explicado en un párrafo, y **por qué
   no hay JavaScript**.
5. **La baseline de versiones**, con su fecha.
6. **Cómo está construido cada bloque**: el bloque `text` con los tres tipos de documento y el de las
   tres capas de respuesta.
7. **Las reglas del corpus** en cinco o seis viñetas, enlazando a la guía de estilo.
8. **Relación con el resto del repositorio**, con la tabla de §8 de este documento en versión corta.
9. **La frontera de privacidad**: este corpus está pensado para publicarse y no cita `Entrevistas/`.

---

# 10. 🧪 Bloque `06` — Talleres

**Qué hace el bloque:** lleva el sistema de ejemplo de un monolito a servicios, en local, y provoca
los fallos que los capítulos describen. Es **opcional**: el corpus teórico se sostiene sin él. Las
reglas de forma están en §13 y §14 de la guía.

**El caso de estudio** es el del bloque de talleres del curso hexagonal —misma tienda, mismos
productos semilla, misma regla determinista de pago—, **copiado y redeclarado** en §14 de la guía,
no enlazado: si mañana cambia la semilla de hexagonal, este bloque no se entera. Nada exige haber
hecho aquel curso.

**El monolito de partida, `ms-monolith`**, es una aplicación Spring Boot sobre una sola base
PostgreSQL, **escrita como se escribe un monolito típico, no como uno ejemplar**. Sus defectos están
puestos a propósito, y cada uno es el material de un taller:

| Defecto a propósito | Qué taller lo desarma |
|---|---|
| Un `@Transactional` que crea el pedido, descuenta stock y autoriza el pago de una vez | `08` y `09`: la saga es "cómo vivo sin esa transacción" |
| Un `JOIN` de `orders` contra las tablas de `inventory` | `02`: base de datos por servicio |
| El proveedor de pago llamado **dentro** de la transacción de base de datos | `01` lo provoca, `03` lo saca |
| La notificación de cancelación escrita en la misma transacción que el cambio de estado | `06`: el outbox |

**El sistema al final de la serie:**

```text
                         ┌──────────────┐
      cliente (hurl) ───►│ api-gateway  │  Envoy: rutas, JWT, timeouts
                         └──────┬───────┘
          ┌─────────────────────┼─────────────────────┐
     ┌────▼─────┐         ┌─────▼──────┐        ┌─────▼──────┐
     │  orders  │ ─gRPC──►│ inventory  │        │ ms-monolith│  catalog + customers
     │  (Java)  │         │    (Go)    │        │   (Java)   │  (lo que queda dentro)
     └────┬─────┘         └─────▲──────┘        └────────────┘
          │ outbox                │
          ▼                       │
     ┌─────────────────── Kafka ──┴───────────────────┐
     │ orders.placed · inventory.reservations ·       │
     │ payments.results · *.dlq                       │
     └─────────────────────┬──────────────────────────┘
                     ┌─────▼──────┐        ┌──────────────┐
                     │  payments  │ ─HTTP─►│ psp-simulator│  regla determinista
                     │  (Python)  │        └──────────────┘
                     └────────────┘
```

**Orden de extracción:** `inventory` primero (frontera más clara, la que más sufre el `JOIN`
compartido); `payments` segundo (corta por cumplimiento y habla con el tercero lento); `orders`
tercero (es el corazón). `catalog` y `customers` se quedan dentro: el strangler nunca termina, y lo
que se queda también es una decisión.

**Decisiones cerradas del bloque** (sesión de diseño del 2026-09-27, abiertas cerradas el
2026-09-29): Kafka en KRaft de un nodo; Envoy como gateway, solo configuración, y **Envoy valida el
JWT** (`jwt_authn`), así que los servicios reciben la identidad ya resuelta; resiliencia desde la
primera llamada remota; observabilidad antes de las sagas y después de Kafka, con el collector de
OpenTelemetry desde `07` (antes, correlación por `traceparent` en los logs); la máquina de estados
del orquestador en una **tabla propia** de `orders`, no en una librería; las librerías de Kafka,
breaker y OpenTelemetry de Go y Python se eligen en su tanda, comprobadas en el registro; backend de
trazas en una imagen todo en uno; `catalog` no se extrae en ningún taller (ejercicio 🟠 de `02`);
contrato `v2` con `202 Accepted` para la saga asíncrona.

## `06/01` — El monolito y su contrato

- **Objetivo:** "Antes de tocar un monolito, fijo su contrato con una suite que el cliente no pueda
  distinguir de la realidad."
- **Construye:** `ms-monolith`, `openapi.yaml`, suite `hurl/v1`, compose base (PostgreSQL,
  Toxiproxy, mock del contrato) y `lab.py`.
- **Fallo provocado:** `lab.py psp-slow` mete latencia en el proveedor de pago, y el `@Transactional`
  que lo llama agota el pool de conexiones y tumba también el catálogo, que no tenía nada que ver.
- **Evidencia:** suite `v1` en verde contra el mock (donde el mock puede) y contra el monolito.
- **Capítulos:** `01/01`, `01/05`, `02/07`.

## `06/02` — Strangler fig con Envoy

- **Objetivo:** "Extraigo un servicio sin que el cliente se entere, y sé por qué primero comparto la
  base y después no."
- **Enseña:** el corte en papel; Envoy delante con el 100 % hacia el monolito; *branch by abstraction*
  (la interfaz `Inventory` con implementación local o remota); `inventory` en Go; la capa
  anticorrupción; la migración de datos.
- **Fallo provocado:** extraer compartiendo la base reproduce el monolito distribuido de `01/04`: un
  cambio de columna en `inventory` rompe el monolito. Después, base propia y migración. La primera
  llamada remota nace con timeout, y Toxiproxy muestra qué habría pasado sin él.
- **Evidencia:** suite `v1` en verde **a través de Envoy**; `git diff --stat` del monolito que
  muestra que solo cambió la implementación de la interfaz.
- **Capítulos:** `01/02`–`01/04`, `03/01`, `04/02`.

## `06/03` — HTTP entre servicios

- **Objetivo:** "Una llamada remota nace con timeout, reintenta solo lo idempotente y propaga la
  clave de idempotencia."
- **Enseña:** `payments` en Python extraído; el monolito lo llama por HTTP con `RestClient`; timeout,
  reintento con jitter solo sobre lo idempotente, `Idempotency-Key` propagada, `problem+json` entre
  servicios, circuit breaker básico en Java.
- **Fallo provocado:** un reintento sobre `POST` sin clave **cobra dos veces**; con la clave, el
  `psp-simulator` devuelve la respuesta repetida.
- **Evidencia:** suite `v1` en verde; un solo cobro por intento en el registro del simulador.
- **Capítulos:** `02/01`, `02/02`, `04/03` §2–§4.

## `06/04` — gRPC

- **Objetivo:** "El `.proto` es el contrato, el deadline viaja con la llamada y un cambio
  incompatible lo caza una herramienta antes del despliegue."
- **Enseña:** `inventory` expone su `.proto`; `orders` (Java) y un cliente Python lo consumen;
  deadlines y su propagación, mapeo de status codes a `problem+json`, metadata de idempotencia.
  `orders` sale del monolito en este taller.
- **Fallo provocado:** un deadline que no se propaga deja a `inventory` trabajando para nadie;
  renumerar un campo lo caza `buf breaking`.
- **Medición honesta:** la misma reserva por HTTP y por gRPC, etiquetada "reproducción local, un solo
  nodo, sin red real", con lo que **no** mide.
- **Evidencia:** suite `v1` en verde con `orders` fuera del monolito.
- **Capítulos:** `02/03`, `02/04`, `02/07`.

## `06/05` — Resiliencia en tres plataformas

- **Objetivo:** "Sé dónde vive el estado del breaker en cada plataforma y por qué dos capas que
  reintentan multiplican la carga."
- **Enseña:** circuit breaker, bulkhead, límite de tasa y fallback **en Java, Go y Python** sobre las
  llamadas ya construidas; timeouts y reintentos en Envoy frente a los del código; liveness contra
  readiness.
- **Fallo provocado:** una readiness que comprueba una dependencia convierte la caída de `payments`
  en la de `orders`; reintentos en Envoy **y** en el cliente multiplican la carga.
- **Evidencia:** transiciones del breaker con Toxiproxy cortando y restaurando; suite `v1` en verde
  tras la recuperación.
- **Capítulos:** `04/03`, `04/01`.

## `06/06` — Kafka: outbox, inbox, idempotencia y DLQ

- **Objetivo:** "El evento sale si el pedido se confirmó, llega al menos una vez y el consumidor lo
  aplica una sola."
- **Enseña:** outbox en `orders` (`outbox_events` y publicador), consumidores idempotentes en Go y en
  Python con `processed_messages`, partición por `orderId`, commit del offset **después** del efecto,
  DLQ, evolución compatible del esquema del evento.
- **Fallo provocado:** matar el consumidor entre el efecto y el commit produce una entrega duplicada
  que **reserva dos veces**; el inbox lo corrige. Publicar fuera de la transacción pierde un evento.
- **Evidencia:** conteo de reservas igual al de pedidos tras la caída; mensaje venenoso en la `.dlq`.
- **Capítulos:** `02/06`, `03/04`, `03/05`.

## `06/07` — Observabilidad de extremo a extremo

- **Objetivo:** "Una traza cruza HTTP, gRPC y Kafka, y sé en qué runtime se corta y por qué."
- **Enseña:** OpenTelemetry en las tres plataformas con collector y backend local; logs
  correlacionados por `trace_id`; qué instrumenta solo el agente de Java y qué hay que escribir en Go.
- **Fallo provocado:** la traza **se corta en Kafka** porque `traceparent` no viaja en el mensaje; se
  corrige en el productor y en los consumidores.
- **Evidencia:** la traza completa con sus spans, en texto.
- **Capítulos:** `04/04`.

## `06/08` — Saga coreografiada

- **Objetivo:** "Puedo montar una saga sin dueño y explicar por qué nadie sabe en qué estado está el
  pedido."
- **Enseña:** contrato `v2` (§13.2 de la guía). `OrderPlaced` → `inventory` reserva → `payments`
  autoriza → `PaymentRejected` dispara la liberación de stock. Nadie manda: cada servicio reacciona.
- **Fallo provocado:** "¿en qué estado está este pedido?" **no tiene dónde contestarse**; un ciclo de
  eventos introducido a propósito.
- **Evidencia:** suite `v2` en verde en las tres ramas (feliz, sin stock, pago rechazado).
- **Capítulos:** `03/03` §1–§3 y §6–§7.

## `06/09` — Saga orquestada, comparación y autopsia

- **Objetivo:** "Sé cuándo la secuencia necesita dueño y cuándo quiero sumar consumidores sin tocar a
  nadie, y lo demuestro con el número de servicios que cambia."
- **Enseña:** el mismo flujo con `orders` como orquestador y la máquina de estados en tabla propia;
  comandos `ReserveInventory`, `AuthorizePayment`, `ReleaseInventory`; pago incierto (`666.00`) que se
  reintenta con la misma clave y no se compensa a ciegas; la autopsia de `03/03` §9 reproducida
  (compensación que no llega → stock bloqueado → expiración de la reserva).
- **Cierre:** tres cambios de negocio sobre las dos sagas —un paso en medio (antifraude), un
  consumidor al final (fidelidad) y un fallo que exige decidir (`666.00`)—; `fraud` y `loyalty` son
  stubs mínimos en Python sin base propia. La evidencia es el `git diff --stat` de cada cambio: el
  número de servicios tocados.
- **🔥 Fuera del conteo:** la misma saga en Temporal, en una línea de veredicto y sin laboratorio.
- **Capítulos:** `03/03` completo.

## `06/10` — Contratos entre servicios y testing (opcional; requiere `03`, `04` y `06`)

- **Objetivo:** "Sé qué rompe un cambio que la suite de extremo a extremo no ve, y quién lo detecta."
- **Enseña:** consumer-driven contracts entre Java, Go y Python sobre HTTP y sobre eventos; qué cubre
  la suite `hurl` y qué no; Testcontainers; la pirámide de `04/07` en un sistema real.
- **Fallo provocado:** un cambio en `payments` que la suite no detecta y el contrato del consumidor sí.
- **Capítulos:** `02/07`, `04/07`.

## `06/11` — Consultas entre servicios y tiempo real (opcional; requiere `06` y `08`)

- **Objetivo:** "Sé cuándo componer en la API y cuándo mantener un read model, y qué pasa cuando se
  desfasa."
- **Enseña:** la vista "mis pedidos con su estado de pago" por composición y por read model
  alimentado por eventos; el seguimiento del pedido por SSE.
- **Fallo provocado:** el read model desfasado tras reprocesar desde el offset 0 sin idempotencia.
- **Capítulos:** `03/02`, `02/05`.

## `06/12` — Respuestas

Solucionario único del bloque: preguntas y ejercicios de los once talleres, enunciado literal y tres
capas (§8.3 de la guía).

## `06-talleres/README.md`

Mapa del bloque, dependencias, "todo aquí es opcional", la ruta corta para la semana de la
entrevista (`01 → 02 → 06 → 08 → 09`, con su precio: sagas sin breaker ni traza) y una prueba de
humo con desglose.

