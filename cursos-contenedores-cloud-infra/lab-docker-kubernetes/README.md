# 🧰 Laboratorio de contenedores y Kubernetes local

Un curso que enseña la plataforma completa —el contenedor, el orquestador y todo lo que queda alrededor— construyendo
un sistema de cuatro microservicios en cuatro lenguajes sobre un Kubernetes local que se puede romper sin pagar, y
midiendo lo que cada decisión cuesta. No forma administradores de cluster ni prepara una certificación: forma la
capacidad de mirar un servicio y decir *"esto lo resuelve el contenedor, esto el orquestador, y esto lo tengo que
escribir yo"*, con el laboratorio encima de la mesa para demostrarlo.

> 🧭 **La pregunta que ordena las veintiocho fases: ¿qué te da el contenedor, qué te da el orquestador, y qué te sigue
> tocando escribir a ti?** Las Partes 0 a III son lo que la plataforma sí regala. La Parte IV es lo que no va a dar
> nunca. Y el cierre contesta la pregunta incómoda: ¿de verdad hacía falta un orquestador?

---

## 👤 Para quién es, y para quién no

**Es para ti si** escribes backend en uno o varios lenguajes, montas un endpoint sin pensarlo, has visto un
`docker-compose.yml` y alguna vez hiciste `kubectl apply` de un YAML que te pasó otro equipo, pero nunca tuviste una
plataforma que pudieras romper. Aquí se explica infraestructura, no programación: HTTP, una base relacional o una
transacción se dan por sabidas.

**No es para ti si** buscas administrar un cluster de producción, operar una nube concreta o aprobar una
certificación. Tampoco si esperas que alguien te convenza de usar Kubernetes: el curso mide, y su veredicto final dice
cuándo no hacía falta.

Dos reglas que no se negocian: **ningún "mejor que" entra sin su número**, medido con el mismo arnés y publicado con su
dispersión; y **nada se publica sin haberse ejecutado**. Lo que no se pudo medir se dice.

---

## 🏘️ La empresa: Droguerías La Vecina

Todo lo narrativo del curso sale de [la historia de La Vecina](00-historia-de-la-vecina.md): una cooperativa de
droguistas de Santander con 263 droguerías, un sistema central de 2008 sobre Oracle (*el Siga*), un respaldo que nació
de un apagón en 2016 (*Contingencia*), un portal que hicieron los practicantes y un despacho de motos que vive pegado a
las tablas del central (*la Braqui*). El curso es **el proyecto Paracelso**: sacar del Siga, pieza por
pieza, lo que ya no cabe en él, y responder con números las cuatro preguntas del encargo. Se construye en **La
Rebotica**, un laboratorio en portátiles, con Docker y con Podman, porque compras no aprobó otra suscripción por
puesto.

El préstamo entre droguerías —un paciente que se queda sin su inhalador esa noche si falla— es la transacción
distribuida que la Parte IV convierte en saga.

---

## 🧱 El sistema que construyes

Cuatro servicios y una página, cada uno en su stack, con contratos OpenAPI y una suite de conformidad que decide si
están bien:

| Servicio | Stack | Qué hace |
|---|---|---|
| `pricing` | Go | el precio vigente por producto y droguería; el piloto de cada patrón |
| `inventory` | Spring Boot · Java | la existencia, la venta y el préstamo entre droguerías |
| `catalog` | Laravel · PHP | el catálogo de productos |
| `replenish` | NestJS · Node | las órdenes de reposición |
| `storefront` | React · nginx | la página que lista y vende |

**El código es andamiaje, y se genera.** Cada paso (G0 a G13) tiene su prompt publicado y su suite; el código está bien
cuando la suite pasa, lo haya escrito un asistente o tú ([a03](a03-contratos-y-prompts-de-generacion.md)). Al lado
corre **el patrimonio** de La Vecina —Contingencia en GlassFish, el portal en Laravel y la Braqui en Node—, que el curso
mete al cluster y le va quitando tráfico ([a16](a16-el-patrimonio.md)).

---

## 🪜 El mapa: cinco partes, veintiocho fases

| Parte | Qué hace | Fases |
|---|---|---|
| **0 · Prolegómenos** | el ambiente, el primer contenedor, y el sistema entero en compose | 00 – 02 |
| **I · El modelo y el salto** | qué pasa debajo, cuánto cuesta empaquetar cada runtime, los dos motores, y por qué compose deja de alcanzar | 03 – 06 |
| **II · El despliegue** | lo que la plataforma te da: cluster, red, entrada, configuración, estado, Helm, salud, escalado | 07 – 16 |
| **III · Operarlo** | métricas, logs, TLS, seguridad del pod y de la red, diagnóstico | 17 – 21 |
| **IV · El lab de patrones** | lo que la plataforma no te da: resiliencia, gRPC, sagas, coreografía, idempotencia y outbox | 22 – 26 |
| **Cierre** | el veredicto honesto y el proyecto final | 27 |

El índice completo —cada fase con su peso, sus ejercicios, sus incidentes y su medición— está en
[`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md). Las fases se hacen en orden: cada una deja el laboratorio como la
siguiente lo espera.

---

## 🧰 Lo que necesitas

- **Una máquina con virtualización** y uno de los dos motores, **Docker Desktop o Podman** (con los dos, mejor: la
  [Fase 05](05-los-dos-motores.md) los compara). macOS, Windows 11 con WSL 2 o Linux.
- **Memoria para la máquina virtual del motor**: [a01](a01-el-laboratorio.md) tiene la tabla medida por perfil, y lo
  que no entra en 4 GiB.
- Las herramientas de la [Fase 00](00-el-ambiente.md): kind, `kubectl`, Helm con helm-diff, Task, k9s, Hurl, k6,
  hyperfine, dive y Python. **Ningún runtime de los servicios en tu máquina**: Java, PHP, Node y Go se compilan dentro
  de un contenedor.

**Las versiones viven en un solo sitio**, [a01](a01-el-laboratorio.md), con su digest y su fecha de verificación. El
autor verificó todo en **macOS arm64**; lo de Windows 11 y Linux está escrito desde la documentación oficial y marcado
*"no verificado por el autor"* donde aplica. [a02](a02-problemas-del-ambiente.md) junta los problemas del ambiente que
salieron.

---

## 🔁 Cómo se trabaja

**Dos repositorios.** El tuyo, donde construyes `src/lab/` fase a fase con tus commits y tus tags; y el del curso, que
clonas aparte y no tocas: la referencia contra la que te comparas y de donde salen los incidentes. La
[convención de git y tags](00-convencion-de-git-y-tags.md) lo explica una vez.

**Un Taskfile como punto de entrada.** `task cluster:up`, `task deploy`, `task conformance`, `task measure`… Cada tarea
es corta y [a01](a01-el-laboratorio.md) dice qué corre debajo, para que puedas prescindir de ella. **Tres perfiles**:
`minimo` (un nodo, lo justo), `lab` (tres nodos, lo que la fase encienda) y `medicion` (solo lo que se mide). La
observabilidad y el bus se encienden por pieza.

**Cada fase tiene la misma forma**: la escena de La Vecina, la apuesta escrita antes de ejecutar, los conceptos sobre el
laboratorio, la rotura provocada con su síntoma literal, la autopsia de un error común, el diccionario en las dos
direcciones, y el veredicto de cuándo no usar lo que se acaba de aprender. Entre 12 y 24 ejercicios graduados
🟢🟡🟠🔴, cada uno con su criterio verificable.

---

## 🩺 El cuaderno de incidentes

[Veintisiete fallos](cuaderno-incidentes.md) que vas a ver en un cluster de verdad, provocados a voluntad en uno que no
cuesta nada romper: la imagen que el nodo nunca vio, el `Service` que no selecciona nada, el `OOMKilled` sin log, el
certificado que vence, la `NetworkPolicy` que cierra hasta lo permitido. Cada uno trae el encargo de quien lo sufre, el
síntoma literal, tres pistas y la solución escondida. Se busca por síntoma, se llega desde un tag o con `task
inc:break`, y entrena el reflejo de los primeros treinta segundos.

---

## 📎 Los apéndices

**De laboratorio y de consulta**, los que se usan durante el curso: [a01](a01-el-laboratorio.md) (versiones, Taskfile,
perfiles y memoria), [a02](a02-problemas-del-ambiente.md) (problemas del ambiente),
[a03](a03-contratos-y-prompts-de-generacion.md) (contratos y prompts), [a04](a04-kubectl-y-k9s.md) (`kubectl` y k9s por
pregunta), [a05](a05-diccionarios.md) (compose ⇄ Kubernetes, `Ingress` ⇄ Gateway API, local ⇄ nube) y
[a16](a16-el-patrimonio.md) (el patrimonio).

**🔥 Ampliaciones**, que ninguna fase espera y que se leen cuando hacen falta, cada una ejecutada y con lo que suma de
memoria: multiplataforma ([a06](a06-arquitecturas-y-multiplataforma.md)), imágenes sin Docker
([a07](a07-imagenes-sin-docker.md)), la JVM nativa ([a08](a08-la-jvm-nativa.md)), el frontend con runtime
([a09](a09-frontend-con-runtime.md)), service mesh ([a10](a10-service-mesh.md)), GitOps
([a11](a11-gitops-de-lectura.md)), operators ([a12](a12-operators-de-lectura.md)), respaldo y restauración
([a13](a13-respaldo-y-restauracion.md)), las GUI ([a14](a14-las-gui.md)) y un `StatefulSet` de varios miembros
([a15](a15-statefulset-de-varios-miembros.md)).

---

## 📏 Las mediciones y los instintos

[`BENCHMARKS.md`](BENCHMARKS.md) junta las mediciones del curso (de B-04 a B-23; la memoria de cada perfil, B-00, vive en
[a01](a01-el-laboratorio.md)), cada una con hipótesis, condiciones,
resultado con dispersión, la apuesta ganada o perdida, y el comando para repetirla. [`INSTINTOS.md`](INSTINTOS.md) junta
los reflejos que el curso corrige: lo que tu instinto de compose, o de servidor, dice, y dónde se equivoca.

---

## 🚫 Lo que queda fuera

cgroups y namespaces por dentro · firma de imágenes y cadena de suministro · gestores de secretos externos · alertas y
guardias · event sourcing y CQRS · desplegar en una nube de pago · escribir un operator propio · Kafka · compose como
herramienta de producción · `Ingress`, salvo para leerlo · JVM anteriores a la 25, Jakarta EE y MicroProfile · enseñar
a programar los servicios · y la regulación farmacéutica de la historia.

---

> 📝 **Estado:** las veintiocho fases, los dieciséis apéndices y el cuaderno completo, verificados entre el 03 y el
> 05/10/2026 en macOS arm64. Las URL y los contenidos de terceros cambian; cada documento avisa cuando una referencia
> apunta a otra versión.
