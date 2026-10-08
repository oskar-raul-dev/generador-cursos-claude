# ✍️ Guía de estilo, tono y convenciones

## Arquitectura monolítica y monolito distribuido — repaso para entrevistas de Backend Senior, Tech Lead y Arquitecto

Esta guía es la fuente de verdad editorial de `02-monolito/`. Manda sobre los cinco bloques
teóricos, sobre el bloque **opcional** de talleres `06-talleres/` (§11 y §12) y sobre cualquier
documento que se añada después. El objetivo no es que el lector pueda repetir que «un monolito se
despliega junto»: es que pueda **identificar unidades de cambio, proteger límites internos y decidir
cuándo distribuir aporta autonomía o solo fallos de red**.

Hasta el 2026-09-28 el corpus era solo teórico. El 2026-09-29 se decidió añadirle un laboratorio
opcional con el mismo caso de estudio que los talleres de `03-hexagonal/` y
`04-microservicios/`, y alinear con ellos la regla de idioma del código (§3). El registro de esa
sesión de diseño es `plan-taller.md`, en la raíz del corpus; lo que decidió está trasladado aquí y a
`prompt-base.md` §9, que mandan sobre él. El curso quedó completo y revisado el 2026-09-29.

> **Vigencia:** 2026-09-29.

**Salto rápido:** [1](#1--principio-rector) · [2](#2--tono) · [3](#3-️-idioma-y-forma) · [4](#4--pedagogía) · [5](#5--sistema-de-ejemplo) · [6](#6--eje-de-plataformas) · [7](#7--plantilla-del-capítulo-nn-temamd) · [8](#8-️-tipos-de-documento) · [9](#9--preguntas-y-dificultad) · [10](#10--referencias-y-coherencia) · [11](#11--bloque-06--talleres) · [12](#12--nombres-fijos-del-laboratorio) · [13](#13--checklist-de-cierre)

---

## 1. 🧭 Principio rector

**Todo párrafo debe ayudar a decidir qué permanece unido, qué necesita un límite, qué garantía se
conserva o qué coste aparece al distribuir.** Si no hace una de esas cuatro cosas, sobra.

```text
Un tutorial de framework  → te enseña módulos, anotaciones y comandos.
Una defensa del monolito  → intenta demostrar que una topología siempre gana.
Este repaso               → te enseña a reconocer unidades de cambio,
                            medir acoplamiento y defender una evolución proporcional.
```

La regla se formula sin misticismo: «monolito» describe primero una unidad de despliegue y
operación, no la calidad del código. Un monolito puede estar bien modularizado o ser un *big ball of
mud*. Un sistema puede estar distribuido en varios procesos y conservar dependencias de cambio,
datos y despliegue tan fuertes que opere como un monolito distribuido.

Cada decisión se evalúa con cinco monedas:

| Moneda | Pregunta que obliga a responder |
|---|---|
| Código | ¿Qué debe modificarse y compilarse junto? |
| Datos | ¿Quién posee el estado y qué puede confirmar atómicamente? |
| Despliegue | ¿Qué componentes deben versionarse o liberarse coordinadamente? |
| Runtime | ¿Qué debe estar disponible para completar la operación? |
| Equipos | ¿Quién decide, cambia y opera cada capacidad? |

No se dice «está acoplado» ni «añade complejidad» sin indicar en cuál moneda, qué evidencia lo
demuestra y quién paga el coste. Tampoco se prescribe distribuir por tamaño: la autonomía obtenida
debe compensar contratos remotos, consistencia eventual, observabilidad y fallos parciales.

### 1.1 Qué queda fuera

- No es una introducción a programación backend, HTTP, SQL, concurrencia ni mensajería. Se explican
  solo hasta donde afectan límites, garantías y operación.
- No es DDD completo. Capacidades, contextos acotados y lenguaje compartido aparecen para descubrir
  módulos y propietarios, no para cubrir todo el catálogo táctico.
- No es un curso completo de microservicios. Los servicios aparecen como alternativa, destino de
  extracción o fuente de acoplamiento distribuido.
- No es un curso de Spring, NestJS, Go o FastAPI. Las plataformas aportan evidencia comparativa, no
  dictan la arquitectura. Tampoco lo son los talleres, aunque corran sobre Spring Boot: explican la
  decisión, no el framework (§11.4).
- No es un laboratorio de nube. Los talleres corren en local con Docker Compose; despliegue real,
  Kubernetes y secretos gestionados viven en los cursos de AWS, GCP y Azure.
- No promete que un monolito modular resuelva límites de negocio incorrectos, ownership difuso o
  mala disciplina de despliegue. Puede hacerlos visibles y controlables; no los elimina por nombre.

---

## 2. 🎤 Tono

- **Español latinoamericano neutro y tuteo.** Cercano, preciso y sin tono de manual corporativo.
- **Sin defensa tribal.** Monolitos y servicios se comparan por restricciones y garantías, no como
  etapas inferiores y superiores de madurez.
- **Honesto con la distribución.** Separar un proceso puede habilitar autonomía y escalado selectivo;
  también añade red, contratos, datos repartidos y estados inciertos. Se nombran ambos lados.
- **Sin absolutos falsos.** Una base compartida no convierte por sí sola un sistema en monolito
  distribuido; una llamada síncrona tampoco. El diagnóstico exige varias evidencias relacionadas.
- **Proporcional.** Un equipo pequeño con un dominio joven puede necesitar un despliegue y límites
  simples. La respuesta madura puede ser «mantenerlo unido por ahora».
- **Sin guerra de lenguajes.** Cada plataforma recibe detalle donde sus mecanismos alteran el coste;
  ninguna se presenta como arquitectura incorporada.
- **Un solo desdramatizador seco por documento, como máximo.** Esto es material de entrevista, no
  una conversación de chat.

---

## 3. 🗣️ Idioma y forma

- Los términos establecidos se conservan en inglés cuando traducirlos pierda precisión: *modular
  monolith*, *big ball of mud*, *bounded context*, *shared kernel*, *lockstep deployment*, *strangler
  fig* y *branch by abstraction*. La primera aparición incluye una explicación breve.
- Se usa **monolito distribuido**, sin tilde en «distribuido». No se alterna con «microservicios
  acoplados» si no se ha demostrado ese diagnóstico.
- **Código en inglés, comentarios del código en español.** Todo lo ejecutable o versionado va en
  inglés: identificadores, paquetes y módulos, rutas HTTP, tablas y columnas, claves JSON, variables
  de entorno, contenedores, mensajes de excepción y datos semilla. Los comentarios dentro del
  código, incluidos los de un `docker-compose.yml` o un `.hurl`, van en español con tildes. La API
  es `/orders`, nunca `/pedidos`.
- **Un solo nombre canónico por concepto, y es el del código.** La prosa habla en español («el
  módulo de pedidos», «la reserva»), pero cuando nombra un identificador usa el del código, en
  backticks:

  | En la prosa | Identificador canónico | Aparece como |
  |---|---|---|
  | módulo de pedidos | `orders` | paquete o módulo; agregado `Order` |
  | módulo de inventario | `inventory` | paquete o módulo; `InventoryReservation`, `InsufficientInventory` |
  | módulo de pagos | `payments` | paquete o módulo; `PaymentGateway`, `PaymentResult` |
  | módulo de notificaciones | `notifications` | paquete o módulo; `Notification` |
  | crear pedido | `CreateOrder` | caso de uso; evento `OrderCreated` |
  | reservar inventario | `ReserveInventory` | operación de `inventory`; evento `InventoryReserved` |
  | autorizar pago | `AuthorizePayment` | caso de uso |
  | notificar al cliente | `NotifyCustomer` | operación de `notifications` |
  | cancelar pedido | `CancelOrder` | caso de uso; evento `OrderCancelled` |

  No se escribe `CrearPedido`, `Pedidos` como identificador ni `PedidoRepository` en ningún
  documento. **Divergencia declarada:** hasta el 2026-09-29 este corpus nombraba el dominio en
  español (`Pedidos`, `CrearPedido`), como `arquitectura/01-bases`. Se cambió para alinearlo con los
  cursos hexagonal y de microservicios, que comparten el caso de estudio, y porque el laboratorio
  ejecuta código, donde manda el `CLAUDE.md` del repositorio. La migración del corpus ya escrito se
  cerró el 2026-09-29; un identificador en español que aparezca después es un error, no una
  excepción.
- Markdown, nunca HTML. Código pequeño, completo y con nombres del sistema de ejemplo.
- La prioridad visual es: diagrama ASCII → tabla de decisión → lista → prosa. La prosa explica el
  porqué; una tabla no sustituye el razonamiento.
- Los diagramas usan bloques `text`, límites claros y flechas con significado. Por ejemplo:

  ```text
  despliegue único
  ┌────────────────────────────────────────────┐
  │ orders ──► inventory ──► payments          │
  │    │           │             │             │
  │    └──── APIs internas y datos propios ────┘
  └────────────────────────────────────────────┘
  ```

- Se diferencia siempre dependencia de código, flujo de ejecución y dependencia operativa. Una
  flecha ambigua debe llevar etiqueta o explicarse inmediatamente.
- Las tablas comparan dimensiones. Tres o cuatro columnas es la norma; no se usan para narrar.
- Un emoji funcional en encabezados `##`; ninguno en `###`. Los encabezados respetan jerarquía real.

---

## 4. 🧱 Pedagogía

Se explica «como para un bebé» en el único sentido útil: sin saltos de razonamiento y sin perder
profundidad. El andamio fijo es:

1. El síntoma concreto: qué cambio, despliegue o incidente duele.
2. La unidad afectada: código, datos, despliegue, runtime o equipo.
3. El límite y la garantía: qué debe permanecer unido y qué necesita independencia.
4. El mecanismo: módulo, API interna, transacción, evento, prueba o paso de migración.
5. El precio: qué coordinación, latencia, duplicación o carga operativa aparece.
6. El veredicto: cuándo aplicarlo, cuándo detenerse y qué evidencia revisar.

Cada patrón se muestra con un flujo completo. No se presentan paquetes vacíos, eventos sin
consumidor ni servicios dibujados sin propiedad de datos. Las comparaciones parten del mismo caso y
cambian una restricción a la vez.

### 4.1 Diagnóstico responsable del monolito distribuido

No se etiqueta por intuición. El capítulo debe buscar evidencia combinada:

```text
cambio pequeño
   ├─► modifica varios componentes
   ├─► exige contratos y despliegues coordinados
   ├─► cruza datos sin propietario claro
   ├─► necesita una cadena runtime completa
   └─► obliga a varios equipos a decidir al mismo tiempo
```

Una señal aislada puede ser una decisión consciente. Varias señales recurrentes, sin autonomía
compensatoria, sostienen el diagnóstico. Siempre se distingue causa, síntoma y consecuencia.

### 4.2 Errores que se desmontan siempre

- «Monolito significa código desordenado».
- «Un monolito no puede escalar horizontalmente».
- «Una carpeta por dominio crea un monolito modular».
- «Una tabla por módulo garantiza propiedad de datos».
- «Si hay varios contenedores, ya son microservicios».
- «Toda llamada síncrona crea un monolito distribuido».
- «Los eventos desacoplan automáticamente».
- «Extraer un servicio reduce el acoplamiento por definición».
- «Microservicios son el siguiente paso natural de un monolito».
- «La base compartida siempre es mala».

---

## 5. 🛒 Sistema de ejemplo

El hilo conductor es una plataforma de comercio con cuatro capacidades —pedidos, inventario, pagos
y notificaciones; en código `orders`, `inventory`, `payments` y `notifications`—. Empieza como
aplicación pequeña, adquiere límites internos, sufre una separación prematura y recupera autonomía de
forma gradual.

```text
monolito simple
      │ crecen reglas y equipos
      ▼
monolito modular
      │ extracción sin ownership suficiente
      ▼
monolito distribuido
      │ contratos, datos y despliegues se corrigen
      ▼
topología proporcional a las restricciones
```

`CreateOrder`, `ReserveInventory`, `AuthorizePayment` y `NotifyCustomer` aparecen de forma estable.
Si un ejemplo no cabe en ese sistema, se explica por qué. La historia no presupone que el estado
final deba ser distribuido: puede terminar con uno o varios despliegues según la evidencia.

Es el mismo dominio que los talleres de `03-hexagonal/` y `04-microservicios/`, pero
**redeclarado aquí y no enlazado**: si mañana cambia la semilla de otro curso, este no se entera.
Los talleres de §11 lo implementan como `mono-legacy`, un monolito escrito sin organización, y usan
los valores de §12. Los capítulos no dependen de ese código: pueden citarlo en prosa, nunca exigirlo.

---

## 6. 🧰 Eje de plataformas

El orden fijo de comparación es **Java · Node/TypeScript · Go · Python**. Cuando una comparación
aporte valor, usa estas columnas:

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|

No existe un bloque de tutoriales por lenguaje. Los mecanismos aparecen en el capítulo cuya decisión
modifican: módulos y build, transacciones, concurrencia, migraciones, pruebas arquitectónicas o
despliegue. Un bloque de código por lenguaje que solo cambia la sintaxis no enseña nada.

No se nombran librerías de memoria. Antes de publicar una herramienta se verifica nombre,
mantenimiento, compatibilidad y documentación primaria. Versiones y baseline se registran en el
capítulo que las introduzca y se enlazan después.

**Los talleres son solo Java** (Java 25 y Spring Boot 4.1.1, la misma baseline que los laboratorios
hexagonal y de microservicios). El dolor que enseñan —trabajar sin contrato, sin límites y sin
disciplina de datos— no depende del lenguaje, y un solo legado en cuatro toolchains repetiría la
lección sin añadir una idea. Su tabla 🧰 remite a los capítulos para el contraste entre plataformas,
en lugar de repetir las cuatro filas.

---

## 7. 📄 Plantilla del capítulo `NN-tema.md`

Cada capítulo, salvo los que el contrato declare conceptuales, sigue este recorrido:

```text
problema → modelo mental → evidencia y límites → diseño o secuencia
→ implementación mínima → 🧰 plataformas cuando aplique
→ ⚖️ decisión y coste → ⚠️ errores frecuentes
→ veredicto → referencias → 🧠 24–26 preguntas sin respuesta
```

- El primer párrafo dice qué decisión aprenderás a tomar.
- La sección de evidencia separa observación, inferencia y diagnóstico.
- Toda recomendación nombra al menos una garantía que conserva y un coste que introduce.
- La sección de plataformas declara explícitamente si no aplica y por qué.
- `## ⚠️ Errores frecuentes` contiene sobregeneralizaciones reales de entrevista, no consejos vagos.
- `## 🧠 Preguntas` no contiene respuestas ni pistas. Cada pregunta lleva dificultad `🟢`, `🟡` o
  `🟠` y se copia literalmente al solucionario.
- Cada capítulo termina con referencias directas y verificadas, no con URLs inventadas ni páginas
  índice cuando exista una fuente específica.

---

## 8. 🗂️ Tipos de documento

### Capítulo

Enseña una decisión concreta y contiene 24–26 preguntas. Tiene introducción, evidencia, veredicto,
referencias y navegación al siguiente documento cuando exista.

### Simulación

No repite capítulos. Incluye 30–45 preguntas transversales `S#`, un bloque «las que descolocan» y
4–6 escenarios. Cada escenario declara qué fuerza: una unidad de cambio, una garantía, un trade-off
y la prioridad que debería expresar un candidato senior.

### Taller

Documento `NN-tema.md` dentro de `06-talleres/`, con código versionado en `06-talleres/laboratorio/`.
No forma parte del recorrido teórico: ningún capítulo ni simulación depende de un taller. Su forma se
fija en §11. Lleva `## 🧠 Preguntas` (10–15) y `## 🧪 Ejercicios` graduados 🟢🟡🟠🔴, más 🔥 y 💀
fuera del conteo; las respuestas viven en `06-talleres/11-respuestas.md` con el enunciado literal.
Es el único tipo de documento del corpus que lleva ejercicios.

### Solucionario

Cada respuesta conserva el enunciado literal y usa tres capas:

```text
⏱️ 30 segundos  → diagnóstico o decisión inicial, precisa y defendible
🗣️ 2 minutos    → evidencia, alternativa, garantía y coste
🔬 El detalle    → matiz para estudiar, no para recitar
```

Los solucionarios se actualizan en la misma tanda que las preguntas. No hay respuestas inline en los
capítulos.

### README de bloque

Se escribe cuando el bloque está cerrado. Explica la decisión que entrena, enumera la ruta real y
declara qué deberías poder defender al terminar. No promete archivos futuros.

---

## 9. 🧠 Preguntas y dificultad

- `🟢`: definición precisa, reconocimiento de una unidad o lectura de un flujo sencillo.
- `🟡`: comparación, diagnóstico con evidencia o decisión con un trade-off explícito.
- `🟠`: escenario incompleto, incidente, migración, desacuerdo entre equipos o excepción que obliga
  a priorizar garantías.

La distribución varía para evitar plantillas mecánicas. Cada capítulo operativo incluye al menos dos
preguntas sobre fallo o reversibilidad. Cuando haya sección de plataformas, incluye al menos dos
preguntas que exijan comparar mecanismos, no recordar nombres de herramientas.

---

## 10. 🔗 Referencias y coherencia

- Toda URL externa se comprueba antes de escribirla y debe respaldar exactamente la afirmación.
- Se priorizan fuentes primarias: documentación oficial, artículos originales de patrones, libros o
  trabajos de sus autores y documentación de plataforma.
- Los enlaces internos solo apuntan a archivos existentes. Una dependencia futura se menciona en
  prosa, sin enlace, hasta que el destino exista.
- Un concepto tiene una definición dueña. Los capítulos vecinos lo enlazan o aplican, no lo redefinen.
- La terminología canónica es: `unidad de despliegue`, `módulo`, `límite`, `propiedad de datos`,
  `acoplamiento de cambio`, `acoplamiento temporal`, `autonomía`, `monolito modular` y `monolito
  distribuido`.
- «Servicio» se acompaña de contexto cuando pueda significar clase de aplicación, proceso desplegable
  o capacidad de negocio.
- No se infiere causalidad desde una métrica aislada. Un grafo de llamadas, una base compartida o un
  despliegue coordinado son evidencia parcial hasta relacionarlos con cambios y ownership.

---

## 11. 🧪 Bloque 06 · Talleres

El bloque `06-talleres/` implementa el sistema de ejemplo como lo encontrarías al heredarlo:
`mono-legacy`, un monolito que funciona pero se escribió **sin organización** —sin contrato, sin
límites, con los errores escondidos en un `200`—, y lo recupera paso a paso sin romper a quien lo
usa. Enseña a **palpar** el dolor que describen los capítulos y a corregirlo **dentro** del
monolito antes de proponer distribuirlo. No enseña el framework. **Todo el bloque es opcional** y
lo declara su README; cada taller lo vuelve a declarar en su primer párrafo, junto con sus
prerrequisitos.

Hay un segundo objetivo, tan importante como el primero y compartido con el laboratorio de
microservicios: el perfil senior suele tener dificultad para **tomar una base de código que no
escribió y orientarse rápido en ella**, que es exactamente lo que pide un legado. Por eso cada
taller tiene una sección fija de **recorrido de la base de código** (§11.3) y al menos un ejercicio
que se responde con ruta y línea.

### 11.1 Inventario y dependencias

```text
06-talleres/
├── README.md                                   mapa, dependencias, recorridos y "todo aquí es opcional"
├── 01-heredar-el-legado.md                     mono-legacy, compose, semilla, lab.py; arqueología sin documentación
├── 02-los-errores-escondidos.md                200 con error, 500 con traza; frontend opcional que se rompe
├── 03-caracterizacion.md                       hurl/legacy: golden master del comportamiento actual
├── 04-el-contrato.md                           openapi.yaml desde lo observado; problem+json; hurl/v1
├── 05-sqlite-miente.md                         pruebas verdes en SQLite y rojas en PostgreSQL; Testcontainers
├── 06-modularizar.md                           de paquete por capa a paquete por capacidad; ArchUnit y Spring Modulith
├── 07-transacciones-y-concurrencia.md          proveedor fuera de la transacción; sobreventa; idempotencia
├── 08-eventos-jobs-y-dos-instancias.md         evento tras commit, outbox local; caché y job duplicados al escalar
├── 09-migraciones-de-esquema.md                Flyway sobre ddl-auto; separar products de inventory con expand/contract
├── 10-el-monolito-distribuido-provocado.md     inventory a otro proceso con la base compartida; medir y desmontar
├── 11-respuestas.md                            solucionario único del bloque
└── laboratorio/                   el estado del último taller escrito
    ├── estados/NN/   copia congelada al terminar el taller NN (`lab.py --estado NN`)
    ├── contrato/     docker-compose.yml · seed/ · toxiproxy/ · hurl/legacy (desde 03) · openapi.yaml y hurl/v1 (desde 04)
    ├── scripts/      lab.py — Python 3, solo biblioteca estándar
    ├── legacy/       mono-legacy, Java
    ├── inventory/    mono-inventory, Java (solo en 10)
    ├── psp-simulator/    el proveedor de pago externo, Python sin dependencias
    └── frontend/     React, opcional
```

```text
01 ─┬─ 02 (frontend opcional)
    ├─ 03 ── 04 ── 06 ─┬─ 07 ── 08
    │                  └─ 09 ── 10
    └─ 05
```

A diferencia de los sabores de hexagonal, aquí **hay un solo sistema y el laboratorio es
acumulativo**: cada taller modifica el legado que dejó el anterior en su rama de dependencias. El
frontend no tiene taller propio; aparece como sección opcional **🖥️ En el frontend** en `02`, `04` y
`07`, y ningún taller lo exige.

### 11.2 El contrato se descubre, no se trae

Los laboratorios hexagonal y de microservicios empiezan con un `openapi.yaml`. Este **no**: el legado
no tiene contrato, y reconstruirlo es parte de la lección. El recorrido es fijo:

```text
01–02   no hay contrato: se aprende la API leyendo código, logs y tráfico
03      hurl/legacy   caracteriza lo que HAY, defectos incluidos (200 + {"error"}, 500 + traza)
04      openapi.yaml  se escribe desde lo observado, con los errores ya correctos
        hurl/v1       problem+json y códigos reales; hurl/legacy deja de pasar, a la vista
05–10   hurl/v1       es la invariante: sigue en verde después de cada taller
```

- **Por fuera, la unión de los dos contratos hermanos.** Las rutas y las formas de `v1` son el
  superconjunto de las de hexagonal (que contiene las de microservicios). Al cerrar `04`, las suites
  `hurl/v1` de los otros dos laboratorios, **copiadas** a `contrato/hurl/`, pasan contra
  `mono-legacy`. Es el punto de enganche de la ruta completa; los cursos siguen siendo
  independientes y ninguno lee archivos de otro.
- **El error típico es deliberado y se corrige una sola vez.** Hasta `04`, todo responde `200` con
  `{"error": "..."}` y un fallo no controlado devuelve `500` con la traza de Java en el cuerpo. `04`
  lo corrige en un único manejador global y muestra al cliente que se rompe con la corrección.
- Un taller **no añade endpoints** fuera de lo que su ficha de `prompt-base.md` declara.

### 11.3 Plantilla del taller

```text
qué enseña → prerrequisitos y versiones exactas → mapa de carpetas → recorrido de la base de código
→ partes en orden, cada una con su fallo provocado ANTES de la corrección → evidencia
→ 🖥️ en el frontend (opcional, solo 02, 04 y 07) → 🧰 plataformas → teardown
→ ⚠️ errores frecuentes → 📚 referencias → 🧠 preguntas → 🧪 ejercicios
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
| En el frontend | 🖥️ |
| Diagnóstico de los errores reales | 🩺 |
| Teardown | 🧹 |

- **Vibecoding declarado.** El código se genera con un asistente y el taller no lo comenta línea a
  línea: explica la decisión —qué límite faltaba, qué garantía se recuperó, qué moneda se pagó— y
  muestra solo los recortes que la demuestran, cada uno con su desglose. Como el código lo escribe
  un asistente, **la evidencia manda sobre la prosa**: una afirmación sin salida pegada no cierra un
  taller.
- **El legado es feo a propósito, y lo dice.** Cada defecto de `mono-legacy` tiene un taller que lo
  desarma (la tabla está en `prompt-base.md` §9). Ningún taller lo corrige antes de su turno, y
  ninguno lo presenta como buena práctica.
- **El recorrido de la base de código es obligatorio.** Antes de cambiar nada, una lectura dirigida
  con rutas reales: punto de entrada, dónde se abre la transacción, quién escribe cada tabla, qué
  configuración pisa a cuál.
- **Ningún comando ni flag queda sin explicar.** Después de cada bloque de comandos va el desglose en
  viñetas. La orquestación es `laboratorio/scripts/lab.py` (Python 3, solo biblioteca estándar): no
  hay scripts `bash` ni PowerShell. En el texto se invoca como `python3 laboratorio/scripts/lab.py ...`
  y se desglosa igual que un comando.
- **Los errores se provocan a propósito**, con órdenes de `lab.py`, siempre **antes** de la
  corrección y con la salida pegada. **Toxiproxy** va delante de cada dependencia remota para la
  latencia y los cortes; nada de `sleep` en el código de negocio.
- **Primero se intenta arreglar dentro.** Ningún taller termina en "hay que partirlo en servicios"
  sin haber mostrado antes la corrección local y su límite. `10` es el único que distribuye, y lo
  hace para medir el daño, no para recomendarlo.
- **Los errores reales se documentan** en una sección 🩺 con el síntoma literal, la causa y la
  lección. Un taller que no encontró ninguno lo dice.
- **La evidencia es literal y fechada**: la salida de la suite, el `git diff --no-index --stat` entre
  dos estados, la fila de la base, la traza. Nunca una salida escrita a mano.
- **Teardown junto al recurso.** Lo que se levanta en una sección se apaga en esa sección; el compose
  común se apaga al final de cada taller.
- **El laboratorio es acumulativo, y cada taller congela su estado** en `laboratorio/estados/NN/`,
  que no se vuelve a tocar; `laboratorio/` a secas es el estado del último taller escrito. **Las rutas
  con número de línea de cada taller citan `laboratorio/estados/NN/`.**
- **Versiones exactas, verificadas el día de escritura.** Nunca `latest`, `^`, `~` ni rangos. Cada
  librería se comprueba en su registro en la misma sesión.
- **Ninguna cifra de rendimiento sin decir de dónde sale y qué no mide.** Se etiqueta "reproducción
  local, un solo nodo, sin red real".
- **Preguntas y ejercicios:** entre 10 y 15 preguntas 🟢🟡🟠🔴 ordenadas de menor a mayor, y entre 6
  y 8 ejercicios graduados, más un 🔥 opcional fuera del conteo. Al menos uno es **de orientación en
  código ajeno** ("¿en qué archivo y línea se abre la transacción que retiene la conexión?"). Todo
  se copia literal a `11-respuestas.md` con las tres capas de §8.

### 11.4 Qué no hace un taller

- No enseña Spring Boot, JPA ni React más allá de lo que hace falta para ubicar la decisión.
- No reabre decisiones de los capítulos: si hay que matizar una, enlaza el capítulo y dice qué
  cambió al correrlo.
- No usa la nube, Kubernetes ni un mesh. Las "dos instancias" de `08` son dos procesos locales.
- No es un taller de frontend legado: el frontend es un cliente React limpio que sufre la API sucia.
- No añade endpoints, entidades ni reglas fuera de lo que su ficha declara.

---

## 12. 🔒 Nombres fijos del laboratorio

No se inventan valores nuevos. Lo que no esté aquí lo fija el taller que lo necesite, en su tanda, y
se añade a esta sección en la misma edición.

| Qué | Valor |
|---|---|
| Prefijo de todo recurso | `mono-` |
| Proyecto compose | `mono-lab` |
| Puertos en el host | rango `3xxxx`, para no chocar con hexagonal (`1xxxx`, `808x`), microservicios (`2xxxx`) ni el laboratorio de bases de datos (puertos estándar) |
| Aplicación | `mono-legacy` en `38081`; paquete `dev.mono.legacy`; Java `25`, Spring Boot `4.1.1` |
| Proceso extraído (solo `10`) | `mono-inventory` en `38082` |
| PostgreSQL | `mono-postgres` en `35432`; base `mono_legacy` |
| Proveedor de pago | `psp-simulator` en `38085`; Toxiproxy `mono-toxiproxy`, API en `38474`, proxy `psp` en `38185` |
| Frontend | `35173` |
| Prefijo de la API | `/api/v1` (el legado ya lo usa, aunque no tenga contrato) |
| Productos semilla | `SKU-001` Mechanical keyboard 49.90 (stock 20) · `SKU-002` USB-C cable 9.90 (100) · `SKU-003` 27" monitor 222.00 (5) · `SKU-004` Webcam 59.00 (**0**) · `SKU-005` Workstation 1499.00 (3) |
| Moneda | `USD`. En el legado, `double` **a propósito** hasta `05`; después, decimal con dos cifras |
| Regla del `psp-simulator` | total `> 1000.00` → rechazado; total `== 666.00` → resultado incierto; resto → autorizado |
| Errores HTTP | hasta `04`: `200` con `{"error": "..."}` y `500` con traza; desde `04`: `application/problem+json` (RFC 9457) con `type`, `title`, `status`, `detail`, `instance` y un `code` estable propio |

`SKU-004` sin stock provoca el stock insuficiente; `SKU-005`, el rechazo del pago; tres `SKU-003`
suman `666.00`, el resultado incierto.

Fijados por `06/01` (2026-09-29):

| Qué | Valor |
|---|---|
| Usuarios semilla | `ana@mono.local` / `ana-12345`, cliente, `11111111-1111-4111-8111-111111111111` · `ops@mono.local` / `ops-12345`, operador, `22222222-2222-4222-8222-222222222222` |
| PostgreSQL | usuario `mono_legacy`, contraseña `mono-lab-pass`, base `mono_legacy`; imagen `postgres:17.11-alpine` |
| Toxiproxy | `ghcr.io/shopify/toxiproxy:2.12.0` |
| JWT | HS256, 900 s; secreto `mono-legacy-jwt-secret-do-not-share-2021` en `application.yaml` **a propósito** (pecado señalado en `01`) |
| Proveedor de pago | el legado llama al proxy `:38185` con timeout de 2 s; el simulador tarda 3 s con `666.00` |
| Cierre diario | `DailyCloseJob` cada 30 s (`legacy.daily-close.every-ms`); `lab.py legacy --daily-close-ms` lo cambia |
| Pruebas del legado | SQLite con `org.xerial:sqlite-jdbc` `3.53.2.1` (gestionado por Boot 4.1.1) y `hibernate-community-dialects` `7.4.5.Final` |
| Semilla | `contrato/seed/seed.sql` vacía y recarga; el esquema lo crea Hibernate (`ddl-auto: update`) hasta `09` |

Fijados por `06/04` (2026-09-29):

| Qué | Valor |
|---|---|
| Contrato | `contrato/openapi.yaml`, `mono-orders` 1.0.0; códigos de `Problem` los de los contratos hermanos más `BATCH_NOT_FOUND` |
| Suites | `contrato/hurl/v1` propia, invariante desde `04` (`lab.py suite` sin `--dir`); `hurl/hex` y `hurl/ms`, copias con `@hex.local`/`@ms.local` → `@mono.local` y los bloques que no caben comentados con `NO CABE (06/04 §7)` |
| Validación del contrato | Prism `stoplight/prism:5.15.10` en modo *proxy*, contenedor `mono-prism`, perfil `contract`, `:34010` (`lab.py contract`) |
| `Idempotency-Key` | obligatoria en el contrato con `x-enforced-from: "06/07"`; el legado la ignora hasta `07` |

Fijados por `06/05` (2026-09-29):

| Qué | Valor |
|---|---|
| Pruebas del legado | PostgreSQL en Testcontainers `2.0.5` (gestionado por Boot 4.1.1), imagen `postgres:17.11-alpine`, `@ServiceConnection` en `PostgresTestConfig`; SQLite retirado |
| Dinero | `BigDecimal` con `@Column(precision = 12, scale = 2)` → `numeric(12,2)` |
| Prueba pendiente | `OrderServiceTest.concurrentOrdersNeverOversell`, `@Disabled` hasta `07` |
| `lab.py legacy --sql` | registra cada sentencia de Hibernate (`logging.level.org.hibernate.SQL=debug`) |

Fijados por `06/06` (2026-09-29):

| Qué | Valor |
|---|---|
| Módulos | `shared`, `auth`, `inventory`, `notifications`, `orders`, `payments`, `reports` bajo `dev.mono.legacy`; raíz = API, `internal/` y `web/` = interior; `allowedDependencies` en cada `package-info.java` |
| Verificación | Spring Modulith `2.1.1` (BOM; `spring-modulith-api` en el código, `spring-modulith-starter-test` en pruebas) y la ArchUnit que trae, `1.4.2`; `ModularityTest` y `ArchitectureTest` |
| API entre módulos | `OrderSnapshot`, `PaymentLookup` (puerto de `orders` que implementa `payments`), `ReservedStock`, `Customers.emailOf`, `Notifications.orderCancelled` |
| Stock al cancelar | `InventoryService.release` (incremento en la base); el *trigger* lo retira `db/drop-legacy-trigger.sql` |

Fijados por `06/07` (2026-09-29):

| Qué | Valor |
|---|---|
| `Idempotency-Key` | módulo `idempotency`, tabla `idempotency_keys` (clave `actor:clave`, huella método+ruta+cuerpo); 8–128 caracteres; sin caducidad todavía; viaja al proveedor y es el `operationId` del pago |
| Pago | tres pasos: tx 1 (reclamar clave, bloquear pedido → `PAYMENT_PENDING`, intento `PENDING`), banco sin transacción, tx 2 (resultado y respuesta) |
| Stock | `ProductRepository.findForUpdate` con `PESSIMISTIC_WRITE` (`FOR NO KEY UPDATE`); reserva en orden de SKU |
| JPA | `spring.jpa.open-in-view: false`; las vistas cargan sus líneas con `@EntityGraph` |
| Carga | `lab.py storm orders|payments|double-pay`, `lab.py psp-charges`, `lab.py api --key` |

Fijados por `06/08` (2026-09-29):

| Qué | Valor |
|---|---|
| Segunda instancia | `mono-legacy` en `38083` (`lab.py legacy --port 38083`), misma base |
| Eventos | `orders.OrderCancelled` (con `eventId`); *outbox* `outbox_events` escrita en la transacción de la cancelación; `OutboxDispatcher` cada 500 ms (`legacy.outbox.every-ms`) con `FOR UPDATE SKIP LOCKED`; `notifications` escucha y usa el `eventId` como id |
| Jobs | *lease* en `job_leases` (`JobLeases.tryAcquire`, dura un periodo); `batch_runs.host` = `host:puerto` |
| Estado compartido | sin `OrderCache`; tokens revocados en `revoked_tokens` |
| Fallos inyectados | `lab.py fault notifications` (`CHECK (false) NOT VALID`) y `lab.py fault orders` (*constraint trigger* diferido que rechaza el `COMMIT`); `seed` los quita |

Fijados por `06/09` (2026-09-29):

| Qué | Valor |
|---|---|
| Esquema | Flyway `12.4.0` (gestionado por Boot 4.1.1; `spring-boot-starter-flyway` + `flyway-database-postgresql`); `ddl-auto: validate`; `baseline-on-migrate`, línea base `1` |
| Migraciones | `db/migration`: V1 baseline, V2 converger (retira FK entre módulos y *trigger*), V3 `inventory`; `db/switch`: V4 re-sincronizar; `db/contract`: V5 borra `products.stock` |
| Pasos | `legacy.inventory.step` = `expand` · `switch` · `contract`; `lab.py legacy --inventory-step expand|switch|contract|done` fija paso y carpetas |
| Stock | tabla `inventory` (`sku`, `stock`), dueña `inventory`; `StockStore` bloquea `products` y luego `inventory` mientras se escriben las dos |
| Pruebas | el esquema de prueba lo crean las mismas migraciones |

Fijados por `06/10` (2026-09-29):

| Qué | Valor |
|---|---|
| `mono-inventory` | `laboratorio/inventory`, paquete `dev.mono.inventory`, `:38082`, misma base; rutas `/internal/reservations`, `/releases`, `/items`, `/stock`; historia propia `flyway_inventory_history` (`db/inventory`; `db/inventory-rename` con `lab.py inventory --rename`) |
| Toxiproxy | proxy `inventory` `:38182` → `:38082`; `lab.py proxy inventory --latency|--down|--off` |
| Modos del legado | `legacy.inventory.mode` = `local` (por defecto, la fusión) · `remote-naive` · `remote` (reservas con `reservationId` y compensación en `afterCompletion`) |
| Medida | `lab.py bench --n 50` |

---

## 13. ✅ Checklist de cierre

- [ ] Responde una decisión de diseño o evolución, no solo define vocabulario.
- [ ] Identifica las unidades relevantes entre código, datos, despliegue, runtime y equipos.
- [ ] Distingue evidencia, diagnóstico y recomendación.
- [ ] Nombra la garantía que conserva y el coste concreto que introduce.
- [ ] No usa «monolito distribuido» a partir de una única señal.
- [ ] Incluye flujo o secuencia, errores frecuentes, veredicto y referencias verificadas.
- [ ] La tabla de plataformas tiene cuatro filas o declara por qué no aplica.
- [ ] Las 24–26 preguntas no contienen respuesta y están copiadas literalmente al solucionario.
- [ ] Los enlaces internos existen; los externos son directos y comprobados.
- [ ] Usa el sistema de ejemplo y la terminología canónica de §3: identificadores en inglés,
      comentarios en español, ningún `CrearPedido` ni `/pedidos`.

Solo para talleres:

- [ ] Declara en su primer párrafo que es opcional y de qué talleres depende.
- [ ] Sigue la plantilla de §11.3, con recorrido de la base de código.
- [ ] Todos los nombres, puertos, credenciales y semillas son los de §12.
- [ ] Ningún bloque de comandos sin desglose; la orquestación es `lab.py`; ninguna versión es
      `latest` ni un rango.
- [ ] Cada parte cierra con la suite que le toca en verde (`hurl/legacy` hasta `03`, `hurl/v1`
      desde `04`), la salida pegada y fechada.
- [ ] Al menos un fallo provocado por parte, antes de la corrección.
- [ ] Teardown junto al recurso.
- [ ] 10–15 preguntas y 6–8 ejercicios, copiados literalmente a `06-talleres/11-respuestas.md` con
      las tres capas.
