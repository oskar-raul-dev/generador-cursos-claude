# Prompt base: arquitectura monolítica y monolito distribuido para refresco técnico y entrevistas

Este documento es el contrato de contenido de `02-monolito/`. La forma la manda
`guia-de-estilo-y-convenciones.md`; este archivo fija qué cubre cada documento, qué confusión debe
desmontar y cómo se relaciona con el resto del recorrido. Cubre los cinco bloques teóricos y, en §9,
el bloque **opcional** de talleres.

**Audiencia:** alguien que ya programa backend y se prepara para entrevistas de Backend Senior, Tech
Lead o Arquitecto. Reconoce HTTP, SQL, transacciones, despliegues y DDD básico; aquí aprende a
razonar sobre unidades de cambio, límites internos, garantías locales y costes de distribución.

> **Vigencia:** 2026-09-29.

**Salto rápido:** [1](#1--inventario-definitivo) · [2](#2--cómo-leer-una-ficha) · [3](#3--bloque-01--fundamentos-y-modelo-mental) · [4](#4--bloque-02--modularidad-y-límites-internos) · [5](#5-️-bloque-03--datos-ejecución-y-operación) · [6](#6-️-bloque-04--monolito-distribuido) · [7](#7--bloque-05--decisión-evolución-y-práctica) · [8](#8--simulaciones-y-solucionarios) · [9](#9--bloque-06--talleres)

## 1. 📦 Inventario definitivo

```text
02-monolito/
├── README.md
├── plan-taller.md                        registro de la sesión de diseño del laboratorio (no normativo)
├── prompts/
│   ├── guia-de-estilo-y-convenciones.md
│   └── prompt-base.md
├── scripts/verificar_corpus.py
├── 01-fundamentos-y-modelo-mental/       6 capítulos + simulación + respuestas
├── 02-modularidad-y-limites-internos/    6 capítulos + simulación + respuestas
├── 03-datos-ejecucion-y-operacion/        7 capítulos + simulación + respuestas
├── 04-monolito-distribuido/               8 capítulos + simulación + respuestas
├── 05-decision-evolucion-y-practica/      6 capítulos + simulación + respuestas
└── 06-talleres/                           opcional: README + 10 talleres + respuestas + laboratorio/
```

**Corpus teórico: 51 documentos** — 33 capítulos, 5 simulaciones, 5 solucionarios, 6 README y los 2
documentos de `prompts/`. El capítulo `01/06` (§3) se añadió el 2026-09-29 y desplazó la simulación y
el solucionario del bloque 01 a `07` y `08`. Los capítulos `04/06` y `04/07` (§6) son del mismo día y
pasaron «Desmontar un monolito distribuido» a `04/08` y la simulación y el solucionario del bloque 04
a `09` y `10`.

**Bloque de talleres: 12 documentos** — README, 10 talleres y el solucionario `11-respuestas.md`,
más el código de `06-talleres/laboratorio/`. `plan-taller.md` no cuenta en ninguno de los dos
inventarios: es un registro, y manda sobre él lo trasladado a `prompts/`.

## 2. 🧭 Cómo leer una ficha

Cada ficha contiene: **Objetivo** (la decisión que debes poder defender), **Cubre** (el mínimo),
**🧰 Plataformas** (comparación o excepción), **Desmonta** (mitos obligatorios) y **Se toca con**
(dependencias conceptuales y futuros enlaces).

Las fichas fijan alcance, no encabezados literales. Cada capítulo debe seguir la pedagogía de la guía
y conservar el hilo de `orders`, `inventory`, `payments` y `notifications` (§3 de la guía).

---

## 3. 🧩 Bloque `01` — Fundamentos y modelo mental

Fija vocabulario y separa topología de calidad interna. Todavía no prescribe módulos ni servicios.

### `01/01` — Qué es una arquitectura monolítica

- **Objetivo:** explicar qué significa monolito sin confundir unidad de despliegue con desorden.
- **Cubre:** una aplicación desplegable; proceso único o réplicas equivalentes; código, datos y
  operación; ventajas de llamada local y transacción local; límites de la definición.
- **🧰 Plataformas:** no lleva código; muestra empaquetado y despliegue típicos sin fijar framework.
- **Desmonta:** «monolito significa legado» y «un monolito solo puede ejecutar una instancia».
- **Se toca con:** `01/02`, `01/03`, `03/04`, `05/01`.

### `01/02` — Unidades de código, despliegue, ejecución y datos

- **Objetivo:** nombrar qué está unido antes de juzgar si el acoplamiento es perjudicial.
- **Cubre:** repositorio, artefacto, proceso, réplica, esquema y transacción; flujo runtime frente a
  dependencia de código; unidad de cambio frente a unidad de despliegue; las cinco monedas.
- **🧰 Plataformas:** tabla de build, empaquetado, procesos y conexión a datos en las cuatro plataformas.
- **Desmonta:** «un repositorio equivale a un monolito» y «varios procesos equivalen a servicios».
- **Se toca con:** `01/04`, `02/03`, `03/05`, `04/01`.

### `01/03` — Monolito tradicional, modular y *big ball of mud*

- **Objetivo:** distinguir topología, modularidad y deterioro estructural mediante evidencia.
- **Cubre:** monolito por capas, monolito modular, *modulith*, aplicación distribuida y *big ball of
  mud*; diferencias entre carpetas, límites verificables y ownership; continuo, no escalera de madurez.
- **🧰 Plataformas:** ejemplos ligeros de módulo de lenguaje, paquete, workspace y comprobación de build.
- **Desmonta:** «modulith es un framework» y «todo monolito termina siendo una bola de barro».
- **Se toca con:** `02/01`, `02/02`, `02/06`, `04/01`.

### `01/04` — Acoplamiento, cohesión y razones de cambio

- **Objetivo:** localizar acoplamiento relevante sin perseguir independencia absoluta.
- **Cubre:** acoplamiento de código, datos, cambio, despliegue, tiempo y organización; cohesión
  funcional; connascence como lente opcional; volatilidad; coste de coordinación y de duplicación.
- **🧰 Plataformas:** no requiere código comparativo; matriz de síntomas y evidencia.
- **Desmonta:** «todo acoplamiento es malo» y «menos imports significa más autonomía».
- **Se toca con:** `02/03`, `02/05`, `04/02`, `05/05`.

### `01/05` — Cuándo elegir un monolito y antipatrones

- **Objetivo:** defender un monolito como decisión proporcional y declarar sus condiciones de revisión.
- **Cubre:** dominio joven, tamaño y experiencia del equipo, carga, regulación, latencia, consistencia,
  velocidad de entrega; señales para modularizar o distribuir; *premature distribution*; criterio de salida.
- **🧰 Plataformas:** señales operativas comunes; no prescribe tecnología.
- **Desmonta:** «microservicios son el siguiente paso natural» y «empieza distribuido para no migrar».
- **Se toca con:** todos los bloques; escenario obligatorio de startup con dominio incierto.

### `01/06` — Estilos de estructura interna: capas, clean, onion y vertical slice

- **Objetivo:** elegir cómo se organiza el código dentro de un despliegue y saber qué garantiza cada
  estilo, sin confundirlo con la topología.
- **Cubre:** capas (N-tier) y su regla real; paquete por capa frente a paquete por capacidad; clean
  architecture y onion como variantes de la regla de dependencias; vertical slice; dónde vive la
  lógica (Transaction Script, Active Record, Domain Model); qué estilo tolera qué tamaño de equipo y
  de dominio; por qué ninguno de ellos, por sí solo, produce un monolito modular.
- **🧰 Plataformas:** estructura de paquetes o módulos en las cuatro plataformas y qué herramienta
  hace cumplir la regla de dependencias en cada una.
- **Desmonta:** «clean y hexagonal son lo mismo con otro nombre», «capas equivale a mal diseño» y
  «vertical slice elimina la necesidad de límites».
- **Se toca con:** `01/03`, `02/01`, `02/03`, `02/06`. El curso `03-hexagonal/` da la
  profundidad de puertos y adaptadores; aquí se menciona en prosa, sin depender de él.
- **Nota de producción:** capítulo añadido el 2026-09-29. Obliga a renumerar la
  simulación y el solucionario del bloque 01 a `07` y `08`, a ampliar la simulación con preguntas
  sobre estilos internos y a actualizar los enlaces entrantes en la misma tanda.

---

## 4. 🧱 Bloque `02` — Modularidad y límites internos

Convierte un despliegue único en unidades de cambio reconocibles sin fingir independencia operativa.

### `02/01` — Módulos alrededor de capacidades de negocio

- **Objetivo:** proponer módulos por razón de cambio y lenguaje, no por tipo técnico.
- **Cubre:** capacidad de negocio, subdominio y contexto acotado en la profundidad necesaria;
  vertical slices; granularidad; cohesión; `orders`, `inventory`, `payments` y `notifications`.
- **🧰 Plataformas:** estructura idiomática de paquetes o módulos; código Java y TypeScript.
- **Desmonta:** «controllers, services y repositories son módulos de negocio».
- **Se toca con:** `01/03`, `02/02`, `02/04`, `05/02`.

### `02/02` — API pública del módulo y encapsulación interna

- **Objetivo:** decidir qué puede conocer otro módulo y mantener oculto el resto.
- **Cubre:** fachada o API interna; comandos, consultas y resultados; tipos expuestos; estabilidad;
  acceso directo accidental; contratos grandes; compatibilidad dentro de un único despliegue.
- **🧰 Plataformas:** mecanismos de visibilidad, módulos y paquetes; código Go y Java.
- **Desmonta:** «una clase `public` es una API diseñada» y «cada módulo necesita REST interno».
- **Se toca con:** `02/01`, `02/03`, `02/05`, `04/04`.

### `02/03` — Dirección de dependencias y ciclos entre módulos

- **Objetivo:** detectar y romper ciclos según ownership y flujo de información.
- **Cubre:** grafo de módulos; dependencia estática frente a llamada runtime; inversión local;
  mediación; ciclo de datos; secuencia de refactoring; cuándo un ciclo revela un límite falso.
- **🧰 Plataformas:** build modules, import rules y herramientas candidatas verificadas por ecosistema.
- **Desmonta:** «un event bus interno elimina cualquier ciclo» y «DI corrige la dirección automáticamente».
- **Se toca con:** `01/04`, `02/02`, `02/06`, `04/02`.

### `02/04` — Propiedad de datos en una base compartida

- **Objetivo:** obtener ownership de datos sin exigir una base física por módulo.
- **Cubre:** tabla y esquema lógicos; escritura por propietario; lectura publicada; vistas y consultas
  cruzadas; claves foráneas; reporting; migración; concesiones explícitas y fecha de revisión.
- **🧰 Plataformas:** ORM y SQL directo comparados por capacidad de respetar límites, no por preferencia.
- **Desmonta:** «base compartida significa datos sin dueño» y «schema separado garantiza autonomía».
- **Se toca con:** `03/01`, `03/05`, `04/03`, `05/04`.

### `02/05` — Comunicación interna: llamadas, comandos y eventos

- **Objetivo:** escoger el mecanismo más simple que preserve semántica y dependencia.
- **Cubre:** llamada directa, interfaz, mediador, comando y evento interno; respuesta inmediata;
  fan-out; orden; errores; transacción; eventos como hechos y no como RPC disfrazado.
- **🧰 Plataformas:** mecanismos in-process y contexto de ejecución; código TypeScript y Python.
- **Desmonta:** «los eventos siempre desacoplan» y «una llamada local impide extraer el módulo».
- **Se toca con:** `03/01`, `03/03`, `04/02`, `05/04`.

### `02/06` — Código compartido, *shared kernel* y controles arquitectónicos

- **Objetivo:** compartir deliberadamente sin crear un módulo `common` que posea todo.
- **Cubre:** shared kernel, utilidades técnicas, modelo canónico, duplicación consciente; ownership;
  versionado interno; reglas automatizadas de dependencias; revisión y excepciones temporales.
- **🧰 Plataformas:** pruebas arquitectónicas y reglas de importación candidatas en las cuatro plataformas.
- **Desmonta:** «DRY obliga a centralizar» y «un test arquitectónico crea buenos límites».
- **Se toca con:** `02/03`, `03/07`, `04/04`, `05/05`.

---

## 5. ⚙️ Bloque `03` — Datos, ejecución y operación

Explota las garantías locales del monolito sin ocultar concurrencia, rendimiento ni riesgo operativo.

### `03/01` — Transacciones locales y límites de consistencia

- **Objetivo:** decidir qué invariantes deben confirmarse juntas y dónde termina la transacción.
- **Cubre:** ACID sin tutorial de base; transacción por caso de uso; varios módulos en una transacción;
  rollback; aislamiento; consistencia fuerte frente a eventual; señales de un límite demasiado amplio.
- **🧰 Plataformas:** Spring, Node/TS, Go y Python; qué queda declarativo y qué explícito.
- **Desmonta:** «un monolito debe hacer todo en una sola transacción».
- **Se toca con:** `02/04`, `02/05`, `03/02`, `04/05`.

### `03/02` — Concurrencia, locking e idempotencia

- **Objetivo:** proteger invariantes ante solicitudes simultáneas y repeticiones.
- **Cubre:** lost update, optimistic y pessimistic locking, restricciones de base, idempotency key,
  deduplicación, reintentos locales; ejemplo de reserva y cobro; elección por contención.
- **🧰 Plataformas:** primitivas de transacción, errores y concurrencia; código Java y Go.
- **Desmonta:** «si está en el mismo proceso no hay carreras» y «idempotencia significa ignorar duplicados».
- **Se toca con:** `03/01`, `03/03`, `04/05`.

### `03/03` — Eventos internos, jobs y procesamiento asíncrono

- **Objetivo:** separar tiempo de ejecución sin simular una garantía que no existe.
- **Cubre:** evento en memoria, tabla de trabajo, scheduler y cola; commit y publicación; reintento;
  orden; backpressure; recuperación tras caída; cuándo introducir broker u outbox.
- **🧰 Plataformas:** schedulers, ejecutores y colas internas; código Python y TypeScript.
- **Desmonta:** «asíncrono equivale a distribuido» y «fire-and-forget es entrega garantizada».
- **Se toca con:** `02/05`, `03/06`, `04/05`, `05/04`.

### `03/04` — Rendimiento, caché y escalado

- **Objetivo:** escalar un monolito según el cuello real antes de partirlo.
- **Cubre:** perfilado; CPU, memoria, I/O y base; réplicas stateless; afinidad de sesión; caché;
  read models; pool de conexiones; escalado vertical y horizontal; coste de consistencia.
- **🧰 Plataformas:** profiling y modelo de concurrencia de las cuatro plataformas, con fuentes verificadas.
- **Desmonta:** «los monolitos no escalan» y «extraer el módulo caliente siempre resuelve el cuello».
- **Se toca con:** `01/01`, `03/02`, `03/06`, `05/01`.

### `03/05` — Despliegues, migraciones de esquema y rollback

- **Objetivo:** cambiar código y datos sin convertir el despliegue único en una apuesta irreversible.
- **Cubre:** build reproducible; migraciones expand-contract; compatibilidad; feature flags; rolling
  deployment de réplicas; rollback de código frente a datos; backups; criterio de abortar.
- **🧰 Plataformas:** empaquetado y herramientas de migración candidatas, verificadas antes de publicar.
- **Desmonta:** «un solo artefacto significa despliegue instantáneo» y «rollback deshace una migración».
- **Se toca con:** `01/02`, `02/04`, `04/04`, `05/04`.

### `03/06` — Observabilidad y resiliencia del monolito

- **Objetivo:** localizar fallos y contener recursos dentro de un proceso compartido.
- **Cubre:** logs estructurados, métricas y trazas internas; correlación; health checks; timeouts de
  dependencias; bulkheads de pools y ejecutores; degradación; límites de memoria; SLO del sistema.
- **🧰 Plataformas:** contexto, telemetría y aislamiento de recursos por ecosistema; código mínimo.
- **Desmonta:** «la observabilidad solo importa en sistemas distribuidos».
- **Se toca con:** `03/03`, `03/04`, `04/02`, `04/05`.

### `03/07` — Estrategia de pruebas y evidencia de modularidad

- **Objetivo:** probar comportamiento, límites y operación con la menor infraestructura necesaria.
- **Cubre:** pruebas de módulo, integración con base, slice tests, end-to-end, contratos internos,
  pruebas arquitectónicas, migraciones y concurrencia; pirámide por riesgo; falsos positivos de mocks.
- **🧰 Plataformas:** herramientas candidatas y límites de cada ecosistema, verificadas al escribir.
- **Desmonta:** «una prueba end-to-end cubre todos los módulos» y «imports limpios prueban autonomía».
- **Se toca con:** `02/06`, `03/05`, `04/04`, `05/03`.

---

## 6. 🕸️ Bloque `04` — Monolito distribuido

Diagnostica pérdida de autonomía con evidencia combinada y diseña una recuperación incremental.

### `04/01` — Anatomía y evidencia del monolito distribuido

- **Objetivo:** sostener o rechazar el diagnóstico sin usar una sola señal como definición.
- **Cubre:** componentes desplegables; acoplamiento de cambio, datos, despliegue, runtime y equipos;
  autonomía nominal frente a efectiva; costes del monolito y de la red acumulados; método de evidencia.
- **🧰 Plataformas:** no lleva código; matriz de diagnóstico y ejemplo completo.
- **Desmonta:** «varios servicios forman microservicios» y «una base compartida basta para diagnosticarlo».
- **Se toca con:** `01/02`, `01/04`, todo el bloque `04`.

### `04/02` — Cadenas síncronas y acoplamiento temporal

- **Objetivo:** decidir cuándo una colaboración síncrona es razonable y cuándo crea una unidad de fallo.
- **Cubre:** call chains; latencia acumulada; disponibilidad compuesta; timeout budget; retry storms;
  chatty APIs; agregación; duplicación selectiva; sustitución por eventos cuando la semántica lo permita.
- **🧰 Plataformas:** clientes HTTP/gRPC y propagación de contexto; foco en garantías, no en librerías.
- **Desmonta:** «REST desacopla» y «reemplazar llamadas por mensajes siempre mejora resiliencia».
- **Se toca con:** `01/04`, `02/05`, `03/06`, `04/05`.

### `04/03` — Base compartida, escrituras cruzadas y propiedad difusa

- **Objetivo:** recuperar ownership de datos sin una migración física de golpe.
- **Cubre:** acceso directo entre servicios; schema común; joins; triggers; cambios incompatibles;
  propietario de escritura; API de lectura; réplica o proyección; secuencia para separar almacenamiento.
- **🧰 Plataformas:** ORM, permisos de base y change data capture como mecanismos a verificar.
- **Desmonta:** «database per service arregla el ownership» y «todo join distribuido debe ser una API».
- **Se toca con:** `02/04`, `03/05`, `04/04`, `05/04`.

### `04/04` — Contratos frágiles y despliegues coordinados

- **Objetivo:** reducir cambios y releases en lockstep sin congelar la evolución.
- **Cubre:** compatibilidad hacia atrás y adelante; contratos de consumidor; versionado; esquema de
  eventos; librerías cliente compartidas; release train; feature flags; métricas de coordinación.
- **🧰 Plataformas:** mecanismos de serialización, contratos y CI; herramientas solo tras verificación.
- **Desmonta:** «versionar la URL da independencia» y «un monorepo obliga al despliegue conjunto».
- **Se toca con:** `02/02`, `02/06`, `03/05`, `05/05`.

### `04/05` — Fallos parciales, retries y falsas transacciones

- **Objetivo:** representar resultado incierto y diseñar recuperación sin fingir atomicidad remota.
- **Cubre:** timeout después de efecto; at-least-once; idempotencia; outbox e inbox; saga y compensación
  hasta el nivel necesario; reconciliación; estados visibles; por qué 2PC rara vez es respuesta por defecto.
- **🧰 Plataformas:** persistencia y mensajería comparadas; código Java de estado y reconciliación.
- **Desmonta:** «guardar y llamar en el mismo método es atómico» y «retry resuelve cualquier timeout».
- **Se toca con:** `03/01`, `03/02`, `03/03`, `05/04`.

### `04/06` — Acoplamiento asíncrono: el monolito distribuido con broker

- **Objetivo:** reconocer cuándo un broker cambia el momento del acoplamiento sin reducirlo, y decidir
  qué evento, esquema o flujo devuelve autonomía real.
- **Cubre:** comando disfrazado de evento (RPC sobre cola que espera respuesta); coreografía sin dueño
  del proceso; cadenas asíncronas que igual necesitan a todos los consumidores para completar un
  pedido; *event-carried state transfer* y esquemas de evento compartidos como base compartida
  diferida; orden, backlog y reprocesamiento como acoplamiento temporal aplazado; consumidores que
  bloquean la evolución del productor; orquestación explícita frente a coreografía; qué cambia en las
  cinco monedas frente a la cadena síncrona de `04/02`.
- **🧰 Plataformas:** clientes de broker y serialización de eventos en las cuatro plataformas, con
  foco en qué garantía de orden, entrega y esquema da cada uno; herramientas solo tras verificación.
  Código Java o TypeScript de un evento que expone el modelo interno frente a uno que expone un hecho.
- **Desmonta:** «los eventos desacoplan automáticamente», «con un broker ya no hay monolito
  distribuido» y «coreografía siempre es más autónoma que orquestación».
- **Se toca con:** `02/05`, `03/03`, `04/02`, `04/04`, `04/05`.
- **Nota de producción:** capítulo añadido el 2026-09-29. El bloque 04 cubría la cadena
  síncrona, la base, los contratos y los fallos; el acoplamiento que viaja por un broker solo aparecía
  como mito desmontado en la guía (§4.2) y no tenía capítulo dueño.

### `04/07` — Cómo se llega: granularidad, entidades y plataforma compartida

- **Objetivo:** explicar el origen del monolito distribuido para prevenirlo, no solo diagnosticarlo:
  qué decisiones de corte y de plataforma lo fabrican.
- **Cubre:** servicios por entidad (`order-service`, `customer-service` como CRUD anémicos) frente a
  servicios por capacidad; granularidad excesiva y *nanoservices*; la ley de Conway en ambos
  sentidos y el corte que copia el organigrama; librería `commons` con modelo de dominio compartido;
  entorno de integración compartido y pruebas end-to-end como único filtro de release; gateway o BFF
  con reglas de negocio; configuración y caché compartidas; cómo cada una se ve en las cinco monedas.
- **🧰 Plataformas:** mecanismos de empaquetado y publicación de librerías internas en las cuatro
  plataformas y qué acopla cada uno (versión transitiva, recompilación, despliegue); sin código extenso.
- **Desmonta:** «más pequeño es más desacoplado», «un servicio por tabla es un buen punto de partida»
  y «una librería común evita la duplicación sin coste».
- **Se toca con:** `01/04`, `02/01`, `02/06`, `04/01`, `04/04`, `05/05`.
- **Nota de producción:** capítulo añadido el 2026-09-29. `04/01` diagnostica el estado;
  este capítulo es dueño de las causas de corte y de plataforma, que antes quedaban repartidas en
  menciones sueltas de `01/04`, `02/06` y `04/04`.

### `04/08` — Desmontar un monolito distribuido

- **Objetivo:** ordenar una recuperación por riesgo sin otra reescritura total.
- **Cubre:** baseline de cambios e incidentes; elegir una costura; ownership primero; reducir cadenas;
  compatibilidad; fusionar servicios cuando convenga; *strangler fig* inverso; criterio de parada.
- **🧰 Plataformas:** no lleva bloques extensos; tabla de tácticas y automatización por ecosistema.
- **Desmonta:** «la solución es dividir cada servicio otra vez» y «fusionar servicios es un fracaso».
- **Se toca con:** `04/06`, `04/07`, `05/01`, `05/03`, `05/04`, `05/05`.

---

## 7. 🧭 Bloque `05` — Decisión, evolución y práctica

Integra restricciones técnicas y organizacionales en una respuesta de entrevista verificable.

### `05/01` — Monolito, monolito modular o servicios: matriz de decisión

- **Objetivo:** recomendar una topología con supuestos, evidencia y fecha de revisión.
- **Cubre:** dominio, equipos, escala, consistencia, aislamiento, regulación, disponibilidad y cadencia;
  coste reversible e irreversible; fitness functions; matriz que no produce una puntuación mágica.
- **🧰 Plataformas:** no lleva código; tabla de decisión y ejemplos contrastados.
- **Desmonta:** «existe un número de usuarios que obliga a usar microservicios».
- **Se toca con:** `01/05`, `03/04`, `04/01`, `05/06`.

### `05/02` — Diseñar un monolito modular desde cero

- **Objetivo:** proponer el mínimo diseño que conserva opciones sin construir servicios internos falsos.
- **Cubre:** mapa inicial; módulos; APIs; ownership de datos; transacciones; eventos; composición;
  repositorio y build; primera prueba arquitectónica; decisiones pospuestas explícitamente.
- **🧰 Plataformas:** esqueleto mínimo en Java y TypeScript; adaptación resumida a Go y Python.
- **Desmonta:** «diseñar para extraer exige tratar cada módulo como red desde el primer día».
- **Se toca con:** todo el bloque `02`, `03/01`, `03/07`.

### `05/03` — Recuperar modularidad en un monolito legado

- **Objetivo:** crear una costura vertical sin mover todo a carpetas nuevas.
- **Cubre:** pruebas de caracterización; hotspots de cambio; dependencias y datos; fachada; branch by
  abstraction; método Mikado para ordenar la secuencia; migración de escritura; secuencia pequeña;
  medir mejora; criterio de parada.
- **🧰 Plataformas:** refactorings y comprobaciones de build por ecosistema; sin reescritura paralela.
- **Desmonta:** «primero hay que definir la arquitectura final completa».
- **Se toca con:** `02/03`, `02/04`, `03/07`, `04/08`.

### `05/04` — Extraer un módulo a servicio

- **Objetivo:** decidir si una extracción compra autonomía suficiente y ejecutarla en orden seguro.
- **Cubre:** razones válidas; frontera candidata; contrato; propiedad y migración de datos; dual write
  prohibido sin estrategia; capa anticorrupción entre el modelo que sale y el que queda; strangler;
  shadow traffic; rollback; observabilidad; qué queda en el monolito.
- **🧰 Plataformas:** mecanismos de despliegue y migración; no convierte el capítulo en tutorial cloud.
- **Desmonta:** «si el módulo está limpio, extraerlo es cambiar una llamada local por HTTP».
- **Se toca con:** `02/05`, `03/05`, `04/03`, `04/05`.

### `05/05` — Equipos, ownership y gobernanza evolutiva

- **Objetivo:** alinear límites técnicos con capacidad real de decidir y operar.
- **Cubre:** cognitive load; ownership de módulo; platform team; revisión de APIs; excepciones;
  métricas de cambios y releases; equipos compartidos; Conway como restricción, no receta mecánica.
- **🧰 Plataformas:** no lleva código; matriz de controles sociales y automatizados.
- **Desmonta:** «un equipo por servicio garantiza autonomía» y «la arquitectura arregla la organización».
- **Se toca con:** `01/04`, `02/06`, `04/04`, `05/01`.

### `05/06` — Caso completo de system design y estrategia evolutiva

- **Objetivo:** conducir una respuesta de entrevista desde requisitos hasta evolución y criterios de revisión.
- **Cubre:** preguntas iniciales; restricciones; monolito inicial; módulos; datos; consistencia; carga;
  despliegue; observabilidad; failure modes; alternativa distribuida; roadmap; decisiones y no objetivos.
- **🧰 Plataformas:** neutral; añade notas solo donde un mecanismo cambie la decisión.
- **Desmonta:** «system design consiste en dibujar componentes» y «una arquitectura debe anticipar todo».
- **Se toca con:** los cinco bloques; sirve como repaso final antes de las simulaciones.

---

## 8. 🧪 Simulaciones y solucionarios

Cada bloque cierra con una simulación y un solucionario. Las simulaciones no son resúmenes: mezclan
conceptos y obligan a priorizar una garantía bajo información incompleta.

Escenarios obligatorios del corpus:

1. Startup de seis personas con dominio y carga todavía inciertos.
2. Monolito por capas donde un cambio pequeño toca controller, service y repository de varios dominios.
3. Monolito modular cuyos módulos escriben las tablas de los demás.
4. Réplicas horizontales que pierden sesiones o ejecutan dos veces el mismo job.
5. Migración de esquema incompatible durante rolling deployment.
6. Cinco servicios que requieren una cadena síncrona y un release train semanal.
7. Servicios con base compartida y ownership disputado entre equipos.
8. Cobro remoto que responde timeout después de haber autorizado el pago.
9. Decisión deliberada de fusionar dos servicios para recuperar una transacción y reducir operación.
10. Extracción de `payments` con migración de datos, rollback y criterio explícito para cancelarla.

Cada escenario debe declarar: **evidencia disponible**, **supuestos faltantes**, **garantía prioritaria**,
**trade-off** y **primera acción reversible**.

---

## 9. 🧪 Bloque `06` — Talleres

Bloque **opcional**, añadido el 2026-09-29. Ningún capítulo ni simulación depende de él. Implementa
el sistema de ejemplo como `mono-legacy`: un monolito Spring Boot que funciona pero se escribió sin
organización, y lo recupera sin romper a quien lo usa. Forma en §11 y nombres en §12 de la guía.

**Decisiones cerradas del bloque** (sesión de diseño del 2026-09-29, registrada en `plan-taller.md`):
mismo caso de estudio que los laboratorios hexagonal y de microservicios, redeclarado y no enlazado;
legado nuevo e independiente de `ms-monolith`, cuyo estado al cerrar `04` es **comparable** al de
`ms-monolith` en su taller 01; por fuera, la unión de los dos contratos hermanos, pero con el error
típico (`200` con el error en el JSON, `500` con traza) hasta `04`; sin OpenAPI de partida; un solo
sabor, Java; PostgreSQL en ejecución y SQLite en las pruebas del legado; frontend React opcional,
cliente limpio, en la última versión estable verificada en su tanda; el taller del monolito
distribuido provocado entra.

### Los pecados del legado

Cada defecto está puesto a propósito y tiene un dueño. Ningún taller lo corrige antes de su turno.

| Pecado a propósito | Taller que lo desarma |
|---|---|
| Sin README útil ni OpenAPI; la regla de pago solo existe en un `if` | `01` |
| Todo responde `200` con `{"error": "..."}` y mensajes libres | `02`, `04` |
| Un fallo no controlado devuelve `500` con la traza de Java en el cuerpo | `02`, `04` |
| `@Entity` serializada directamente al JSON (con el hash de la contraseña; `LazyInitializationException` al azar) | `02`, `04` |
| Pruebas contra SQLite; el dinero en `double` | `05` |
| Paquetes por capa; `OrderService` ↔ `InventoryService` en ciclo | `06` |
| Lógica repartida entre controlador, servicio y un *trigger* de PostgreSQL | `06` |
| El proveedor de pago llamado **dentro** de la transacción de base de datos | `07` |
| Stock descontado con leer-restar-escribir, sin bloqueo ni versión | `07` |
| Sin idempotencia en `POST /orders` ni en el pago | `07` |
| Notificación escrita en la misma transacción que la cancelación | `08` |
| Caché en memoria y `@Scheduled` que corre en cada instancia | `08` |
| Tokens revocados en un `Set` en memoria (descubierto al correr `08`) | `08` |
| `ddl-auto: update` en lugar de migraciones | `09` |
| `products` e `inventory` en una sola tabla | `09` |
| Secretos en `application.yaml` | se señala en `01`; el arreglo no es de este curso |

`reports/orders-summary` y `batches/{id}` existen en el legado como **consultas sincrónicas lentas
disfrazadas de lote**, que es lo que suele haber; ningún taller las convierte en un lote real (eso
es el taller 11 del curso hexagonal).

### `06/01` — Heredar el legado

- **Objetivo:** "Me dan un monolito sin documentación y en una hora sé qué hace, dónde y con qué
  datos."
- **Construye:** `mono-legacy`, compose base (PostgreSQL, Toxiproxy), semilla, `psp-simulator` y
  `lab.py`.
- **Enseña:** arqueología: rutas desde el código y los logs, la regla de pago desde un `if`, quién
  escribe cada tabla; secretos en la configuración, señalados y no arreglados.
- **Fallo provocado:** una petición "normal" que falla sin que nada lo diga: `200` y el pedido no
  existe.
- **Evidencia:** el mapa de rutas y tablas reconstruido, contrastado con tráfico real.
- **Capítulos:** `01/01`, `01/03`, `05/03`.

### `06/02` — Los errores escondidos

- **Objetivo:** "Explico por qué un `200` con error dentro acopla al cliente con los accidentes del
  servidor."
- **Enseña:** `200` con `{"error"}`, `500` con traza, entidad serializada con datos que no debían
  salir y `LazyInitializationException` intermitente.
- **Fallo provocado:** en el frontend opcional, el `200` con error se muestra como éxito y, al pintar
  un pedido inexistente, deja la pantalla en blanco; el `500` enseña al usuario el mensaje interno de
  Java. (Ajustado al correrlo: la traza llega como JSON válido y no rompe el `JSON.parse`.)
- **Evidencia:** respuestas literales del legado y captura de consola del frontend.
- **Capítulos:** `02/02`, `04/04`.

### `06/03` — Caracterización

- **Objetivo:** "Antes de tocar un legado, congelo lo que hace, incluidos sus defectos."
- **Construye:** `contrato/hurl/legacy` como golden master del comportamiento actual.
- **Fallo provocado:** un "arreglo" inocente (cambiar un mensaje de error) que la caracterización
  detecta como regresión.
- **Evidencia:** `hurl/legacy` en verde contra el legado; en rojo tras el arreglo inocente.
- **Capítulos:** `03/07`, `05/03`.

### `06/04` — El contrato

- **Objetivo:** "Escribo el contrato desde lo observado y rompo a un cliente a sabiendas, con plan de
  migración."
- **Construye:** `openapi.yaml`, `hurl/v1`, un manejador global de errores con `problem+json`, DTO en
  lugar de entidades; copia de las suites `v1` de los laboratorios hexagonal y de microservicios.
- **Fallo provocado:** `hurl/legacy` deja de pasar y el frontend que había aprendido a leer `{"error"}`
  en un `200` deja de mostrar errores. (Ajustado al correrlo: el cliente del taller 02 nunca leyó
  `{"error"}`, sino `message` y una lista; con el contrato, el catálogo deja de pintarse y los errores
  llegan sin texto.)
- **Evidencia:** `hurl/v1` propia y las dos copiadas, en verde contra `mono-legacy`. (Ajustado al correrlo:
  `hurl/v1` en verde y Prism sin violaciones de respuesta; las copias fallan solo en lo que depende de
  `Idempotency-Key`, cuyo dueño es `07`, y pasan completas al cerrar `07`.)
- **Capítulos:** `02/02`, `04/04`.

### `06/05` — SQLite miente

- **Objetivo:** "Sé por qué una prueba verde contra otra base no es evidencia."
- **Enseña:** diferencias que muerden (`FOR UPDATE`, `double` frente a `numeric`, `LIKE` y mayúsculas,
  fechas); Testcontainers con PostgreSQL; el dinero pasa a decimal.
- **Fallo provocado:** una prueba verde en SQLite cuyo caso falla en PostgreSQL.
- **Evidencia:** la misma prueba en rojo con Testcontainers y en verde tras la corrección.
  (Concretado al correrlo: la verde en SQLite y roja en PostgreSQL es la de sobreventa, cuyo arreglo es de
  `07` y queda `@Disabled`; la roja y después verde es la del total exacto, con el dinero en decimal.
  Además, el `ALTER` que Hibernate 7 lanza solo al arrancar.)
- **Capítulos:** `03/01`, `03/07`.

### `06/06` — Modularizar

- **Objetivo:** "Recupero límites internos sin cambiar de topología, y lo demuestro con una prueba."
- **Enseña:** de paquete por capa a paquete por capacidad; API pública de módulo; romper el ciclo
  `orders` ↔ `inventory`; sacar la lógica del *trigger*; ArchUnit y Spring Modulith.
- **Fallo provocado:** un import prohibido entre módulos que la prueba arquitectónica rechaza.
- **Evidencia:** suite `v1` en verde y prueba arquitectónica en verde; `git diff --stat` del movimiento.
  (Añadido al correrlo: la misma prueba de Modulith en verde sobre los paquetes por capa, como provocación
  previa; y la devolución duplicada del stock al mudar el *trigger*.)
- **Capítulos:** `01/06`, `02/01`–`02/03`, `02/06`.

### `06/07` — Transacciones y concurrencia

- **Objetivo:** "Arreglo el pool agotado y la sobreventa sin partir el monolito."
- **Enseña:** sacar al proveedor de la transacción; bloqueo pesimista o versión optimista;
  `Idempotency-Key` en pedido y pago; el resultado incierto (`666.00`) como estado, no como error.
- **Fallo provocado:** con Toxiproxy, el proveedor lento agota el pool y tumba el catálogo; veinte
  pedidos concurrentes venden más stock del que hay.
- **Evidencia:** la misma carga con el catálogo sano y el stock exacto; filas de la base pegadas;
  `hurl/hex` y `hurl/ms` completas en verde (lo que `04` dejó pendiente).
- **Capítulos:** `03/01`, `03/02`, `04/05`.

### `06/08` — Eventos, jobs y dos instancias

- **Objetivo:** "Sé qué se rompe al escalar un monolito horizontalmente y cómo evitarlo sin
  distribuirlo."
- **Enseña:** evento interno tras el commit; outbox local para la notificación; dos instancias del
  legado: caché en memoria incoherente y `@Scheduled` que corre dos veces; lease en la base.
- **Fallo provocado:** la notificación de un pedido cuya cancelación hizo rollback; el job nocturno
  ejecutado dos veces.
- **Evidencia:** filas de `notifications` y del job, antes y después. (Concretado al correrlo: el fallo al
  confirmar se inyecta con un *constraint trigger* diferido; la notificación perdida de
  `AFTER_COMMIT` entra como provocación intermedia; y con dos instancias aparecen también los tokens
  revocados en memoria.)
- **Capítulos:** `02/05`, `03/03`, `03/04`.

### `06/09` — Migraciones de esquema

- **Objetivo:** "Cambio el esquema con la aplicación viva y sé volver atrás."
- **Enseña:** Flyway sobre una base creada con `ddl-auto` (baseline); separar `products` de
  `inventory` con *expand/contract*; *rollback* de aplicación sin rollback de esquema.
- **Fallo provocado:** una migración incompatible durante un despliegue de dos instancias con
  versiones distintas.
- **Evidencia:** suite `v1` en verde en cada paso de expand/contract. (Concretado al correrlo: siete pasos
  con dos instancias de versiones distintas, 16 corridas en verde; la provocación es aplicar V2–V5 de
  golpe con la versión del estado 08 viva; hallazgo: interbloqueos entre versiones si cada una bloquea
  solo la tabla que lee.)
- **Capítulos:** `02/04`, `03/05`.

### `06/10` — El monolito distribuido provocado

- **Objetivo:** "Demuestro con evidencia que distribuir sin límites no compra autonomía."
- **Construye:** `mono-inventory`, un segundo proceso Java que comparte la base de `mono-legacy`.
- **Fallo provocado:** cadena síncrona que cae con Toxiproxy; cambio de columna que rompe al otro
  proceso; despliegue en *lockstep* obligatorio.
- **Después:** desmontarlo: fusionar de vuelta o darle propiedad de datos y contrato; se compara el
  coste de ambas salidas.
- **Evidencia:** suite `v1` en verde con los dos procesos y tras la fusión; la matriz de evidencias de
  `04/01` rellenada con datos del laboratorio. (Concretado al correrlo: con la extracción ingenua `v1` cae
  por la falsa transacción; queda en verde con los dos procesos en la salida «propiedad de datos y
  contrato» y tras la fusión, que es el estado final del laboratorio.)
- **Capítulos:** `04/01`–`04/08`, `05/04`.

### `06/11` — Respuestas

Solucionario único del bloque: preguntas y ejercicios de los diez talleres, enunciado literal y tres
capas (§8 de la guía).

### `06-talleres/README.md`

Mapa del bloque, dependencias, "todo aquí es opcional", las rutas de lectura (una tarde: `01 → 03 →
04`; Tech Lead Java: añadir `06` y `07`; arquitecto: añadir `10`), la relación con los laboratorios
hexagonal y de microservicios en prosa y una prueba de humo con desglose.
