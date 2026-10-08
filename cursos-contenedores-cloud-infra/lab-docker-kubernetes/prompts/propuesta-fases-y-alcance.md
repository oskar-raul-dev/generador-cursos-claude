# 🗺️ Propuesta de fases y alcance
## Laboratorio de contenedores y Kubernetes local

Este documento es la **fuente de verdad estructural del curso**. Fija el arco, la secuencia
numerada de fases, el encargo de cada una, los apéndices, el cuaderno de incidentes, las
convenciones de archivo y de git, y las decisiones cerradas con su porqué.

> **Precedencia:** debajo del [alcance](alcance-del-proyecto.md), de la
> [guía](guia-de-estilo-y-convenciones.md) y del [contrato del cluster](contrato-del-cluster.md).
> Si una fase de aquí contradice a uno de los tres, gana el otro y esto se corrige. Las plantillas
> y los prompts copian de aquí el peso y los ejercicios (§11).
> **Fecha:** 14/09/2026, revisada el 30/09/2026 con las decisiones D1–D18 (§12). **Estado:** temario
> cerrado (D1–D32). La verificación de laboratorio (P11) se hizo el 03/10/2026, y lo que fijó está
> en D32.

Una advertencia que vale para todo el documento: **las apuestas y las roturas escritas aquí son
candidatas**. La fase las reescribe en su paso 1 si el laboratorio sugiere algo mejor, y las deja
fijas **antes** de medir. Lo mismo con los mensajes de error que se citan: son los que se esperan, y
la fase publica el que salió.

> 🧭 **La pregunta que ordena el curso entero:** *¿qué te da el contenedor, qué te da el
> orquestador, y qué te sigue tocando escribir a ti?*
>
> Las Partes 0 a III son lo que la plataforma **sí** te regala. La Parte IV es lo que no te va a
> dar nunca, y por eso existen las sagas. El curso cierra con el ⚖️ veredicto honesto: cuándo no
> necesitabas nada de esto.

---

## 1. ✅ Decisiones cerradas

Ninguna de estas se reabre al escribir una fase. Si una fase necesita contradecir alguna, se
corrige **aquí primero**, con su razón escrita.

**🪦 El curso es autocontenido y no nombra ningún otro curso.** Ni como prerrequisito, ni como
profundización, ni para justificar una exclusión. Cuando un tema queda fuera, se declara la
exclusión y el texto se detiene ahí: decir dónde vive ese material es una promesa que esta carpeta
no puede cumplir.

**🪦 Nada de tratamiento *legacy*.** Todo el stack es actual y cada pieza se elige por lo que hace
hoy. No hay convivencia de generaciones de estilo, ni deuda heredada, ni arqueología de motores.
Lo que el ecosistema está retirando —y hay cosas— se nombra como lo que es y se sigue.

**🪦 El lector es un dev semi-senior o senior políglota.** Ha escrito JavaScript, PHP y Java, monta
endpoints sin pensarlo, y ha visto un `docker-compose.yml`. Lo que no tiene es la panorámica del
sistema completo ni una plataforma que pueda romper sin pagar. Se le explica infraestructura, no
programación.

**🪦 El código de negocio es andamiaje, y se genera asistido por LLM.** Es la decisión de método
que hace posible el alcance: el curso publica el **contrato** de cada servicio y el **prompt** que
lo genera, y el código resultante vive en `src/`. El lector puede regenerarlo, escribirlo a mano o
usar el que viene — y en los tres casos el curso funciona igual, porque **ninguna fase enseña a
programar el endpoint**. Lo sostienen un contrato OpenAPI por servicio, una suite de conformidad en
Hurl y una matriz de prompts escalonados (contrato del cluster §6); el detalle publicado está en
`a03`.

**🪦 El sistema se construye en oleadas horizontales, no servicio por servicio.** Tres oleadas
—esqueleto, almacén propio y el flujo que los cruza— repartidas por el arco, cada una tocando los
cuatro servicios a la vez con una capa fina. Y dentro de cada patrón nuevo, **`pricing` es el
servicio piloto** y los otros tres lo siguen. El detalle está en la §4.1, y es la decisión de
método que hace que ninguna fase de infraestructura tenga que depurar lógica de negocio.

**🪦 Cuatro servicios, cuatro runtimes, un frontend tonto.** `inventory` en Spring Boot 4 con Java
25 LTS, `catalog` en PHP con Laravel, `replenish` en Node con TypeScript y NestJS, `pricing` en Go, y
`storefront` en React con Vite servido como estático. Cada runtime está elegido por la lección de
plataforma que compra, no por variedad — la tabla completa está en la §3. **Sin Jakarta EE ni
MicroProfile**: no suman una lección que los otros cuatro no den.

**🪦 La JVM es la de Java 25, tal cual.** Hoy la JVM sabe que corre en un contenedor y dimensiona el
heap contra el límite del cgroup. La autopsia del `OOMKilled` se escribe sobre esa JVM y no sobre la
de hace diez años. Las JVM anteriores y MicroProfile quedan como extensión futura, fuera de este
curso (alcance §15).

**🪦 Gateway API es la única entrada al sistema.** El controlador de Ingress más usado del
ecosistema, ingress-nginx, se retiró en marzo de 2026. El curso no despliega ni un objeto `Ingress`;
el recurso aparece solo en el diccionario de traducción.

**🪦 Un solo Postgres con una base y un usuario por servicio.** *Database-per-service* es el
principio, y el laboratorio lo implementa con la credencial en vez de con el hardware, para caber
en la memoria del lector. **La divergencia se declara en voz alta** en la fase que la estrena:
en producción esto son instancias separadas, y esto es exactamente lo que se pierde.

**🪦 El laboratorio ocupa lo menos posible.** Es una restricción de diseño, no una molestia. kind
de **un solo nodo** por defecto, la observabilidad **encendida y apagada por pieza**, y tres
perfiles de despliegue —`minimo`, `lab` y `medicion`—. La meta es que `minimo` entre en 8 GB; lo
que se publica es lo medido en la verificación de laboratorio.

**🪦 kind es el cluster del curso.** k3d, minikube y el Kubernetes de Docker Desktop se miden una
vez, con el arnés, y se archivan. MicroK8s sale de la comparación: fuera de Linux exige una máquina
virtual más, y eso no compara clusters sino instaladores.

**🪦 El punto de entrada es un Taskfile.** Corre igual en PowerShell, macOS y Linux, y ninguna
instrucción del curso exige `make` ni un shell POSIX en Windows.

**🪦 No hay reparto horario.** Un curso donde media hora se va esperando a que un cluster levante o
a que una imagen de Java se construya no puede estimar horas con honestidad, y una cifra inventada
es peor que ninguna. Cada fase declara en su cabecera su **peso** —ligera, media o densa— y ahí se
acaba la promesa.

**🪦 TLS llega después de que el sistema funcione.** Añadir cifrado sobre algo que ya opera enseña
más que arrancar con cifrado, y permite que el laboratorio de incidentes de certificados tenga
contra qué romperse.

**🪦 El cuaderno de incidentes es un archivo propio**, con IDs globales que no se reasignan. El
lector lo consulta por síntoma, no por fase.

**🪦 Las versiones exactas se fijan en `a01`**, por digest y con su fecha de verificación, antes de
escribir la primera línea que las use. Ninguna se pone de memoria en este documento.

---

## 2. 🎭 El dominio y la empresa

El curso construye el sistema de inventario de una **cadena de retail**: venta → validar producto →
descontar stock → disparar reposición si el stock cae bajo el umbral. Es el flujo central, y está
elegido porque es la **transacción distribuida más honesta que cabe en un laboratorio**: cuatro
servicios, cuatro bases lógicas, y una compensación que significa algo cuando falla a la mitad.

> 🏘️ **La empresa es Droguerías La Vecina**, y su historia vive en
> [`00-historia-de-la-vecina.md`](../00-historia-de-la-vecina.md): personajes, cifras, cronología y
> reglas de negocio. El curso es el **proyecto Paracelso**: el POC con que la cooperativa prueba
> salir de su monolito en WebLogic y Oracle, que la unidad de I+D Alquimia construye en **La
> Rebotica**, un laboratorio en portátiles. La venta del curso es la de una droguería, y la reposición incluye
> el **préstamo entre droguerías**, que es una `replenishmentOrder` cuyo origen es otra `store`.
> **Este documento fija la estructura; ninguna fase inventa dominio por su cuenta.**

Lo que sí está fijado desde aquí, porque es contrato técnico y no narrativa, son los **nombres de
los servicios y de las entidades**, en inglés como manda la guía de estilo:

`product` · `category` · `store` · `stockLevel` · `stockMovement` · `replenishmentOrder` · `price`

Y los cinco servicios: **`catalog`**, **`inventory`**, **`replenish`**, **`pricing`**,
**`storefront`**. Ninguna fase los renombra. El detalle de qué gana cada uno en cada fase vive en
[`contrato-del-cluster.md`](contrato-del-cluster.md), que es de lectura obligatoria antes de tocar
cualquier cosa bajo `src/lab/`.

---

## 3. 🧱 El stack, y qué compra cada pieza

Ninguna pieza entra por variedad ni por completitud. Entra si enseña algo de la plataforma que las
otras no enseñan.

### 3.1 Los servicios

| Servicio | Stack | La lección de plataforma que compra |
|---|---|---|
| `inventory` | Spring Boot 4 · Java 25 LTS | La JVM contra los `limits` del cgroup. **El `OOMKilled` es la clase magistral del curso** y solo la da Java: la JVM de hoy sabe que está en un contenedor, y aun así muere cuando el heap configurado más la memoria que no es heap pasan el límite. Además arranca lento, lo que obliga a entender `readinessProbe` de verdad, y el AOT cache es su respuesta moderna |
| `catalog` | PHP · Laravel | El modelo de proceso que no encaja: PHP-FPM y nginx son **dos procesos en un pod**. Quién responde el health check, y por qué "un request, un proceso" hace que el HPA por CPU se comporte distinto a todo lo demás |
| `replenish` | Node · TypeScript · NestJS | El consumidor de eventos y el lado asíncrono de la saga. Y el *event loop* como tercer modelo de concurrencia frente a hilos y procesos |
| `pricing` | Go | El **suelo y el techo del experimento**: la imagen más pequeña y el arranque más rápido. Es el control de todas las mediciones y el sujeto de la fase de gRPC |
| `storefront` | React · Vite · nginx | Que el frontend **no es un servicio**: es un archivo que alguien sirve, y su configuración se hornea en tiempo de build |

### 3.2 Los datos y el bus

**PostgreSQL** como base del laboratorio, con una base y un usuario por servicio, desplegado con
la **imagen oficial y un `StatefulSet` propio**: sin charts de terceros, porque el lector tiene que
ver los campos y porque el catálogo de imágenes más usado para esto cambió sus condiciones en 2025.
**SQLite** en tres sitios elegidos y en ninguno más: el primer despliegue sin dependencias, las
pruebas donde el SQL no es el punto, y el experimento 🧨 del stock fantasma.
**Testcontainers** para todo lo que sí toque SQL de verdad — y la decisión se mide, con el tiempo
de suite de cada opción.
**Valkey** con doble función: caché en la Parte II y el pub/sub deliberadamente frágil de la
Parte IV.
**NATS con JetStream** como bus de la coreografía en serio, que es lo que fuerza las lecciones de
idempotencia y de outbox.

### 3.3 La observabilidad, deliberadamente flaca

Sin Operator. Nada de una distribución que traiga plano de control, alertas y exportadores: es de
donde salen los gigabytes, y además esconde el `scrape_config` detrás de un recurso propio, que es
justo lo que el lector necesita ver.

| Pieza | Elección | Por qué esta |
|---|---|---|
| Métricas | Prometheus binario único, configuración a mano, retención corta | El lector escribe el `scrape_config` y entiende el modelo de *pull* |
| Dashboards | Grafana con dashboards provisionados | Efímera y sin persistencia. Los dashboards son código y se versionan |
| Logs | Loki monolítico y Fluent Bit como `DaemonSet` | Fluent Bit es el recolector más liviano que existe, y el `DaemonSet` es contenido |
| Trazas | Tempo monolítico, **apagado por defecto**, y **los SDKs de OpenTelemetry** en los servicios | Solo se enciende en la Parte IV, donde por fin hay algo que trazar. OpenTelemetry es el estándar de instrumentación, y el lector lo va a encontrar en todas partes |
| Escalado | metrics-server | No es opcional: sin él no hay HPA. Es la única pieza que queda encendida cuando la observabilidad se apaga |

**Cada pieza se enciende y se apaga por separado** —métricas, tableros, logs, trazas—, porque la
observabilidad es lo que más memoria consume del laboratorio. Ninguna fase la exige entera salvo la
que la enseña, y cada fase declara en su encabezado qué piezas necesita.

### 3.4 Los tres perfiles de despliegue

No son cosmética: son parte del arnés de medición y del presupuesto de memoria. La definición exacta
está en el contrato del cluster §5.

- **`minimo`** — kind de **un solo nodo**, servicios y Postgres, observabilidad apagada, todo a una
  réplica. Es el perfil por defecto de las Partes 0 a II.
- **`lab`** — control-plane y dos workers, con lo que la fase encienda. Se usa donde el curso
  necesita más de un nodo de verdad: la topología (F07), el escalado (F16), el `DaemonSet` (F18), y
  las Partes III y IV.
- **`medicion`** — únicamente lo que se está midiendo, para que los números no los contamine nada
  más.

### 3.5 La entrada al sistema: Gateway API

El sistema se expone con **Gateway API**: un `GatewayClass` que pone el controlador, un `Gateway`
compartido en su namespace, y una `HTTPRoute` por servicio que el equipo del servicio escribe. El
controlador es **Envoy Gateway** (D12): implementa la especificación sin anotaciones propias, y el
proxy que despliega es el mismo Envoy que el lector va a encontrar debajo de muchos mesh y
balanceadores. La Fase 10 nombra las alternativas con sus ventajas y desventajas. El
`Service` del proxy del `Gateway` es un **`NodePort` fijo** que el cluster de kind publica en el
host con `extraPortMappings` (D32): en macOS, la dirección que cloud-provider-kind le da a un
`LoadBalancer` no llega al host. Siempre sobre los puertos 8080 y 8443 del host, porque Podman sin
privilegios no publica los privilegiados.

---

## 4. 🪜 El arco: cinco partes, 28 fases

| Parte | Qué hace | Fases |
|---|---|---|
| **0 · Prolegómenos** | El ambiente y el vocabulario. El sistema corriendo en compose | 00 – 02 |
| **I · El modelo y el salto** | Qué pasa debajo, y por qué compose deja de alcanzar | 03 – 06 |
| **II · El despliegue** | Lo que la plataforma te da: cluster, red, configuración, estado, Helm, escalado | 07 – 16 |
| **III · Operarlo** | Observabilidad, TLS, seguridad y diagnóstico | 17 – 21 |
| **IV · El lab de patrones** | Lo que la plataforma **no** te da: resiliencia, gRPC, sagas, outbox | 22 – 26 |
| **Cierre** | El veredicto honesto y el proyecto final | 27 |

Dos reglas de secuencia que ninguna fase puede saltarse:

> 🧭 **Primero funciona, después se entiende.** La Parte 0 pone al lector a correr contenedores
> antes de explicarle qué son. El orden inverso —teoría del kernel antes del primer `run`— pierde a
> media audiencia en la primera sesión.
>
> 🧭 **YAML plano antes que Helm, siempre.** Una herramienta de plantillas sobre un modelo que no
> entiendes es una máquina de frustración. El lector escribe los campos a mano antes de que nada
> se los genere.

### 4.1 🌊 El método de construcción: tres oleadas

El sistema **no se construye servicio por servicio**. Se construye en **oleadas horizontales**:
cada oleada toca los cuatro servicios a la vez y les añade una capa fina, en vez de terminar uno
antes de empezar el siguiente.

> 🧭 **Infra primero, dominio después.** El dominio es ruido mientras aprendes la plataforma.
> Cuando la fase trata sobre `readinessProbe`, lo último que quieres es estar depurando por qué la
> venta no descuenta stock — y al revés, cuando llega la saga quieres toda tu atención ahí y no en
> si el Gateway enruta bien.

Son tres, y cada una aterriza en la fase que la necesita, no al principio del curso:

| Oleada | Qué añade a los cuatro servicios | Dónde aterriza | Por qué ahí |
|---|---|---|---|
| **0 · Esqueleto** | Solo `/health` y un endpoint que devuelve JSON fijo. Sin base de datos, sin lógica | **Fase 02** | Es todo lo que hace falta para que compose —y después el cluster— tengan algo que levantar. Y es lo mínimo que deja ver la **forma** del sistema: cuatro procesos, una red, resolución por nombre |
| **1 · Almacén propio** | Cada servicio suma su almacén y sus operaciones básicas de lectura y escritura, **sin cruzarse entre ellos** | **Fase 09** | Es lo que hace posible el experimento 🧨 de la Fase 12: para que el stock se vuelva fantasma tiene que haber stock que escribir. Llega en SQLite, dentro del pod, y eso es deliberado |
| **2 · El flujo que los cruza** | La venta completa: validar producto, descontar stock, consultar precio y disparar reposición | **Fase 16** | Es lo que da **carga real** a la medición de escalado, y lo que la Parte III tiene que observar y la Parte IV tiene que romper. Antes de aquí, ningún servicio llama a otro por trabajo de negocio |

Entre la Fase 02 y la 16 el sistema devuelve datos poco interesantes, **y eso es correcto**: durante
diez fases lo que se está aprendiendo no tiene nada que ver con el dominio, y meterlo antes solo
habría añadido superficie donde equivocarse. El curso lo dice en voz alta en la Fase 02 en vez de
dejar al lector con la sensación de que le falta algo.

### 4.2 🧪 El servicio piloto

Dentro de cada oleada, y de cada patrón de infraestructura nuevo, **un servicio va primero y los
otros tres lo siguen**. El piloto es **`pricing`**, el más pequeño y el que arranca más rápido:
construir con él un Dockerfile, un subchart, un juego de probes o un `ServiceMonitor` cuesta
minutos en vez de esperas.

Una vez el patrón funciona en el piloto, replicarlo es casi mecánico —*"lo mismo que `pricing`,
pero en Java"*—, y ahí es donde aparece lo interesante: **las tres veces que no es mecánico**. Que
PHP necesite dos procesos, que Java tarde cinco segundos en estar listo, que Node cargue
dependencias que Go no tiene. Esas fricciones son el contenido, y solo se ven si hay un patrón
previo contra el que compararlas.

---

## 5. 📋 Las 28 fases, en detalle

Cada bloque declara: **qué construye**, **qué concepto trae**, y cuando corresponda **qué mide**
📏, **qué rompe a propósito** 🧨 y **qué difiere** a otra fase. El peso —ligera, media, densa— es
la única promesa de esfuerzo que da el curso.

### Parte 0 · Prolegómenos

Su regla es distinta a la del resto: aquí no se filtra por profundidad conceptual, sino por si el
lector puede seguir sin esto. Y **no se recrea en nada**: da el vocabulario mínimo y se detiene.
Cada tentación de profundizar tiene destino en una parte posterior, donde el tema llega con un
problema que lo justifique.

#### 🛠️ Fase 00 — El ambiente: dos escritorios y tres plataformas · *media*

**Construye:** una máquina lista. Docker Desktop y Podman Desktop instalados y conviviendo, con
una forma explícita de saber cuál está activo y de alternar entre ellos.

**Trae:** los prerrequisitos y su validación en las tres plataformas soportadas —Windows 11 con
WSL 2, macOS Apple Silicon y Linux amd64—, sin nota al pie y sin condescendencia: se dan las tres
instrucciones, en ese orden.

**🏚️ Y presenta el patrimonio**: lo que La Vecina ya tiene y con lo que arranca el taller
—Contingencia, el portal y la Braqui (`a16`)—, sin levantarlo todavía.

**🩺 Estrena el cuaderno de incidentes** con los cuatro fallos de instalación que se llevan por
delante a más gente: WSL 2 que no arranca, virtualización deshabilitada, la máquina de Podman que
no levanta, y el socket al que no tienes permiso.

**Difiere:** todo lo que sea *usar* los motores, que es la Fase 01.

> ⚠️ Es el material que más rápido envejece del curso. Lleva fecha de verificación visible y se
> revisa antes de cualquier publicación.

#### 📦 Fase 01 — Tu primer contenedor, y tu primer Dockerfile · *media*

**Construye:** la imagen de **la Braqui**, la pieza del patrimonio más simple de empaquetar —Node,
un solo proceso— y un contenedor corriendo. Es código que existe, con sus mañas, y no un ejemplo
hecho para la fase. (`pricing` todavía no existe: nace en la Fase 02.)

**Trae:** los tres sustantivos (imagen, contenedor, tag) y el modelo mental que los separa; los
verbos del trabajo diario (`run`, `ps`, `logs`, `exec`, `stop`, `rm`); la anatomía de un
Dockerfile de un solo *stage* con `FROM`, `WORKDIR`, `COPY`, `RUN`, `ENV`, `EXPOSE`, y **la
diferencia entre `CMD` y `ENTRYPOINT`**, que casi nadie explica bien; puertos y volúmenes desde la
línea de comandos; de dónde salen las imágenes y por qué tu descarga falló a la tercera; y la
limpieza del disco, que es el problema operativo más común de quien empieza.

**Difiere:** el multi-stage, el caché de capas y las imágenes base a la Fase 04. Las capas y OCI a
la Fase 03.

> 📝 **La nota del toolchain, y es propia de este curso.** Con las versiones actuales de los
> cuatro runtimes **ninguna imagen del laboratorio necesita un toolchain de compilación**: Node
> trae binarios precompilados, las extensiones de PHP vienen en las imágenes oficiales, Java no
> compila nada nativo y Go compila estático en su propia etapa. Eso simplifica mucho los
> Dockerfiles — y por eso la fase dice **dónde dejaría de ser verdad**: una dependencia sin
> binario para tu arquitectura, una extensión de PHP sin empaquetar, o una base con musl en vez de
> glibc. Se nombra el síntoma y se sigue.

#### 🧩 Fase 02 — Compose: el sistema entero en un archivo · *media*

**🏚️ Primero, el patrimonio en un archivo**: Contingencia con su Postgres, el portal y la Braqui,
levantados con `task legacy:up` (perfil `legacy`). Es "lo que hay", y el lector lo ve correr antes
de construir nada.

**🌊 Después, la Oleada 0 — el esqueleto.** Los cuatro servicios nuevos y el `storefront` corriendo
al lado del patrimonio con un solo comando, cada uno exponiendo `/health` y un endpoint que devuelve JSON fijo. **Sin base de datos y
sin lógica de negocio**, y eso es deliberado: lo que esta fase enseña es la **forma** del sistema
—cuatro procesos, una red, resolución por nombre— y el dominio solo la taparía.

**Trae:** `services`, `image` contra `build`, `ports`, `environment`, `volumes`, `depends_on`,
`networks`, y los comandos de operación. Y el contrato REST completo de los cuatro servicios
—incluidos los endpoints que todavía no existen, marcados como pendientes—, que a partir de aquí
está congelado.

**Y dice en voz alta por qué el sistema todavía no hace nada interesante**, con el calendario de
las tres oleadas delante, para que el lector no arrastre la sensación de que le falta algo.

**🦭 Estrena el marcador de divergencia** en un sitio inocuo: `docker compose` y `podman compose`
no son el mismo programa, hay más de una implementación, y conviene saberlo antes de que la
diferencia aparezca donde duele.

**🌊 Y estrena el método de generación:** el esqueleto sale de los prompts G0 de `a03`, y la suite
de conformidad en Hurl lo valida contra compose. Es la primera vez que el lector ve que un servicio
es válido porque pasa la suite, no porque alguien lo escribió de una forma concreta.

**Difiere:** la 🪞 de dónde se rompe el instinto de compose a la Fase 06. Aquí compose se usa y se
disfruta; la crítica llega cuando haya con qué compararla.

### Parte I · El modelo y el salto

Llega con el lector ya teniendo el sistema corriendo. Lo que no tiene todavía es el modelo mental
de qué pasa debajo. **Y aquí está la tentación más grande del curso: convertirlo en un tratado de
namespaces y cgroups. Se resiste** — este curso enseña el modelo, no el kernel.

#### 🔬 Fase 03 — El contenedor por dentro, y su ciclo de vida · *media*

**Trae:** qué es realmente un contenedor —un proceso del host con la vista recortada—, que es lo
que desactiva la analogía con la máquina virtual de la que salen la mitad de los errores de
intuición de este perfil; la imagen y sus capas, que es lo que hace comprensibles el caché, el
tamaño y por qué los datos se van; el estándar OCI y por qué construir con un motor y correr en
otro no rompe nada; **PID 1, las señales y el apagado limpio**, que son la mitad invisible de un
rollout sin cortes; y usuarios, permisos y rootless, en la medida exacta en que evitan el
`CrashLoopBackOff` más frustrante que existe.

**Difiere:** `securityContext` y el endurecimiento del pod a la Fase 20.

**🚫 Deja fuera, declarándolo:** cgroups y namespaces por dentro. Se nombra qué son y se sigue.

#### 🏗️ Fase 04 — Empaquetar los cuatro runtimes ⭐ · *densa*

**Construye:** el Dockerfile multi-stage definitivo de los cuatro servicios y del frontend.

**Trae:** `dive` para ver las capas por dentro; el patrón multi-stage resuelto cuatro veces, y **la constatación de que el patrón es uno
y cada runtime lo paga distinto**; las imágenes base y su costo —musl contra glibc, el shell que
ya no tienes para depurar—; el caché de capas, el orden de instrucciones y el `.dockerignore`; y
el digest frente al tag, que es la causa raíz de toda una familia de *"pero si yo desplegué el
arreglo"*.

**📏 La primera medición del curso, y la que fija el arnés:** tamaño final, build en frío, build
con caché y tiempo hasta el primer request atendido, para los cuatro runtimes. Es la tabla que el
lector va a recordar tres años después, y es la que hace defendible todo lo demás.

#### 🦭 Fase 05 — Los dos motores, sin guerra · *ligera*

**Trae:** que el mismo cluster corre sobre cualquiera de los dos y que las imágenes viajan entre
ellos porque OCI es un estándar; y **dónde divergen de verdad** — el demonio frente al modelo sin
demonio, rootless por defecto, el puerto 80 que Podman no te deja publicar sin más, y la máquina
virtual frente al WSL en cada plataforma.

**📏 Mide:** tiempo de creación del cluster, tiempo de build y memoria del host en reposo, en los
dos motores. La medición se publica; **ejecutarla es opcional para el lector**, que puede no tener
los dos instalados.

**🦭 Y la divergencia que más muerde en el resto del curso:** `kind load docker-image` supone Docker
(con Podman responde *"not present locally"* aunque la imagen esté); con Podman, la imagen viaja
como archivo (`podman save` y `kind load image-archive`), y se construye como `docker.io/lab/<svc>`
porque Podman la nombraría `localhost/lab/<svc>` y el pod que pide `lab/<svc>` no la encontraría.
Se resuelve aquí una vez y la tarea `images:load` la esconde después. Las otras dos que P11
encontró: `podman compose` delega en el `docker-compose` de Docker Desktop, y la máquina de Podman
por defecto (2 GiB) no alcanza para el laboratorio.

**🔥 Deja como opcional:** generar manifiestos desde contenedores corriendo. Es un puente
conceptual bonito y produce YAML que nadie desplegaría tal cual.

#### 🪜 Fase 06 — Del compose al cluster · *densa*

Es la bisagra del curso y donde vive su sección insignia.

**Trae:** 🪞 **dónde se rompe el instinto de compose** — `depends_on` no espera a que el servicio
esté listo, `restart: always` no es un `Deployment`, la red de compose resuelve por nombre pero no
es DNS de cluster, `scale` te da réplicas que nadie balancea de verdad, y tus volúmenes son del
host y punto. 📖 **El diccionario compose ⇄ Kubernetes en las dos direcciones**, para que el lector
pueda traducir cualquier archivo que tenga hoy en su trabajo. Y **qué no tiene traducción**:
`Namespace`, `ServiceAccount`, RBAC, el planificador, el bucle de reconciliación.

**Y el concepto del que cuelga todo lo demás:** el modelo declarativo y el bucle de reconciliación
— le dices al cluster qué quieres, no qué haga, y algo trabaja sin parar para que la realidad se
parezca. Sin esto, Kubernetes es una API rara; con esto, casi todo se deduce.

**🦭 Y el puente en la otra dirección:** `podman kube play` corre un manifiesto de Kubernetes sin
cluster. Es la prueba más corta de que el YAML describe un deseo y no un orquestador, y le deja al
lector una forma de probar un `Deployment` sin levantar nada.

**🚫 Deja fuera, declarándolo:** compose como herramienta de producción. No lo es, y decirlo es
parte del contenido.

### Parte II · El despliegue

Es la mitad *"esto es lo que la plataforma te da"*, y es a lo que el lector vino.

#### ☸️ Fase 07 — El cluster local · *media*

**Construye:** los dos clusters del curso desde sus archivos de configuración: el de un nodo del
perfil `minimo`, que es el de todos los días, y el de control-plane con dos workers del perfil
`lab`, que se levanta aquí para ver la topología y se apaga hasta que haga falta.

**Trae:** la topología y qué corre en cada nodo, y por qué un solo nodo alcanza para casi todo lo
que el curso enseña; `kubectl`, contextos y la higiene de no equivocarse de cluster; y por qué
`localhost` llega o no llega a tu pod, que es la primera frustración universal.

**📏 Mide:** kind, k3d, minikube y el Kubernetes de Docker Desktop — tiempo de arranque, memoria en
reposo y si dan multi-nodo, sobre los dos motores donde se pueda. Y después se archivan: **kind es
el cluster del curso.**

#### 🚀 Fase 08 — El primer despliegue, en YAML plano ⭐ · *densa*

**Construye:** `pricing` desplegado a mano, con su `Deployment` y su `Service`, sin ninguna
herramienta que genere nada.

**Trae:** la escalera Pod → ReplicaSet → Deployment y por qué casi nunca escribes un Pod; el
`Service` de tipo ClusterIP y el DNS interno, que es la respuesta a *"¿cómo se llaman entre sí mis
servicios?"*; y el primer contacto con `describe`, `logs` y `events`.

**🩺 Primeros incidentes de plataforma:** la imagen que nunca se cargó al cluster, y el `Service`
sin endpoints porque el selector no coincide con las labels.

#### 🧱 Fase 09 — Los cuatro servicios dentro · *media*

**Construye:** los cuatro servicios y el `storefront` desplegados en el cluster, siguiendo el
patrón que `pricing` estrenó en la Fase 08.

**🌊 Oleada 1 — el almacén propio.** Cada servicio suma su almacén y sus operaciones básicas de
lectura y escritura, **sin llamarse entre ellos todavía**: `catalog` sirve productos de verdad,
`inventory` registra movimientos y devuelve existencias, `replenish` crea y lista órdenes,
`pricing` resuelve precios. Todo en **SQLite, dentro del pod**, y eso es una deuda 💸 declarada con
fecha de cobro: la Fase 12. Es el paso G1 de la matriz de generación, y la suite de conformidad del
paso corre ya contra el cluster.

**Trae:** `Namespace` como frontera, labels y selectores como el mecanismo que lo une todo, el DNS
interno entre namespaces, y el primer `ConfigMap` con las URLs de los vecinos —que todavía nadie
usa, y por eso es un buen sitio para introducirlo sin ruido.

**🚫 Deja fuera:** la persistencia real y el flujo que cruza servicios. Los dos con su fase de
destino escrita.

#### 🌐 Fase 10 — La entrada al sistema · *media*

**Construye:** el controlador de Gateway API, un `Gateway` compartido en el namespace `gateway`, y
una `HTTPRoute` por servicio: `storefront.localhost` para el frontend y `api.localhost` con ruteo
por prefijo a los cuatro backends, accesibles desde el navegador del host.

**Trae:** los tipos de `Service` y **por qué `LoadBalancer` se queda en `Pending`** en un cluster
recién creado. Después, cloud-provider-kind lo resuelve delante del lector, y esa es la lección: **un
objeto no hace nada sin alguien que lo implemente**, y en la nube ese alguien te factura una IP. Es
el primer 🚧 del curso, y tiene una segunda mitad honesta: en macOS esa IP no llega al host, y el
mapeo de puertos de cloud-provider-kind publica uno efímero distinto en cada creación. Por eso el
laboratorio entra por un `NodePort` fijo que kind publica en `127.0.0.1:8080` (D32).

**🧨 La rotura natural, en el perfil `lab`:** Envoy Gateway crea el `Service` del proxy con
`externalTrafficPolicy: Local`; cuando el proxy cae en un worker, el `NodePort` del control-plane
—el único mapeado al host— no reenvía y el navegador se queda esperando. Se arregla con
`externalTrafficPolicy: Cluster` en el `EnvoyProxy`, y se explica qué se pierde (la IP de origen). Luego, el reparto de papeles de Gateway API —quien opera la
infraestructura pone el `GatewayClass` y el `Gateway`, y cada equipo escribe su `HTTPRoute`— y por
qué ese reparto es lo que faltaba en el modelo anterior. Y el dominio local, con por qué tu
navegador llega y tu `curl` a veces no.

**⚖️ Las otras implementaciones, con lo que ganan y lo que pierden:** Traefik (liviano y con
Ingress y Gateway en el mismo controlador, a cambio de su propio modelo de configuración), NGINX
Gateway Fabric (la continuidad para quien viene de NGINX), kgateway (Envoy con extensiones de API
gateway), y Istio o Cilium (la entrada como parte del mesh o del CNI, con todo lo que eso suma). La
tabla es de criterio, no de medición: solo Envoy Gateway se instala.

**📖 Sección corta sobre `Ingress`**, solo como traducción: qué es, por qué lo vas a encontrar en
clusters ajenos, cómo se lee uno y cómo se traduce a `HTTPRoute`. **No se despliega ninguno.** Y la
nota honesta de por qué: el controlador más usado se retiró en marzo de 2026, y sus anotaciones no
eran portables entre controladores.

**🏚️ El *strangler*, en el camino base (D27):** Contingencia entra al cluster en el namespace
`legacy`, detrás del mismo `Gateway`, y una `HTTPRoute` reparte por pesos el tráfico de precios
entre Contingencia y `pricing`, hasta que Contingencia no recibe nada. Es la forma de sacarle
tráfico a un sistema sin apagarlo, y es lo que Paracelso tiene que hacer con el Siga de verdad.

**🩺 Incidente:** la `HTTPRoute` que no se engancha al `Gateway` —el `parentRef` apunta al namespace
equivocado, o el `Gateway` no admite rutas de otros namespaces— y devuelve 404 sin que ningún pod
se entere.

#### ⚙️ Fase 11 — Configuración y secretos ⭐ · *media*

**Trae:** `ConfigMap` y variables de entorno, con la lección de que cambiar un ConfigMap no
reinicia nada —en la voz de la historia, *"salió la circular de precios y las droguerías siguen
cobrando lo viejo"*: el tope regulado de `pricing` es configurable y su tabla vive en un
`ConfigMap`—; `Secret` y la verdad incómoda de que base64 no es cifrado; y **la pieza central de
la fase: la configuración horneada en build frente a la inyectada en arranque.**

El `storefront` es el caso perfecto y se demuestra con dos despliegues de la misma imagen: su
`API_URL` se fija al compilar, y el contenedor espera inyectarla al arrancar. Ese desajuste es la
causa raíz de la mitad de los *"funciona en QA y no en producción"* de cualquier aplicación de
página única. El arreglo es el paso G2: el `storefront` lee su configuración al arrancar.

**🏚️ Y el `.env` del portal (`a16`):** las credenciales SOAP de Contingencia viven versionadas en
el repositorio y horneadas en la imagen desde 2019. Con el portal ya en el namespace `legacy` (F10),
la fase las pasa a un `Secret` y muestra lo que no se arregla con eso: el historial de git.

**🚫 Deja fuera, declarándolo:** los gestores de secretos externos. Exigen infraestructura que el
laboratorio no tiene y no cambian ninguna decisión local.

#### 💾 Fase 12 — Estado, almacenamiento y datos iniciales · *densa*

**🧨 Abre rompiendo, y es la mejor puerta de entrada del curso.** Desde la Oleada 1 de la Fase 09
los servicios llevan tres fases escribiendo en SQLite dentro del pod, impecable. Le subes las
réplicas a dos. Las dos responden, ninguna falla, ningún log se queja — **y el stock aparece y
desaparece según qué réplica conteste.** Nadie olvida un bug que no produce ningún error.

Ahí se cobra la deuda 💸 que la Fase 09 dejó declarada.

**Construye:** Postgres en el cluster como `StatefulSet` escrito a mano sobre la imagen oficial,
con su PVC y su `Service` headless, y los cuatro servicios apuntando a su propia base con su propia
credencial (paso G3).

**Trae:** volúmenes, `PersistentVolume`, `PersistentVolumeClaim` y `StorageClass`, todos motivados
por el fallo de arriba; identidad estable y arranque ordenado; `Job` y `CronJob` para el seed y las
migraciones —el seed es el script de Python de `a01` (D31), empaquetado en una imagen y corrido como
`Job`—; y **el orden de la migración contra el rollout**, con la pregunta que nadie se hace a
tiempo: qué pasa si dos réplicas migran a la vez.

**⚖️ Y un veredicto honesto:** vas a poner Postgres en el cluster en este laboratorio, y
probablemente no deberías hacerlo en producción. Aquí está por qué.

**Declara la divergencia:** un servidor con una base por servicio en vez de instancias separadas,
y qué se pierde con eso.

**⚰️ La autopsia, de la historia y en vivo:** la Braqui integrada al Siga leyendo y escribiendo en
sus tablas (historia §1.11). En el laboratorio no se cuenta: el patrimonio la trae funcionando así,
sondeando las tablas de Contingencia, y la fase lo muestra antes de que `replenish` tenga su base.
Integrar por la base de datos fue la decisión razonable de quien quería una sola verdad, y ató a dos
equipos a un mismo esquema y a un mismo calendario de despliegue. Es la que justifica *una base por
servicio*, y la que hace honesta la divergencia del laboratorio: una base y un usuario por servicio,
y ninguna tabla compartida.

**🏚️ Y el script de la Braqui (D30, historia §1.9):** el aviso de traslados por archivo pasa de su
`cron` dentro del contenedor a un `CronJob`. `concurrencyPolicy: Forbid` y `activeDeadlineSeconds`
reemplazan el archivo de bloqueo, y con él el bloqueo que se queda puesto después de un reinicio.
Es lo que la plataforma sí arregla; las otras mañas del script quedan anotadas para la Parte IV.

#### 📦 Fase 13 — Helm: el paquete · *densa*

**Abre con el dolor:** cuatro servicios por tres perfiles son doce archivos casi idénticos. La
herramienta llega después de que el lector haya sentido eso, no antes.

**Construye:** el umbrella chart con un subchart por servicio, y los tres perfiles de valores.

**Trae:** chart, plantillas, valores y qué es realmente un release; la disciplina de qué va en el
chart base y qué en el override; y los *hooks* para el seed y las migraciones que la fase anterior
dejó como Jobs sueltos.

#### 🔧 Fase 14 — Helm en operación · *media*

**Trae:** `upgrade`, `rollback`, `--dry-run` y el *diff* previo — la red de seguridad que hace que
el lector se atreva a tocar; y los tres perfiles de la §3.4 en uso real, incluido el de medición.

**🏘️ La segunda cadena (D24):** el mismo chart instalado una segunda vez, como el release
`tenant-b` en el namespace `apps-b`, para "la cadena de Don Rodrigo", con su propio archivo de
valores (marca, tope regulado, réplicas). Es la cuarta pregunta del encargo de la historia y la
prueba de que la configuración vive en los valores y no en el código. Se apaga al terminar la
fase: el perfil `minimo` no la lleva.

**Sección corta sobre Kustomize:** que hay dos escuelas —plantillas contra parches— y en qué se
diferencian.

**🔥 Deja como apéndice:** GitOps. Es el destino natural de todo esto y merece nombrarse con
honestidad, pero montarlo exige un repositorio, un flujo y un plano de control que duplican el
alcance.

#### 🩺 Fase 15 — Salud y recursos ⭐ · *densa*

**Trae:** las tres *probes* y, sobre todo, **la diferencia entre liveness y readiness**, que casi
nadie tiene clara: una readiness mal puesta corta tráfico en cada despliegue, y una liveness mal
puesta reinicia pods sanos en bucle. Los dos fallos son comunes y los dos son invisibles.

Y la observación que solo un curso políglota puede hacer: **el mismo campo del YAML significa cosas
distintas según lo que corre debajo.** Spring Boot tarda segundos, Go milisegundos, y PHP-FPM está
"listo" antes de poder atender de verdad.

La readiness deja de ser trivial en esta fase (paso G4): cada servicio comprueba lo que de verdad
necesita para atender, y nada más.

Después, `requests` y `limits`: qué le prometes al planificador y qué te impone el cgroup. Y
`ResourceQuota` y `LimitRange` por namespace, con las dos cadenas de la F14 encendidas: que una
cadena en quincena no le quite la máquina a la otra (D24).

**⚰️ La autopsia central del curso: el `OOMKilled` de la JVM de hoy.** Java 25 sabe que está en un
contenedor y dimensiona el heap contra el límite, así que la historia no es la del heap ignorante
de hace diez años. Es la de la decisión razonable que la rompe: un `-Xmx` copiado de cuando el
servicio corría en una VM, o un `MaxRAMPercentage` subido cerca del cien "para aprovechar la
memoria", con la memoria que no es heap —metaspace, pilas de hilos, buffers directos, caché de
código— empujando por encima del límite. El pod muere sin escribir ni un error, y el arreglo se
mide antes y después.

**🔥 Sección corta: el AOT cache.** La respuesta de la JVM actual al arranque lento, medida contra
la readiness de `inventory`. La comparación completa con la compilación nativa es el apéndice `a08`.

#### 📈 Fase 16 — Escalado y rollout · *densa*

**🌊 Oleada 2 — el flujo que los cruza.** Abre cerrando el dominio: la venta completa, con
`inventory` validando el producto contra `catalog`, consultando a `pricing`, descontando
existencias y disparando una reposición en `replenish` cuando el stock cae bajo el umbral. **Es la
primera vez en todo el curso que un servicio llama a otro por trabajo de negocio**, y llega aquí
porque es lo que da carga real a la medición de esta fase, material que observar a la Parte III y
algo que romper a la Parte IV.

Es el paso G5, y trae consigo el apagado limpio ante `SIGTERM` en los cuatro servicios.

El aviso a `replenish` se hace **sin esperar respuesta, registrando el resultado en el log**: la
venta no puede fallar porque el servicio de reposición esté caído. Es, en la historia, el préstamo
entre vecinas: si la droguería no tiene, se pide a otra. Es una decisión deliberada y
deja sembrada la pregunta que la Fase 25 responde — *¿y si esa llamada se pierde?*

**Trae:** escalado manual y HPA, con su decepción honesta incluida — el HPA reacciona tarde, mide
una sola métrica, y con PHP-FPM se comporta distinto que con Node; las estrategias de rollout,
`maxSurge` y `maxUnavailable`; y **el apagado limpio**, con `terminationGracePeriodSeconds` y el
`preStop` que le da tiempo al balanceador a enterarse. Ahí se cobra lo que la Fase 03 sembró sobre
`SIGTERM`. metrics-server entra aquí, y con él el primer incidente de un cluster local: el HPA que
muestra `<unknown>` porque el kubelet de kind no presenta un certificado que metrics-server acepte.

Es la fase que enciende por primera vez el perfil `lab`: sin más de un nodo, el reparto de réplicas
no enseña nada.

**📏 Mide:** con carga generada, cuántas réplicas de cada runtime sostienen la misma tasa de
peticiones, y cuánta memoria cuesta cada una. Es la tabla que cierra la tesis de la Parte II.

**🚧 Frontera declarada:** `PodDisruptionBudget`, autoescalado de nodos y multi-zona se nombran
como lo que existe del otro lado y no se puede reproducir gratis.

### Parte III · Operarlo

Aquí el sistema deja de ser un diagrama y se vuelve algo que se rompe.

#### 📊 Fase 17 — Métricas y dashboards · *densa*

**Construye:** Prometheus con su `scrape_config` escrito a mano, Grafana con dashboards
provisionados como código, y los cuatro servicios exponiendo `/metrics` (paso G6). Estrena los
interruptores de observabilidad: la fase mide cuánto cuesta cada pieza encendida, y el lector
aprende a apagarla cuando no la usa.

**Trae:** los tres pilares y cuándo sirve cada uno —métricas para saber que algo va mal, logs para
saber qué, trazas para saber dónde—, que es el criterio que separa diagnosticar de adivinar; el
modelo de *pull*; y la instrumentación de los cuatro runtimes, comprimida, porque es el mismo
concepto cuatro veces.

**Y una tesis del curso, dicha aquí:** exponer métricas es responsabilidad de la aplicación, no
regalo de la plataforma. Lo que el cluster te da gratis no te dice nada de tu negocio.

**🚫 Deja fuera, declarándolo:** las alertas y una cadena de guardia. Sin destinatario, una alerta
es un ejercicio vacío.

#### 🔎 Fase 18 — Logs · *media*

**Construye:** los cuatro servicios logueando JSON estructurado a stdout (paso G7), Fluent Bit como
`DaemonSet` en el perfil `lab` —en un solo nodo, un `DaemonSet` no se distingue de un
`Deployment`— y Loki recibiéndolo todo.

**Trae:** la regla operativa —a stdout, nunca a archivo— y la fricción real de conseguirla en Java
y en PHP, que por defecto loguean texto plano; el `DaemonSet` como el objeto que explica cómo
funciona un recolector; y LogQL para buscar una venta a través de cuatro servicios.

#### 🔐 Fase 19 — TLS y certificados ⭐ · *densa*

**Construye:** una CA propia, el certificado del listener HTTPS del `Gateway` firmado con su SAN
correcto, montado como `Secret` TLS, y la confianza instalada en el host. Después, cert-manager con
un emisor propio que lo renueva solo, y trust-manager para repartir la CA a los pods que la
necesitan.

**Trae:** la cadena de confianza entendida de una vez, que es lo que casi nadie tiene claro del
todo; y el patrón de emisión automática que el lector va a encontrar en cualquier cluster real.

**🧨 Y abre el laboratorio de incidentes de certificados**, que es el mejor activo individual del
curso: certificado expirado, CA desconocida, SAN incorrecto, clave y certificado desparejados,
cert-manager que no emite, mTLS sin certificado de cliente, y **el registry local con CA propia**:
el `x509: certificate signed by unknown authority` al traer una imagen, que se arregla en tres
sitios distintos según quién tire de ella —el motor del host, el containerd de los nodos de kind y
los clientes del host—. Es el mejor 🦭 del curso: Docker no lo muestra con `localhost`, porque trata
`127.0.0.0/8` como registry inseguro por defecto, y Podman sí, porque no hace esa excepción y la CA
va dentro de su máquina. Cada uno con su síntoma, su evidencia, su causa y su primer comando.

**Incluye** mTLS entre `inventory` y `pricing` en su versión a mano (paso G8). La versión con mesh
es apéndice.

#### 🛡️ Fase 20 — Seguridad del pod y de la red · *media*

**Trae:** `securityContext`, `runAsNonRoot` y las capacidades, que cobran lo que la Fase 03 sembró
sobre permisos; RBAC en versión mínima y provocada por un fallo real —por qué tu pod no puede leer
un Secret—; y `NetworkPolicy`.

**🧨 Con el experimento que lo justifica:** por defecto, en un cluster, **todo el mundo puede
hablar con todo el mundo**. Se demuestra exponiendo la base de datos por accidente, y se arregla en
dos minutos. Es la lección de seguridad más transferible del curso. Y la segunda lección, que llega
sola: una `NetworkPolicy` no hace nada si la red del cluster no la aplica. kindnet sí la aplica en
la versión fijada (verificado en P11), y la fase lo dice, con la advertencia de que no es
universal.

**🏘️ Y el aislamiento entre cadenas (D24):** con las dos cadenas de la F14 encendidas, una
`NetworkPolicy` que impide que los servicios de `apps-b` lleguen a los de `apps` y a sus bases. Lo
que la `NetworkPolicy` no resuelve —datos de las dos cadenas en el mismo Postgres, identidad— se
declara como frontera de un SaaS de verdad, fuera del curso.

**🩺 Incidentes:** `runAsNonRoot` contra una imagen que corre como root, y la política de *default
deny* que corta también el DNS.

**🔥 Deja como apéndice:** el service mesh. Es la respuesta real a media Parte IV y verlo funcionar
cambia el criterio, pero cuesta memoria, un plano de control entero y complejidad conceptual
encima de un lector que acaba de conocer los `Service`.

#### 🩻 Fase 21 — Diagnóstico: el kit y el cuaderno · *densa*

**Trae:** el kit completo de trabajo —`describe`, `logs --previous`, `events`, `exec`,
`port-forward`, contenedores efímeros de depuración y k9s—, cada herramienta estrenada en el
incidente que la necesita y nunca en una lista.

**Y abre formalmente el cuaderno de incidentes de plataforma**, que a esta altura ya tiene entradas
de fases anteriores. Aquí se enseña **el método**: síntoma, evidencia, hipótesis, primer comando,
causa, corrección, prevención. El reflejo de los primeros treinta segundos es donde se gana o se
pierde una guardia.

> 🧭 Esta fase es la que convierte al lector de alguien que despliega en alguien que **diagnostica**,
> que es la diferencia entre haber hecho un tutorial y saber operar.

### Parte IV · El lab de patrones distribuidos

Es donde el curso demuestra su tesis: **nada de esto lo resuelve Kubernetes.**

#### 🔥 Fase 22 — Resiliencia, y el generador de caos · *media*

**Construye:** el generador de caos del curso —código propio en Go, generado como los servicios, no
una herramienta externa— que inyecta latencia, errores intermitentes y respuestas malformadas entre
servicios. Y las respuestas en `inventory` (paso G9).

**Trae:** el fallo en cascada, el timeout que no pusiste, el reintento que empeora las cosas; y
timeouts, backoff y circuit breaker como respuestas. **Con la pregunta que ordena la parte
entera:** ¿esto va en tu código o en la plataforma? Es la tesis del curso aplicada a una decisión
cotidiana.

#### 🔌 Fase 23 — gRPC, y el balanceo que no balancea ⭐ · *densa*

**Construye:** la llamada entre `inventory` y `pricing` migrada a gRPC, con su contrato en
Protobuf. Y **enciende Tempo**: aquí por fin hay algo que trazar.

**Trae:** contratos binarios y HTTP/2, y el fallo que hace que esta fase exista: **el balanceo de un
`Service` funciona por conexión, y gRPC mantiene la conexión abierta — así que todo tu tráfico se
va a una sola réplica.** Es sutil, es medible, y es específico de la combinación. Exactamente el
tipo de cosa que este curso existe para enseñar.

**Trae también** las trazas distribuidas con OpenTelemetry y el `trace-id` propagado, que es lo único
que responde *"¿por qué esta venta tardó ocho segundos?"* cuando pasó por cuatro servicios. Es el
paso G10, y es donde los cuatro runtimes se separan otra vez: agente en Java, SDK en Node y en Go, y
extensión en PHP.

#### 🎬 Fase 24 — La saga orquestada · *densa*

**Construye:** el flujo de venta como saga coordinada por `inventory`, con sus compensaciones
escritas a mano (paso G11). Es el préstamo entre vecinas de la historia: reservar en la droguería
que tiene, despachar, cobrar; y si algo falla, liberar la reserva, reembolsar, o dejar el pedido
**pendiente** con aviso al cliente. *"Siempre llega"* no significa *"siempre llega ya"*.

**🏚️ Abre con el procedimiento (D28):** hoy el préstamo es un procedimiento en PL/pgSQL dentro de
Contingencia, una transacción en una sola base. La fase lo saca de la base y lo convierte en una
saga entre servicios: es la única pieza del PL/SQL de la historia que Paracelso toca, y la toca para
sacarla de la base.

**⚰️ Y con la saga que ya existía (D30):** el aviso de traslados por archivo es un proceso de dos
pasos entre dos sistemas —Contingencia descuenta, la Braqui despacha— sin ninguna compensación. Si
el traslado no llega, nadie devuelve la unidad. Se muestra antes de escribir la primera
compensación, y es el origen de los huérfanos de los lunes.

**Trae:** que no hay transacción distribuida gratis, y que **"deshacer" es una operación de
negocio, no técnica**. Se provoca el fallo a mitad de saga con el generador de caos de la Fase 22 y
se observa el sistema a medio compensar.

#### 📡 Fase 25 — La coreografía, y los mensajes que se pierden · *densa*

**🧨 Abre rompiendo, otra vez a propósito.** Se monta la coreografía sobre el pub/sub de Valkey.
Funciona. Se reinicia un consumidor durante una venta, y el mensaje **no existió nunca**. La
motivación de todo lo que sigue se siente en vez de explicarse.

**Construye:** la misma coreografía sobre NATS con JetStream, con entrega *al menos una vez* (paso
G12).

**🏚️ El antecedente (D30):** el `.txt` leído a medio subir y el `.ok` que llega antes que su
archivo son el mismo mensaje que no existió nunca, en la versión de 2020: nadie confirma la
lectura y nadie mide la pérdida. El *ack* de JetStream es lo que al script le faltó siempre.

**Trae:** el desacoplamiento por eventos; el contraste directo con la saga orquestada y el ⚖️
veredicto de cuándo conviene cada una, que es lo que nadie te dice; y la factura inmediata del
arreglo: **si entrego al menos una vez, entrego dos veces.**

#### 🔁 Fase 26 — Idempotencia y outbox ⭐ · *densa*

**🧨 Abre con las dos motos**: dos droguerías contestan el mismo pedido de préstamo y al cliente le
llegan dos motos con el mismo inhalador.

**🏚️ Y con los dos parches que no alcanzaron (D30):** la tabla de archivos procesados usa como
clave el nombre del archivo, y el lote reintentado genera otro nombre con los mismos traslados; y
el `.txt` se escribe después del commit, que es la escritura dual tal como la hizo La Vecina. La
clave de idempotencia es el ID del traslado, y el outbox reemplaza al archivo.

**Trae:** claves de idempotencia y operaciones que se pueden repetir sin daño, que es la
consecuencia directa de la fase anterior; y **el patrón outbox** — escribir el evento en la misma
transacción que el dato, con un proceso aparte que lo publica. Resuelve la escritura dual, que es
el bug distribuido más común y el peor diagnosticado. Es el paso G13, y el publicador del outbox es
el sitio natural para mostrar un contenedor *sidecar* nativo.

**🚫 Deja fuera, declarándolo:** event sourcing y CQRS. Son patrones de arquitectura de datos, no
de infraestructura, y se comen un curso entero.

### Cierre

#### ⚖️ Fase 27 — El veredicto honesto, y el proyecto final · *densa*

**El veredicto:** cuándo **no** necesitabas nada de esto, en dos ramas: La Vecina sola, y La
Vecina con una segunda cadena encima, que es la que cambia la cuenta. Un árbol de decisión honesto que empieza
por la pregunta que el curso lleva veintisiete fases ganándose el derecho a hacer: ¿esto lo
resolvía un contenedor y un servicio del sistema? ¿Lo resolvía compose en una máquina? ¿De verdad
necesitas un orquestador, o necesitas dos servidores y una lista de comprobación?

**🌩️ Y el diccionario local ⇄ nube consolidado**, en las dos direcciones, con la 🚧 frontera de lo
que el laboratorio nunca pudo darte: un plano de control gestionado y su disponibilidad, un
balanceador de verdad, multi-zona, autoescalado de nodos, identidad de carga de trabajo, y el coste
como restricción de diseño.

**El proyecto final:** desplegar un servicio nuevo de cero —su contrato, su imagen, su subchart, sus
probes, sus límites, sus métricas, su `HTTPRoute` y su papel en la saga— sin que ninguna fase lo
explique, y hacer que la suite de conformidad y el tablero de la plataforma lo reconozcan sin tocar a
los otros cuatro. Es el mejor criterio de éxito que el curso puede darse.

---


## 6. 🎨 Apéndices

No cuentan como camino base y no llevan peso declarado. Qué cubre cada uno, qué deja fuera y cuándo
se escribe está en [`propuesta-apendices-y-alcance.md`](propuesta-apendices-y-alcance.md); aquí va
solo el mapa.

| Apéndice | Qué es |
|---|---|
| `a01` | **El laboratorio**: versiones fijadas, el Taskfile, los perfiles y el presupuesto de memoria. El único sitio del curso donde vive una versión |
| `a02` | Solución de problemas del ambiente, por plataforma. La cola larga de la Fase 00 |
| `a03` | **Los contratos y los prompts de generación**: OpenAPI, la suite Hurl y la matriz de pasos. Sostiene la decisión de método de la §1 |
| `a04` | Referencia rápida de `kubectl` y de k9s |
| `a05` | 📖 Los diccionarios: compose ⇄ Kubernetes, `Ingress` ⇄ Gateway API, local ⇄ nube 🌩️ |
| `a06` | 🔥 Arquitecturas y builds multiplataforma: ARM contra amd64, y la imagen que corre lentísima bajo emulación |
| `a07` | 🔥 Construir imágenes sin Docker: Buildah, Kaniko y los constructores por lenguaje |
| `a08` | 🔥 La JVM nativa: compilación nativa contra AOT cache, medido |
| `a09` | 🔥 Qué cambia cuando el frontend necesita un runtime: renderizado en servidor |
| `a10` | 🔥 Service mesh: mTLS automático, reintentos y métricas de red sin tocar el código |
| `a11` | 🔥 GitOps, de lectura |
| `a12` | 🔥 Operators y recursos propios, de lectura |
| `a13` | 🔥 Respaldo y restauración de los datos del cluster |
| `a14` | 🔥 Las GUI del cluster y de los motores: cuándo ayudan y cuándo estorban |
| `a15` | 🔥 Un `StatefulSet` de varios miembros: arranque ordenado y failover |
| `a16` | 🏚️ **El patrimonio**, de laboratorio: Contingencia, el portal y la Braqui, cómo están hechos y con qué prompts. Se escribe antes de F00, en la tanda T1b |

---

## 7. 📓 El cuaderno de incidentes

Un único archivo, `cuaderno-incidentes.md`, con **27 incidentes** de IDs globales que no se
reasignan. Su especificación completa, con el catálogo de IDs reservados, está en
[`formato-cuaderno-incidentes.md`](formato-cuaderno-incidentes.md).

| Familia | Cuántos | De dónde salen |
|---|---|---|
| 🩺 Ambiente | 5 | Fase 00 (el 27, el proxy corporativo, se sumó después y conserva su número) |
| ☸️ Plataforma | 15 | Fases 08 a 16 y 20 |
| 🔐 Certificados | 7 | Fase 19 |

Cada incidente traduce a git con el par de tags `inc/<ID>/<slug>-roto` e `inc/<ID>/<slug>-fix`, de
modo que el `git diff` entre los dos **es** la corrección aislada del ruido de la fase, y la tarea
`task inc:break -- <ID>` lleva el laboratorio al estado roto sin tocar el historial.

> 🧭 **El formato es el mismo siempre:** qué provocar, qué síntoma esperar, **qué mirar en los
> primeros treinta segundos**, cuál es la causa, cómo se arregla, y cómo se previene. El tercer
> punto es el que hace útil al cuaderno; sin él es una lista de errores.

Las roturas de la Parte IV —el tráfico gRPC en una sola réplica, el mensaje que se pierde en el
pub/sub, la venta cobrada dos veces— son **experimentos 🧨 de su fase**, no incidentes: su causa es
de diseño y no se diagnostica con `kubectl`.

---

## 8. 📏 Las mediciones del curso

Seis, todas con el mismo arnés (`task measure`), todas consolidadas en `BENCHMARKS.md` con la
declaración del entorno de referencia y el formato de la guía §6.1. Más una de preparación, la del
presupuesto de memoria, que se publica en `a01`.

| ID | Fase | Hipótesis, en una línea |
|---|---|---|
| B-00 | `a01` | Cuánta memoria del host ocupa cada perfil, con cada motor, en macOS arm64 |
| B-04 | 04 | El costo de empaquetar cada runtime: tamaño, build en frío, build con caché, arranque |
| B-05 | 05 | Los dos motores: creación del cluster, build y memoria del host en reposo |
| B-07 | 07 | Los clusters locales: arranque, memoria en reposo, multi-nodo |
| B-12 | 12 | Pruebas contra SQLite frente a pruebas contra el motor real: tiempo de suite y fidelidad |
| B-16 | 16 | Réplicas necesarias por runtime para sostener la misma tasa, y memoria por réplica |
| B-23 | 23 | Distribución del tráfico gRPC entre réplicas, antes y después del arreglo |

Y las reglas de honestidad, que son las que hacen que el curso sobreviva a un lector escéptico:
se publica lo que salió y no lo que esperabas · **el empate se llama empate** · nada de números
redondos sin dispersión · el competidor se configura bien · se declara lo que no se midió · y
nunca se extrapola.

---

## 9. 📁 Convención de nombres y de git

**Fases:** `NN-slug.md`, de `00-` a `27-`, con los slugs de §11.
**Apéndices:** `aNN-slug.md`, de `a01-` a `a16-`, con los slugs de la propuesta de apéndices §2.
**Documentos de raíz:** `00-historia-de-la-vecina.md`, `00-convencion-de-git-y-tags.md`,
`BENCHMARKS.md`, `INSTINTOS.md`, `cuaderno-incidentes.md`; y al final, `README.md` y
`0-ESTRUCTURA-CURSO.md`.
**Código:** un único proyecto, `src/lab/`, porque el curso construye **un solo artefacto** que crece
fase a fase. Su estructura está en el contrato del cluster §2.

**Git:** el del contrato del cluster §8 — tags `fase-NN-<slug>`, commits `fNN:`, incidentes con su
par de tags, y apéndices sin tag salvo `a01`, `a03` y `a16`.

---

## 10. 🚫 Lo que queda fuera del alcance

Reunido aquí para que cada exclusión sea visible y no se pierda entre las fases. Se declara y el
texto se detiene: **no se dice dónde estaría ese material.**

cgroups y namespaces por dentro · SBOM, firma de imágenes y cadena de suministro · gestores de
secretos externos · alertas y cadena de guardia · event sourcing y CQRS · desplegar en una nube de
pago · escribir un Operator propio · un segundo motor relacional · Kafka · compose como herramienta
de producción · **`Ingress` y sus controladores**, salvo como traducción · **JVM anteriores a la 25,
Jakarta EE y MicroProfile** · la semilla de ciencia de datos · profundidad de negocio en el dominio
de inventario, que se mantiene mínimo a propósito.

Si algo interesante aparece fuera de alcance mientras se escribe, se registra como **pendiente 📌**
con su destino sugerido. No se infla la fase actual.

---

## 11. 📊 Resumen de fases

| # | Archivo | Parte | Peso | Ejercicios | Incidentes | 📏 |
|---|---|---|---|---|---|---|
| 00 | `00-el-ambiente.md` | 0 | media | 20 | 01–04, 27 | |
| 01 | `01-primer-contenedor-y-dockerfile.md` | 0 | media | 20 | | |
| 02 | `02-compose-el-sistema-en-un-archivo.md` | 0 | media | 20 | | |
| 03 | `03-el-contenedor-por-dentro.md` | I | media | 20 | | |
| 04 | `04-empaquetar-los-cuatro-runtimes.md` ⭐ | I | densa | 24 | | B-04 |
| 05 | `05-los-dos-motores.md` | I | ligera | 12 | | B-05 |
| 06 | `06-del-compose-al-cluster.md` | I | densa | 24 | | |
| 07 | `07-el-cluster-local.md` | II | media | 20 | | B-07 |
| 08 | `08-el-primer-despliegue.md` ⭐ | II | densa | 24 | 05–06 | |
| 09 | `09-los-cuatro-servicios-dentro.md` | II | media | 20 | 07 | |
| 10 | `10-la-entrada-al-sistema.md` | II | media | 20 | 08 | |
| 11 | `11-configuracion-y-secretos.md` ⭐ | II | media | 20 | 09–10 | |
| 12 | `12-estado-y-almacenamiento.md` | II | densa | 24 | 11 | B-12 |
| 13 | `13-helm-el-paquete.md` | II | densa | 24 | | |
| 14 | `14-helm-en-operacion.md` | II | media | 20 | | |
| 15 | `15-salud-y-recursos.md` ⭐ | II | densa | 24 | 12–15 | |
| 16 | `16-escalado-y-rollout.md` | II | densa | 24 | 16–17 | B-16 |
| 17 | `17-metricas-y-dashboards.md` | III | densa | 24 | | |
| 18 | `18-logs.md` | III | media | 20 | | |
| 19 | `19-tls-y-certificados.md` ⭐ | III | densa | 24 | 18–24 | |
| 20 | `20-seguridad-del-pod-y-de-la-red.md` | III | media | 20 | 25–26 | |
| 21 | `21-diagnostico.md` | III | densa | 24 | | |
| 22 | `22-resiliencia-y-caos.md` | IV | media | 20 | | |
| 23 | `23-grpc-y-el-balanceo.md` ⭐ | IV | densa | 24 | | B-23 |
| 24 | `24-la-saga-orquestada.md` | IV | densa | 24 | | |
| 25 | `25-la-coreografia.md` | IV | densa | 24 | | |
| 26 | `26-idempotencia-y-outbox.md` ⭐ | IV | densa | 24 | | |
| 27 | `27-el-veredicto-y-el-proyecto-final.md` | Cierre | densa | 12 | | |
| | **Total** | | | **604** | **27** | **6** |

Catorce fases densas, doce medias, una ligera y el cierre. Los slugs son canónicos: una fase no se
renombra una vez escrita.

---

## 📌 12. Registro de decisiones

Lo que sostiene este temario. **Cerradas por Oskar el 30/09/2026**, salvo D30 y D31: D1–D5 al resolver
las contradicciones del material preliminar, D8–D17 sobre la propuesta de valores, D18–D25 al
cerrar la historia y sus pendientes, D26–D29 al decidir el patrimonio de arranque, D30 el
02/10/2026, al sumar a la historia el aviso de traslados por archivo, y D31 el 03/10/2026, al fijar
Python como lenguaje de scripting, y D32 el 03/10/2026, con lo que fijó la verificación de
laboratorio (P11). D33 y D34 las cerró Oskar durante la producción; D35 a D43 las tomaron las sesiones de producción por defecto, y Oskar las revisó y confirmó el 05/10/2026 (con la marca de la segunda cadena en D37 y la excepción del cuaderno en D40). D44 la pidió Oskar en la revisión del curso cerrado contra los lineamientos de producción. Si una decisión cambia, se cambia primero en
su sitio y después aquí.

| ID | Decisión | Valor | Estado | Manda en |
|---|---|---|---|---|
| D1 | Stack | Spring Boot 4 · Java 25, Laravel con PHP-FPM + nginx, NestJS · Node 24, Go, React · Vite. Sin Jakarta EE ni MicroProfile | ✅ | alcance §7.2 |
| D2 | Piloto | `pricing` | ✅ | §4.2 |
| D3 | JVM | Java 25 tal cual; JVM anteriores y MicroProfile como extensión futura fuera del curso | ✅ | alcance §15 |
| D4 | Entrada | Gateway API; ningún objeto `Ingress` desplegado | ✅ | alcance §8, §3.5 |
| D5 | Tamaño | Mínimo posible: kind de un nodo por defecto, observabilidad por piezas, tres perfiles; lo publicado es lo medido | ✅ | alcance §7.4 |
| D6 | Código de `src/` preliminar | Borrado `src/microk8s-lab`; se conserva `switch-container.ps1` para revisarlo en T1 | ✅ | — |
| D7 | Desechables | `06-…`, `07-…` y el temario candidato pasan a `_desechable-*` | ✅ | — |
| D8 | Punto de entrada | Taskfile (go-task) | ✅ | contrato §7 |
| D9 | Plataformas | **El autor verifica solo en macOS arm64.** Windows 11 y Linux se escriben desde la documentación oficial, marcados como no verificados, y se verifican al hacer el curso | ✅ | alcance §8, guía §12 |
| D10 | Método de generación | OpenAPI 3.1 + suite Hurl + matriz G0–G13, y **Swagger UI** en un contenedor para documentar los contratos; Claude Code como herramienta de referencia | ✅ | contrato §6–§7, `a03` |
| D11 | Ejercicios | 12 / 20 / 24 por peso; 12 en F27 | ✅ | guía §9 |
| D12 | Controlador de Gateway | **Envoy Gateway**. La Fase 10 nombra las alternativas (Traefik, NGINX Gateway Fabric, kgateway, Istio, Cilium) con ventajas y desventajas, sin instalarlas | ✅ | §3.5, contrato §9 |
| D13 | Cuaderno | 26 incidentes; se suma el del registry con CA propia (27 con D20) | ✅ | formato del cuaderno |
| D14 | Apéndices | Quince, renumerados (dieciséis con `a16`, D19); se suman `a01` (laboratorio), `a05` (diccionarios) y `a08` (JVM nativa) | ✅ | propuesta de apéndices |
| D15 | Mesh (`a10`) | **Istio** en modo ambient; Linkerd y Cilium nombrados como alternativas | ✅ | propuesta de apéndices |
| D16 | Comparación de clusters | kind, k3d, minikube y el Kubernetes de Docker Desktop; MicroK8s fuera | ✅ | Fase 07 |
| D17 | Versiones | **Todo en su última LTS**, y donde no haya línea LTS, en su última estable, a la fecha de la verificación; por digest en `a01` | ✅ | `a01` |
| D18 | La empresa | **Droguerías La Vecina**, cooperativa de droguistas de Santander que creció a Boyacá, Cundinamarca y Bogotá; el curso es su POC, el proyecto Paracelso de la unidad Alquimia, construido en La Rebotica | ✅ | historia |
| D19 | El patrimonio | **Reescrita el 01/10/2026**: el taller arranca con el patrimonio de La Vecina —Contingencia (el código del Siga en Eclipse GlassFish y Postgres), el portal y la Braqui—, creado con prompts antes de escribir capítulos (tanda T1b) e insumo de los servicios nuevos | ✅ | alcance §12, `a16` |
| D20 | Incidente del proxy | El proxy corporativo con inspección TLS entra como incidente **27**, de ambiente, reservado por la F00 | ✅ | formato del cuaderno |
| D21 | Nube en el diccionario | Columnas OCI y Azure, con AWS y Google nombradas; el curso no elige | ✅ | `a05` |
| D22 | Dominio | Fuera fórmula, lotes, cadena de frío, control especial y EPS; "pendiente" como estado de compensación; préstamo como `replenishmentOrder` entre `store` | ✅ | alcance §7.1, historia §8 |
| D23 | Precio regulado | Regla configurable de `pricing` (tope), con su tabla en un `ConfigMap` | ✅ | contrato §3, Fase 11 |
| D24 | El producto embrionario | La idea de vender el sistema como SaaS (historia §1.12–§1.13) entra como motivo de negocio, como la cuarta pregunta del POC y con **nivel 2**: la rama nueva del veredicto en F27, un segundo release del chart (`tenant-b` en `apps-b`) en F14, cuotas por namespace en F15 y aislamiento entre cadenas en F20. Sin apéndice propio | ✅ | historia, alcance §7.1 y §11, contrato §4 |
| D25 | Motor de `a15` | NATS con JetStream en tres miembros: ya está en el stack y su quórum deja provocar el failover | ✅ | propuesta de apéndices |
| D26 | Contingencia y Postgres | La base del patrimonio es Contingencia, y Postgres viene de la historia: entró en 2016 porque el comité no definió a tiempo las licencias de Oracle | ✅ | historia §1.7, alcance §12 |
| D27 | *Strangler* | Camino base, en la Fase 10, con Contingencia detrás del `Gateway` | ✅ | F10 |
| D28 | El procedimiento del préstamo | La Fase 24 lo lleva de PL/pgSQL en Contingencia a una saga entre servicios; es el único PL/SQL que el curso toca | ✅ | F24, `a16` |
| D29 | `a16` | Pasa de 🔥 a apéndice de laboratorio, "El patrimonio", con su tanda propia (T1b) antes de F00 | ✅ | propuesta de apéndices |
| D30 | El aviso de traslados por archivo | La historia (§1.9, §1.11) suma la integración de 2020 entre el Siga y la Braqui: un `.txt` con su `.ok` en una carpeta compartida y un script de Python cada cinco minutos, con tres parches. **No abre track ni incidentes nuevos** (el cuaderno sigue en 27): entra al patrimonio de `a16` y sirve de hilo a F12 (`CronJob`), F24 (saga sin compensaciones), F25 (mensaje perdido) y F26 (idempotencia por nombre y escritura dual). Python entra como lenguaje de scripting del laboratorio, no como un stack | ✅ | historia §1.9, `a16`, F12, F24–F26 |
| D31 | Python para scripting | Python es el lenguaje de los scripts del laboratorio —uno solo para los tres sistemas, en vez de un `.sh` y un `.ps1`—, con `venv` y un `requirements.txt` por directorio de scripts. **Sin apéndice propio**: una sección corta en `a01` con lo mínimo y un ejemplo, el seed con Faker, que la F12 corre como `Job`. Ningún servicio está escrito en Python | ✅ | alcance §8, `a01`, F12 |
| D32 | Lo que fijó P11 | (1) **El nodo de kind en 1.36**: D17 se aplica como "la última estable que soportan todas las piezas", y Envoy Gateway 1.9 llega hasta Kubernetes 1.36. (2) **La entrada**: `extraPortMappings` + `NodePort` fijo 30080/30443 con `externalTrafficPolicy: Cluster`; cloud-provider-kind solo se muestra en la F10. (3) **Las imágenes con Podman** se construyen como `docker.io/lab/<svc>` y se cargan por archivo. (4) **4 GiB para la máquina virtual** de cada motor. (5) **Python 3.12 o superior**, sin versión exacta, porque el `venv` hereda la del sistema | ✅ | contrato §4, §5 y §7, `a01`, F05, F10 |
| D33 | El contrato REST de G1 | Revisado por Oskar el 03/10/2026. **Los datos maestros se editan; el estado se cambia con hechos.** `inventory`: la existencia solo cambia por movimientos —no hay `PUT /stock`—; los `ADJUSTMENT` exigen `reasonCode` y aceptan `reference` (el archivo de traslados perdido, la orden); el **`COUNT`** registra lo contado y guarda la diferencia con signo, y el primer `RESTOCK` o `COUNT` crea la existencia con umbral 0; el umbral se cambia con `PATCH`. `catalog`: `status` (`ACTIVE`/`DISCONTINUED`) con `PATCH`, descontinuar exige `reasonCode`, y se mantiene `POST`. `replenish`: una orden no se edita; se cancela en `PENDING` con `reasonCode` y se crea otra con `replacesOrderId`, y la cancelación pasa de G11 a G1 (la saga la reusa con `SAGA_COMPENSATION`). Los códigos de razón son **una tabla de datos por servicio** (`GET /reason-codes`), no un enum del contrato | ✅ | `src/lab/contracts/openapi/`, `a03`, `CLAUDE.md` de los servicios |
| D34 | `catalog` en dos contenedores | Decidida por Oskar el 03/10/2026, al abrir T3. **PHP-FPM y nginx son dos contenedores**, no dos procesos en una imagen: `lab/catalog` es FPM con la aplicación, y nginx es la imagen oficial sin privilegios con un `nginx.conf` del repositorio. En compose comparten red con `network_mode: service:catalog` (el puente a la F06: eso es un pod); en la F09 son dos contenedores del mismo pod. Evita un supervisor de procesos como proceso 1 (F03) y deja a la F15 la pregunta de quién responde la sonda | ✅ | contrato §2 y §3, F04, F09, F15 |
| D35 | G1 | Tomada por la sesión de T4 con permiso de Oskar ("por default"); **confirmada por Oskar el 05/10/2026**. El SQLite de G1 vive en `DATA_DIR` (`/var/lib/<svc>`), una carpeta de la imagen a nombre del usuario; el esquema se crea al arrancar y solo se siembran los códigos de razón. El `storefront` pide `GET {API}/catalog/products` desde el navegador, con la dirección horneada al compilar (`http://api.localhost:8080`): en la F09 no llega, la F10 abre la puerta (con CORS en el `Gateway`) y la F11 cobra el horneado. Las imágenes llevan además el tag del paso (`:g1`), que piden los manifiestos con `IfNotPresent`. La suite corre en el cluster con `task conformance TARGET=cluster -- G1` | ✅ | `a03`, contrato §3, F09–F11 |
| D36 | T5 | Tomadas por la sesión de T5 con permiso de Oskar ("sigue con T4 y T5"); **confirmadas por Oskar el 05/10/2026**. **F10:** la fachada REST de precios de Contingencia (`PriceFacadeServlet`, con `X-Contestado-Por`) detrás de un nginx en su mismo pod (8081), porque Envoy Gateway rechaza `URLRewrite` dentro de un `backendRef`; el *strangler* reparte por pesos en la `HTTPRoute` de `pricing`, con un `ReferenceGrant` y un `Job` que migra los 64 precios; CORS con el **filtro del estándar** (`HTTPRouteCORS`), no con la `SecurityPolicy` de Envoy Gateway. **F11:** G2 con la plantilla de la imagen de nginx (`/config.json` con `API_BASE_URL` y `BRAND_NAME`, `no-store`; `index.html` con `no-cache`); un tag por servicio (`STEP_TAGS`, el del último paso que lo cambió); los valores de los `Secret` en `.secrets/` (fuera de git), y Contingencia leyendo el mismo `Secret` que el portal; el `.env` del portal re-incluido en git (`!legacy/portal/.env`) porque la raíz ignora todos los `.env`. **F12:** Postgres 18 en un `StatefulSet` propio en `data`, con una base y un usuario por servicio (credenciales generadas por `scripts/data/credentials.py`); G3 con `DATABASE_URL` y **el SQLite de G1 como respaldo cuando no está** (compose sigue igual); migraciones con un comando de cada servicio, como `Job`, que `task deploy` corre antes de aplicar; el seed carga por la API (`load.py`); las pruebas de `pricing` con Testcontainers para B-12; la Braqui en `legacy` y el aviso de traslados como `CronJob`, con la carpeta compartida en un PVC. **Quedan abiertas a propósito:** la carrera de `inventory` (F16) y el `INTEGER` de los precios (ejercicio de F12) | ✅ | `a03`, contrato §2 y §3, F10–F12 |
| D37 | T6 | Tomadas por la sesión de T6 (Oskar: "trabaja en esta sesión tandas T6-T10"); **confirmadas por Oskar el 05/10/2026**. **F13:** chart paraguas `charts/platform` (release `lab` en `apps`) con un subchart por servicio y una librería `lab-common` que es dependencia del paraguas y que los subcharts usan por el espacio global de plantillas (un subchart no se instala solo); el `Deployment` de cada servicio queda escrito en su subchart, y solo `Service`, `HTTPRoute` y el `Job` de migraciones van en la librería; el tag de cada imagen sin valor por defecto (`required`), pasado por `task deploy` desde `STEP_TAGS`; namespace, `Secret` de las bases, Postgres, la puerta y el patrimonio fuera del chart; migraciones como hooks `pre-install,pre-upgrade` y el seed `post-install`; el hash de los `ConfigMap` en el pod; el `nginx.conf` de `catalog` como enlace simbólico; la mudanza recomendada es borrar y reinstalar (15,7 s de corte), no `--take-ownership`; `task deploy FORCE=true` agrega `--force-conflicts` y `inc:fix` lo usa. **F14:** `task deploy` con `--rollback-on-failure --history-max 10`; `task deploy:diff` con `--three-way-merge`; `values.schema.json` en el paraguas (réplicas enteras, hosts que terminan en `.localhost`); la segunda cadena con hosts `*.tenant-b.localhost`, marca **Droguerías Río Negro** (Oskar, 05/10/2026: la cadena de Don Rodrigo nació en Rionegro; no se encontró ninguna cadena real con ese nombre), cuarenta droguerías en el seed, y bases `<svc>_tenant_b` en el mismo Postgres (`task platform:postgres TENANT=tenant-b`); Kustomize solo como comparación en `deploy/kustomize/lab` | ✅ | contrato §2, §4 y §7, F13, F14 |
| D38 | T7 | Tomadas por la sesión de T7; **confirmadas por Oskar el 05/10/2026**. **Historia:** el `-Xmx` heredado de WebLogic pasa a ser `-Xmx4096m` (§1.6); la autopsia de la F15 usa `-Xms4096m -Xmx4096m`, porque solo con `-Xmx` la JVM no murió. **G4:** readiness por la base con un segundo de límite, sin vecinos; `inventory` sin Actuator (`ApplicationAvailability`); el manejador de `error` del pool de `pg`. **Chart:** sondas y recursos medidos por servicio, sin límite de CPU; `pricing` con 128 MiB de límite desde la F16; cuotas y `LimitRange` en `apps` (1.536 MiB / 3 GiB) y `apps-b` (1 GiB / 1,5 GiB); `preStop` de 5 s, `maxSurge 1`/`maxUnavailable 0`, `progressDeadlineSeconds 120`; HPA por valor, y sin `replicas` en el `Deployment` cuando existe. **Incidentes:** 12 = `MaxRAMPercentage=95` con `AlwaysPreTouch`; 13 = la contraseña del `Secret` de `replenish`; 14 = la liveness de `catalog` a 1 s con carga; 15 = Postgres pidiendo 4 GiB en `data` (en `apps`, la cuota lo rechaza antes); 16 = una `DATABASE_URL` equivocada en la versión nueva de `inventory`; 17 = metrics-server sin `--kubelet-insecure-tls`. **G5:** la venta con `RestClient` sin timeouts, la carrera cerrada con `FOR UPDATE`, el aviso en un hilo virtual por la cantidad del umbral, y la venta desde la página con CORS en las rutas de `pricing` e `inventory`; el contrato de `/sales` suma 422 y 503. 🔥 `Dockerfile.aot` fuera del chart. B-16 a 300 peticiones/s en el perfil `medicion` sobre `lab` | ✅ | historia §1.6, contrato, F15, F16, `a03` |
| D39 | T8 | Tomadas por la sesión de T8; **confirmadas por Oskar el 05/10/2026**. **G6:** el histograma `http_server_requests_seconds` (method, uri, status) con el nombre de Spring en los cuatro; lo que no tiene ruta, `uri="/**"`; `inventory` con Actuator solo para `/metrics` y la primera métrica de negocio (`lab_sales_total`); APCu en `catalog`; `@prometheus-io/client` en `replenish`. **Observabilidad:** subcharts del umbrella con sus objetos en `observability`; `scrape_config` a mano con las labels del contrato y cAdvisor recortado a dos métricas; Grafana anónimo con rol `Editor` y un tablero RED; `task obs:on` guarda los interruptores en `.observability.json` (no versionado), encender `logs` enciende Grafana y Prometheus. **F17 y F18 corren en el cluster `lab` con los valores de `minimo`**, por la memoria (H154–H155). **G7:** campos `time`, `level`, `service`, `msg` y la línea `request` con `method`, `uri`, `path`, `status`, `duration_ms`, `request_id`; el id de `X-Request-Id`, que pone Envoy, y que `inventory` reenvía; la única línea en texto aceptada, `Picked up JAVA_TOOL_OPTIONS`; la suite de G7 con un verificador de logs en Python. **Loki y Fluent Bit:** un proceso y un `DaemonSet` sin `toleration` del control-plane; etiquetas `namespace`, `service`, `container`. **Antipatrones medidos:** la ruta cruda como etiqueta (F17) y el `request_id` como etiqueta de Loki (F18) | ✅ | contrato, F17, F18, `a01`, `a03` |
| D40 | T9 | Tomadas por la sesión de T9; **confirmadas por Oskar el 05/10/2026**. **F19:** la CA del laboratorio con `cryptography` (`scripts/tls/certs.py`), claves en `.secrets/tls/`; listener `https` en el 8443 con `Terminate`; cert-manager y trust-manager por OCI con imágenes por digest, `ClusterIssuer lab-ca` de tipo CA y el `Certificate` de la puerta de 24 h; el `Bundle` reparte la CA a los namespaces con `part-of: lab`; la confianza en el host la instaló Oskar en su llavero el 05/10/2026 (H270; receta en `a01`). **G8:** `pricing` con un 8443 mTLS y el 8080 en HTTP; `inventory` con *SSL bundle* PEM y recarga; `global.mtls.enabled` encendido desde F19; la dirección `https` solo en el `Deployment` de `inventory`. **Registry:** `lab-registry` (`registry:3` por digest) con tareas `registry:*`. **Incidentes:** 18 = un certificado de 2 min puesto a mano (uno ya vencido no lo carga la puerta); 21 = un `Secret` TLS en YAML; 22 = el emisor sin su `Secret`; 23 = el bundle sin certificado de cliente; 24 = los nodos sin `certs.d`. **F20:** `global.podSecurity.enabled` y `global.networkPolicy.enabled` encendidos desde F20; `emptyDir` en `/tmp`; Postgres como 999; 25 = `runAsNonRoot` en Postgres; 26 = sin `allow-dns`. **F21:** casos de práctica sin ID; la revisión del cuaderno aceptó dos desviaciones: 01–03 y 27 dicen la línea de su primer comando en prosa (son de ambiente), y **las autopsias de F19 y F20 cuentan la causa de los incidentes 18 y 26** desde la decisión que los produce (excepción declarada en el formato del cuaderno) | ✅ | contrato, F19, F20, F21, cuaderno, `a01`, `a03` |
| D41 | T10 | Tomadas por la sesión de T10; **confirmadas por Oskar el 05/10/2026**. **F22:** el generador de caos en Go (solo biblioteca estándar) entre `inventory` y `catalog`, con perfiles de ciudad; G9 con el núcleo de Resilience4j 2.3.0 (sin su integración con Spring), timeouts de 1 s y 2 s, 3 intentos con espera y circuito al 50 %; el `POST` a `replenish` sin reintentos. **F23 / G10:** `pricing` sirve `GetPrice` en el 9090 con el mismo mTLS del 8443; el código de Go se genera con `task proto` y se versiona, el de Java lo genera Maven con `--build-context proto`; **por defecto, `global.grpc.balancing: client` (headless `pricing-grpc` con `round_robin`) y `global.grpc.maxConnectionAge: 10s`**, porque B-23 midió que el balanceo en el cliente solo no ve una réplica nueva (0 de 1200); en producción, la edad se mediría en minutos. El proxy de capa 7 queda sin medir (ejercicio 21, `a10`). Trazas: Tempo 3 con `backend_worker` (no `compactor`); OpenTelemetry por variables `OTEL_*` del chart, apagado con `OTEL_SDK_DISABLED`; `Context.current().wrap(...)` en el hilo del aviso a `replenish`; `task obs:trace` para leer una traza en la terminal. **Abierto:** con Tempo caído, `catalog` (PHP) cuelga peticiones hasta 15 s al exportar; la fase lo deja medido y como ejercicio 22 (timeout corto o un Collector en el nodo), sin arreglarlo en el chart | ✅ | contrato, F22, F23, `a01`, `a03`, `BENCHMARKS.md` |
| D42 | T11 | Tomadas por la sesión de T11 (Oskar: "sigue con T11-T16"); **confirmadas por Oskar el 05/10/2026**. **F24 / G11:** el préstamo (`POST /loans`, 202) como saga orquestada en `inventory`, con el estado en `loans` y `loan_steps`; **orden RESERVE → DISPATCH → CHARGE → RECEIVE**: la ficha decía "reservar, despachar, cobrar" y el contrato de `replenish` ya pedía la cancelación como compensación, así que el cobro va al final como pivote (lo que más cuesta deshacer) y el reembolso no se escribe (ejercicio 23); el cobro es una fila de `sales` del destino sin movimiento; `LOAN_RELEASED` y `SAGA_COMPENSATION` como códigos de razón; `BACKORDERED` sin compensar; el barrido `@Scheduled` cada 30 s con reclamo por `UPDATE` condicionado; un span por paso; `task chaos:on TARGET=replenish`. **F25 / G12:** el evento `lab.inventory.stock-low` en `x-lab-events` del OpenAPI (no AsyncAPI); Valkey y NATS en `data`, fuera del chart, con `task bus:on|off`, y el chart solo escribe `EVENT_BUS`, la dirección y la regla de salida de la red; imágenes `-alpine` (cambio de los digests de P11, por el shell); la coreografía es el aviso de la venta, no el préstamo (que queda orquestado: la comparación es entre los dos). **F26 / G13:** `Idempotency-Key` en `sales`, `loans` y órdenes con índice único parcial; `processed_events` (y no un índice único sobre `source_event_id`, que los repetidos ya existentes habrían impedido); outbox solo con NATS (Valkey sigue publicando directo, como bus frágil); el publicador en Go como sidecar nativo con la misma imagen de `inventory`; la saga reintenta el despacho con la clave y lo busca al compensar; **la cancelación idempotente** (un cambio de contrato que encontró el laboratorio). Las trazas quedan apagadas al cerrar T11 | ✅ | contrato, F24–F26, `a01`, `a03` |
| D43 | T14 | Tomada por la sesión de T14; **confirmada por Oskar el 05/10/2026**. **F23:** con Tempo caído y las trazas encendidas, `catalog` (PHP, que exporta al final de cada petición) cuelga hasta el corte de la puerta (H202). **El chart no se cambia**: el fallo es la lección de la sección 6 de la F23 y su ejercicio 22 pide el arreglo (bajar el timeout del exportador, o un Collector en el nodo); con las trazas apagadas, el valor de todos los perfiles salvo `obs:on traces`, no aparece. **Herramientas:** `task inc:break|fix` toma `PROFILE` y `CLUSTER` (`INC_CONTEXT`, `INC_VALUES`); B-04 acepta `--path` y guarda la imagen con tag. | ✅ | F23, `a01`, Taskfile |
| D44 | Revisión contra los lineamientos | Pedida por Oskar el 05/10/2026, con el curso cerrado. **Diagramas en Mermaid:** siete diagramas de `text` a `mermaid` (`00-el-ambiente`, F06, F10, F27 ×2, `a03`, `a16`), cada uno dibujado con `mmdc` antes de publicarlo; se quedan en `text` las fichas de cierre de fase, los árboles de archivos, las salidas y capturas de terminal. **Anclas:** 32 enlaces a títulos con emoji corregidos al ancla que genera GitHub (con U+FE0F). **Verificador:** `prompts/verificar-corpus.py` sobre el perfil `courses-ia`, con `verificador_base.py` copiado de los lineamientos. Detalle en la guía §19 | ✅ | guía §19, `prompts/README.md` |
