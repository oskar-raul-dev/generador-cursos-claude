# L00 — Introducción a la serie práctica: qué se hace en la nube y qué no

> **Objetivo:** entender qué vas a construir en los labs `L01`–`L08`, por qué el laboratorio
> incluye exactamente esos servicios y no otros, por qué son ocho sesiones y no cuatro, cuánto
> va a costar y cómo se garantiza que no quede nada encendido.
> **Se asume leído:** nada. Este es el primer documento de la serie práctica.
> **Precios de referencia:** `us-central1`, orden de magnitud. Verifica siempre en la
> [calculadora oficial](https://cloud.google.com/products/calculator) antes de encender algo.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Las dos restricciones](#1--las-dos-restricciones-de-partida) ·
[Doctrina de reparto](#2--la-doctrina-de-reparto-qué-se-paga-y-qué-se-practica-en-local) ·
[Por qué no un microservicio en GKE](#3--el-caso-testigo-por-qué-no-montamos-un-microservicio-en-gke) ·
[Qué entra y qué no](#4--el-catálogo-completo-de-exclusiones) ·
[El sistema del lab](#5--el-sistema-que-vas-a-construir) ·
[Presupuesto](#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas) ·
[Cómo recorrer la serie](#7--cómo-recorrer-la-serie) ·
[Emuladores](#8--emuladores-locales-qué-sirve-y-qué-miente) ·
[Ampliaciones](#9--ampliaciones-opcionales) ·
[Preguntas](#-preguntas-rápidas)

Este documento no es material de estudio para la entrevista: es el contrato de la serie
práctica. Define qué entra en el laboratorio de pago, **qué queda fuera y por qué**, el
presupuesto y cómo se conecta con el resto del repositorio. Si solo vas a leer un
documento antes de abrir una cuenta de Google Cloud, que sea este.

---

## 1. 🧭 Las dos restricciones de partida

Todo el diseño de la serie sale de dos hechos. El primero es una buena noticia con letra
pequeña; el segundo no es negociable.

**Hay dos cosas gratis, y no son la misma.** Una cuenta nueva recibe un **crédito de
bienvenida de $300 válido por 90 días**, que se gasta en casi cualquier producto. Aparte,
y sin fecha de caducidad, existe el **Free Tier ("Always Free")**: cuotas mensuales de una
lista de productos que no expiran mientras Google no las cambie. Son mecanismos
independientes: el crédito se agota o vence, el Always Free sigue.

> 📝 **Contexto.** Mucho material de estudio confunde los dos y te dice "GCP es gratis 90
> días". Lo cierto es más útil: **casi toda esta serie cabe dentro del Always Free**, y el
> crédito de $300 es la red de seguridad para los drills opcionales de §9, no el
> presupuesto principal. Diseñar el lab pensando en el crédito es diseñarlo para que
> caduque en tres meses.

Las cuotas que sostienen el laboratorio, tal como las publica Google:

| Producto | Cuota Always Free mensual |
|---|---|
| Cloud Run | 2 millones de requests, 360.000 GiB-s de memoria, 180.000 vCPU-s |
| Pub/Sub | 10 GiB de mensajes |
| Firestore | 1 GiB de almacenamiento; 50.000 lecturas, 20.000 escrituras y 20.000 borrados **por día** |
| Cloud Storage | 5 GiB-mes regional (regiones de EE. UU.), 5.000 operaciones clase A, 50.000 clase B |
| Cloud Logging | primeros 50 GiB de logs por proyecto |
| Cloud Build | 2.500 build-minutes |
| Artifact Registry | 0,5 GB de almacenamiento |
| Secret Manager | 6 versiones activas de secreto, 10.000 accesos |

**El lab acompaña una búsqueda de empleo.** No hay presupuesto de empresa ni tiempo
ilimitado. El laboratorio tiene que poder encenderse en minutos, practicarse en una sesión
y destruirse con certeza. Un lab que tarda tres horas en levantarse se hace una vez y
nunca más, y un lab que no sabes destruir del todo es una suscripción mensual que no
pediste.

De ahí sale la tesis de la serie:

```text
El laboratorio no se mide por lo que despliegas.
Se mide por lo que destruyes y vuelves a levantar sin intervención manual.
```

---

## 2. ⚖ La doctrina de reparto: qué se paga y qué se practica en local

Aquí está la decisión de diseño que explica todo lo demás, y es la regla que más gente
hace al revés cuando monta su primer laboratorio de nube.

> 🧠 **Modelo mental.** En la nube se practica lo que **solo** existe en la nube. Todo lo
> demás se practica en local con contenedores: gratis, con un ciclo de iteración de
> segundos en vez de minutos, y sin miedo a olvidarse algo encendido.

Un tema entra en el laboratorio de pago solo si cumple **al menos una** de estas cuatro
condiciones:

| Criterio | Ejemplos en GCP |
|---|---|
| Lo hace cumplir Google y nadie más | IAM y allow policies, jerarquía Organization → Folder → Project, habilitación de APIs, cuotas |
| El fallo real difiere del fallo emulado | `deletion_protection`, push subscriptions con OIDC, dead-letter, reintentos, drift de Terraform |
| Solo se conoce pagando | Informes de facturación, presupuestos, qué consume de verdad tu cuota Always Free |
| Es la costura entre tu código y GCP | Service accounts, ADC, impersonation, service agents, Workload Identity Federation |

La contrapartida de esa regla es lo que hace útil al laboratorio:

> Regla de arquitectura: los emuladores son andamio de desarrollo, no instrumento de
> enseñanza. Lo que un emulador te quita —IAM que sí deniega, una API que hay que
> habilitar, un push que sí valida el token, una factura— es exactamente lo que GCP enseña.

Y al revés: lo que Google **no** te enseña mejor que un contenedor local no merece que le
pagues. Correr PostgreSQL en Cloud SQL no te enseña PostgreSQL. Correr un contenedor en
Cloud Run no te enseña qué es un contenedor. Desplegar un microservicio en GKE no te
enseña Kubernetes. En los tres casos estás pagando por hora para practicar algo que ya
podías practicar gratis, y encima con un feedback loop diez veces más lento.

---

## 3. ⚖ El caso testigo: por qué no montamos un microservicio en GKE

Es la pregunta que más aparece cuando alguien ve el índice de la serie: *"¿un lab de GCP
sin un microservicio corriendo en Kubernetes?"*. Sí, y vale la pena desarmarla entera,
porque el razonamiento se aplica igual a Compute Engine, a Cloud SQL y a media docena de
productos más.

### 3.1 Primero, hay que ser honestos con el precio

En GCP este argumento **no se gana por el precio del control plane**, y conviene decirlo
antes de que alguien lo verifique y deje de creerle al resto del documento.

GKE cobra una tarifa de administración de **$0.10 por cluster y por hora**, en cualquier
modo de operación. Pero el Free Tier de GKE aporta **$74.40 de crédito mensual por cuenta
de facturación**, aplicado a clusters zonales y Autopilot — que a $0.10/h son unas 744
horas, es decir, un mes entero de un solo cluster. Un cluster zonal encendido todo el mes
tiene, en la práctica, el control plane cubierto.

> 💰 **Costo.** Lo que ese crédito **no** cubre es lo que de verdad se paga: en Autopilot,
> los recursos que piden tus Pods (vCPU, memoria, almacenamiento efímero); en Standard, las
> VMs del node pool, encendidas aunque no haya nada desplegado. Y si expones el servicio
> con un Ingress o con la Gateway API, el controlador crea un load balancer de Google
> Cloud, cuyo **forwarding rule global cuesta del orden de $0.025/h** — unos $18 al mes por
> una regla que nadie recuerda haber creado.

Así que el argumento honesto no es "el control plane es caro". Es este:

### 3.2 Qué esperas aprender y qué aprendes de verdad

Cuando imaginas ese lab, la lista mental de aprendizajes suele ser esta:

```text
Lo que crees que vas a aprender montando un microservicio en GKE
──────────────────────────────────────────────────────────────────
  1. Contenedores y su ciclo de vida         ← ya lo aprendes en local
  2. Deployments, Services, Ingress          ← ya lo aprendes en local (kind)
  3. Rolling updates, readiness, liveness    ← ya lo aprendes en local
  4. ConfigMaps, Secrets, resource limits    ← ya lo aprendes en local
  5. HPA y escalado                          ← ya lo aprendes en local
  6. Workload Identity Federation for GKE    ← esto SÍ es de GCP
  7. GKE Ingress / Gateway → load balancer   ← esto SÍ es de GCP
  8. Clusters VPC-native y agotamiento de IPs ← esto SÍ es de GCP
```

De ocho puntos, cinco los practicas gratis con `kind` o `minikube` en tu portátil, en un
cluster que levanta en cuarenta segundos y que puedes destruir y recrear veinte veces en
una tarde. Tres son específicos de GCP.

### 3.3 El cálculo que decide

Ponlo en la balanza:

- **Aprendizaje específico de GCP por sesión:** tres conceptos (Workload Identity
  Federation, la integración Ingress/Gateway con Cloud Load Balancing, el direccionamiento
  VPC-native con alias IP ranges).
- **Costo de una sesión:** bajo. El control plane lo cubre el crédito, un nodo pequeño son
  centavos por hora y un forwarding rule ~$0.025/h si expones algo. Una tarde entera se queda
  por debajo de $0.20. **El precio no es el argumento**, y conviene no fingir que lo es.
- **Latencia de iteración:** entre 5 y 15 minutos para crear un cluster, y otro tanto para
  borrarlo. En `kind`, cuarenta segundos. Ahí sí hay una diferencia de dos órdenes de magnitud,
  y es la que decide cuántas veces vas a repetir el ejercicio.
- **Riesgo de teardown incompleto:** alto, y **es el argumento de verdad**. Lo que se filtra no
  es lo que el cluster posee —eso se borra— sino dos categorías que Google documenta de forma
  explícita. La primera es lo que el controlador creó **en nombre de un objeto de Kubernetes**:
  *"debes borrar los recursos Ingress y Service antes de borrar los clusters o los recursos de
  balanceo de Compute Engine quedan huérfanos"*. La segunda son los discos: **GKE retiene los
  PersistentVolume al borrar el cluster, tengan la política de recuperación `Delete` o
  `Retain`**. El `Delete` solo borra el disco cuando borras el `PersistentVolumeClaim` con el
  cluster vivo; si borras el cluster directamente, el disco sobrevive igual.

La conclusión no es "GKE no importa", ni tampoco "GKE es caro". Es que **GKE merece un drill
dirigido de una tarde, no ser el escenario donde practicas el resto**. Los tres conceptos
que sí son de GCP caben en una sesión enfocada, con el teardown escrito antes que el
despliegue. Montar el microservicio de negocio encima solo añade costo, tiempo de espera y
superficie de olvido, sin añadir un solo aprendizaje de GCP.

Por eso GKE aparece en §9 como ampliación opcional, con su precio declarado, y no en el
tronco de `L01`–`L08`.

### 3.4 El mismo razonamiento, aplicado en general

La pregunta que decide cualquier caso dudoso es siempre esta:

> Regla de entrevista: *"¿Qué me enseña este producto que no me enseñe el mismo software
> corriendo en un contenedor en mi máquina?"*. Si la respuesta cabe en dos conceptos, es un
> drill de una sesión. Si la respuesta es "nada", es un contenedor local. Si la respuesta es
> "el modelo entero", entonces sí es un lab de nube.

Y es, de paso, una respuesta excelente en una entrevista de arquitectura. Quien puede
justificar por qué **no** llevó algo a un servicio administrado demuestra criterio de
costo; quien lleva todo a Kubernetes porque sí, demuestra lo contrario.

---

## 4. 📋 El catálogo completo de exclusiones

Lo que sí entra al laboratorio de pago, con lo que enseña cada cosa:

| Servicio | Qué enseña que no se aprende en local |
|---|---|
| `gcloud` y proyectos | Habilitación de APIs, configuraciones, ADC, impersonation, cuotas |
| Cloud IAM | Allow policies aditivas, herencia por jerarquía, service agents, `PERMISSION_DENIED` real |
| Terraform sobre GCP | Ciclo de vida real de un state remoto, drift, `deletion_protection`, borrado con dependencias |
| Cloud Run | Contrato de plataforma: `PORT`, concurrencia, escalado a cero, identidad del servicio |
| Firestore | Índices compuestos declarados, escritura transaccional, límites y cuotas reales |
| Pub/Sub + DLQ | Push con token OIDC, políticas de reintento, dead-letter, at-least-once de verdad |
| Eventarc | Triggers, service agents y los permisos que nadie recuerda conceder |
| Cloud Logging y Monitoring | Logs estructurados, log-based metrics, alerting policies, Audit Logs |
| Facturación y Asset Inventory | La factura, los presupuestos y el inventario que demuestra el teardown |

Y lo que queda fuera, cada uno con su razón y su destino. Ninguna exclusión se deja sin
justificar: una exclusión explicada es contenido, una exclusión silenciosa es un hueco del
temario.

**GKE.** Desarrollado en §3. El control plane lo cubre el crédito del Free Tier, pero los
Pods o los nodos facturan por hora y el Ingress crea un forwarding rule; y nada de eso te
enseña Kubernetes. → `kind` en local, más el drill de §9.

**Compute Engine y Managed Instance Groups.** Una `e2-micro` en una región de EE. UU. entra
en el Always Free, así que el problema no es el precio: es que el ciclo de vida de una VM
no enseña nube. Lo que sí es de GCP —plantillas de instancia, autohealing de un MIG, el
metadata server como fuente de credenciales— es un drill de una sesión. → VM o contenedor
local, más el drill de §9.

**Cloud SQL y AlloyDB.** Cloud SQL es PostgreSQL o MySQL con un sobre de gestión encima, y
**no tiene cuota Always Free**: factura por hora de instancia y por almacenamiento, y el
almacenamiento sigue cobrando con la instancia detenida. El motor se aprende mejor en un
contenedor, donde puedes romperlo sin consecuencias; el sobre —alta disponibilidad
regional, read replicas, backups y point-in-time recovery, IP privada con Private Service
Connect— es un drill. → PostgreSQL en contenedor, más el drill de §9.

**Cloud Load Balancing (Application Load Balancer global).** Un forwarding rule global
cuesta del orden de **$0.025/h**, y es completamente evitable: Cloud Run ya publica una URL
HTTPS con certificado administrado sin cobrar por ella. Es la trampa de costo número uno de
los proyectos de práctica, junto con las IP estáticas reservadas. → No se usa en el tronco;
el concepto se explica en [`06`](06-cloud-dns-conectividad.md) y se practica en el drill de §9.

**Cloud NAT.** Cobra por hora de gateway y por GiB procesado, y el laboratorio no lo
necesita: no hay VMs privadas que deban salir a Internet, y para llegar a las APIs de Google
desde una subnet sin IP externa está **Private Google Access**, que no tiene cargo adicional.
→ No se usa; el concepto se explica en [`01`](01-infraestructura-global-y-redes.md) y se
practica, gratis y con Private Google Access en su lugar, en
[`L04`](l04-red-vpc-firewall-y-diagnostico.md).

**Memorystore.** Redis administrado factura por hora y por GiB sin cuota gratuita, para
enseñarte un Redis que ya sabes usar. Lo específico —replicación, failover, la ventana de
mantenimiento— es un drill si algún día lo necesitas. → Redis en contenedor.

**Dataflow y Dataproc.** Facturan por worker y por hora, y lo que enseñan es Apache Beam y
Apache Spark, que corren igual en local. → Beam o Spark en contenedor.

**Apigee.** Su modelo de licenciamiento no se parece en nada al del resto del catálogo y no
hay forma barata de practicarlo. El vocabulario que se pregunta en entrevista —proxies,
políticas, quotas, monetización— se cubre conceptualmente en
[`06`](06-cloud-dns-conectividad.md). → Fuera de alcance del laboratorio.

**BigQuery.** Caso especial, y con final distinto al de los demás: **entra**, pero como
drill opcional de §9 y no en el tronco. La cuota Always Free —1 TiB de consulta y 10 GiB de
almacenamiento al mes— alcanza de sobra para practicar particionado, clustering y lectura de
un plan de consulta sin gastar un centavo. Se queda fuera del tronco porque el sistema del
lab es transaccional y meterle un data warehouse no aportaría nada al flujo; se queda dentro
de §9 porque es gratis y porque [`13`](13-bigquery-analitica.md) lo pide.

**Frontend.** Cero aprendizaje de nube. → Fuera de alcance del repositorio.

**Jenkins, SonarQube, Prometheus, Grafana.** No son productos de Google Cloud. Pagar una VM
para correrlos es pagar por un contenedor con pasos extra. → Contenedores en local.

---

## 5. 🧱 El sistema que vas a construir

Inventario de una cadena de tiendas. Solo backend, íntegramente serverless, sin una sola
línea de frontend y sin un solo recurso que cobre por hora.

```text
  curl  (con identity token)
    │
    ▼
  inv-api (Cloud Run, sin acceso anónimo)
    │
    ├──►  Firestore  ── colección events   (escritura idempotente)
    │
    └──►  Pub/Sub topic  inv-events
                 │   push subscription con token OIDC
                 ▼
           inv-projector (Cloud Run)  ──►  Firestore ── colección stock
                 │   tras N intentos fallidos
                 ▼
           dead-letter topic  inv-events-dlq
                 │
                 ▼
           log-based metric  ──►  alerting policy  ──►  correo
```

Es deliberadamente pequeño, y cada pieza está ahí por un motivo concreto:

- **Cloud Run con `--no-allow-unauthenticated`** es la costura entre tu código y GCP: quién
  invoca a quién, con qué identidad y con qué token. Es también donde se ve por qué una
  service account por servicio no es purismo, sino la diferencia entre un lab que enseña
  privilegio mínimo y uno que corre entero como `roles/editor`.
- **La escritura en Firestore** es donde practicas la escritura transaccional y la
  idempotencia, que es la respuesta a la pregunta de entrevista más frecuente sobre
  procesamiento asíncrono.
- **La push subscription con OIDC** es puro GCP: Pub/Sub firma un token con la identidad que
  le indicaste, Cloud Run lo valida y la entrega falla con `403` si el binding de
  `roles/run.invoker` no está exactamente donde tiene que estar. Ningún emulador reproduce
  eso.
- **El dead-letter topic** te deja provocar un mensaje envenenado a propósito y ver a dónde
  va, además de tropezar con el permiso que todo el mundo olvida: el service agent de Pub/Sub
  necesita poder publicar en el DLQ y consumir de la subscription.
- **Un trigger de Eventarc** sobre un bucket de Cloud Storage cierra el cuadro de integración
  sin añadir infraestructura que cobre, y trae su propia lección sobre service agents.
- **La vigilancia del dead-letter no es un tercer servicio.** Una versión anterior de este diseño
  ponía un `inv-alert` en Cloud Run detrás del DLQ; se descartó al escribir
  [`L07`](l07-observabilidad-logs-metricas-y-auditoria.md), porque una **log-based metric** más una
  **alerting policy** hacen exactamente lo mismo, sin desplegar nada, sin una imagen más en
  Artifact Registry —la única cuota que el tronco consume de verdad— y enseñando por el camino que
  no se puede alertar directamente sobre un log. Es la doctrina de reparto aplicada a nuestro
  propio diagrama: si el servicio administrado ya lo hace, no escribas un servicio.

El sistema no se levanta de una sentada: [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) despliega `inv-api` y se queda ahí, y [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md)
añade Firestore, el topic, la push subscription, el dead-letter y el trigger. Esa frontera es
deliberada y está explicada en §7.1.

El flujo cubre así casi todo el vocabulario de mensajería, eventos y NoSQL de
[`04`](04-firestore-bigtable-nosql.md) y [`07`](07-pubsub-eventarc-integracion.md), que es
justamente lo que se pregunta en una entrevista de arquitectura backend.

---

## 6. 💰 Presupuesto, y de dónde sale el gasto que no esperabas

| Bloque | Costo |
|---|---|
| `L01`–`L04` — proyecto, IAM, Terraform y red | $0.00; todo lo que se crea entra en el Always Free o no cobra |
| `L05`–`L06` — Cloud Run, Firestore, Pub/Sub y Eventarc | centavos; el tráfico del lab cabe en las cuotas gratuitas |
| `L07`–`L08` — observabilidad, costos y teardown | $0.00; muy por debajo de los 50 GiB de logs |
| **Serie completa, repetida varias veces** | **menos de $1** |

El único cargo que aparece de verdad en el tronco es **Artifact Registry**: la cuota gratuita
es de 0,5 GB, y cada despliegue de Cloud Run deja una imagen nueva. Cinco despliegues de una
imagen de 200 MB ya se pasan. Se cubre —y se limpia— en [`L08`](l08-costos-y-destruccion-verificada.md).

Ahora la parte importante, porque el gasto real de un proyecto de práctica **casi nunca viene
del lab en sí**. Viene de cuatro sitios:

1. **Forwarding rules e IP estáticas olvidadas.** Un load balancer que probaste una tarde deja
   su forwarding rule facturando por hora, y una IP externa reservada que no está adjunta a
   nada **se cobra a una tarifa mayor** que una en uso. Las dos sobreviven a casi cualquier
   limpieza a mano.
2. **Discos persistentes y snapshots huérfanos.** Borrar una VM no borra necesariamente su
   disco, y un snapshot no lo borra nadie nunca. El catálogo completo va en
   [`A02`](a02-costos-trampas-y-recursos-huerfanos.md).
3. **Instancias que facturan detenidas.** Una instancia de Cloud SQL parada sigue cobrando
   almacenamiento; un cluster de GKE vacío sigue consumiendo su crédito.
4. **Drills opcionales que se quedan encendidos.** Los de §9. Son los únicos elementos de la
   serie con recursos que cobran por hora de forma continua.

Los cuatro tienen su barrido verificado en
[`L08`](l08-costos-y-destruccion-verificada.md) y su catálogo de referencia en
[`A02`](a02-costos-trampas-y-recursos-huerfanos.md), y el blindaje preventivo —presupuesto,
alertas, notificación programática, labels— se monta en
[`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) antes de crear el primer
recurso.

> ⚠️ **Un presupuesto de Cloud Billing no es un tope de gasto.** Un budget con alertas te
> avisa; no detiene nada ni impide que se sigan facturando servicios. Si quieres que algo pase
> automáticamente, hay que conectarlo a un topic de Pub/Sub y actuar sobre esa notificación
> —el patrón documentado por Google llega hasta deshabilitar la facturación del proyecto—, o
> usar un spend cap budget donde esté disponible. [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) monta la alerta y explica exactamente
> hasta dónde llega.

---

## 7. 🧭 Cómo recorrer la serie

### 7.1 Por qué ocho labs y no cuatro

Antes del índice conviene justificar su tamaño, porque el número de labs no se hereda de
ningún otro curso: **lo decide la nube que se está practicando**, y hay tres hechos de GCP que
empujan la serie hacia arriba.

**Lo barato se practica, no se cuenta.** El Always Free y la ausencia de un equivalente al
NAT Gateway de pago obligatorio hacen que temas que en otras nubes serían un drill caro aquí
sean un lab de $0.00. La red es el caso claro: una VPC, sus subnets, sus firewall rules,
Private Google Access y los Connectivity Tests no cuestan nada mientras no levantes una VM que
no entre en la cuota gratuita. Un tema que se pregunta en toda entrevista de arquitectura y
que además es gratis practicar no tiene por qué quedarse en el capítulo teórico.

**El modelo de identidad de GCP es más grande de lo que cabe en media sesión.** Allow policies
aditivas, herencia a lo largo de Organization → Folder → Project, roles predefinidos frente a
personalizados, service accounts frente a principals humanos, impersonation frente a keys
descargadas, service agents que aparecen solos, IAM Deny policies y las herramientas de
diagnóstico —Policy Troubleshooter, Policy Analyzer— son, juntos, la mitad de las preguntas
difíciles de una entrevista de GCP. Meter todo eso como preámbulo de otro lab lo convierte en
un trámite. Va aparte.

**Cloud Run y el flujo de eventos son dos aprendizajes distintos.** El contrato de la
plataforma —`PORT`, concurrencia, escalado a cero, revisiones, reparto de tráfico, timeouts,
identidad del servicio— se entiende con un solo servicio y ningún mensaje de por medio.
Encadenarlo con Pub/Sub, OIDC, reintentos y dead-letter en la misma sesión mezcla dos
diagnósticos que conviene aprender por separado: cuando algo falle, el lector tiene que poder
decir si el problema es del contenedor o de la entrega.

La contrapartida es que **las sesiones son más cortas y más fáciles de retomar**. Ocho labs de
dos o tres horas se hacen en ocho tardes; cuatro labs de cinco horas no se hacen nunca. Y cada
uno cierra con su propio teardown, así que abandonar la serie a mitad no deja nada encendido.

### 7.2 El índice

Los labs son **acumulativos y en orden**. Cada uno asume el estado que dejó el anterior:

```text
L01  proyecto, jerarquía, gcloud, APIs, presupuesto     $0.00      60–90 min
  │  deja: el proyecto blindado, nada desplegado
  ▼
L02  IAM: allow policies, service accounts, diagnóstico $0.00      2–3 h
  │  deja: las service accounts del lab, sin recursos
  ▼
L03  Terraform desde la CLI                             $0.00      2–3 h
  │  deja: bucket de state + bucket de datos + Firestore vacío
  ▼
L04  red: VPC, firewall, Private Google Access          $0.00      2–3 h
  │  deja: la VPC del lab, sin cargas de trabajo
  ▼
L05  Cloud Run: contrato, revisiones y tráfico          centavos   3 h
  │  deja: inv-api corriendo, cerrado a invocación anónima
  ▼
L06  datos y eventos: Firestore, Pub/Sub, Eventarc      centavos   3–4 h
  │  deja: el sistema de §5 completo
  ▼
L07  observabilidad: logs, métricas, alertas, auditoría $0.00      2–3 h
  │  deja: lo mismo, ahora observable
  ▼
L08  costos y destrucción verificada                    $0.00      2 h
     deja: el proyecto vacío, verificado y (opcionalmente) borrado
```

Lo que cada uno practica, en una línea:

- **[`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md)** — configuraciones de
  `gcloud`, la diferencia entre `gcloud auth login` y `gcloud auth application-default login`,
  un proyecto dedicado con su cuenta de facturación, la habilitación explícita de APIs (y el
  `SERVICE_DISABLED` que sale cuando te olvidas), cuotas, labels de rastreo y presupuesto con
  alertas y notificación a Pub/Sub.
- **[`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md)** — bindings en el
  recurso correcto y en el equivocado, herencia por jerarquía, roles predefinidos frente a
  personalizados, una service account por carga de trabajo, impersonation en vez de keys
  descargadas, y un `PERMISSION_DENIED` provocado a propósito y resuelto con Policy
  Troubleshooter en vez de a fuerza de `roles/owner`.
- **[`L03`](l03-terraform-desde-la-cli.md)** — provider pinneado, backend de state en Cloud
  Storage, `plan` frente a `apply`, lectura de un plan que marca un recurso como
  `must be replaced`, drift provocado a mano desde `gcloud`, y dos borrados que fallan a
  propósito: un bucket no vacío sin `force_destroy` y una base de Firestore con
  `deletion_protection`.
- **[`L04`](l04-red-vpc-firewall-y-diagnostico.md)** — una VPC con subnets propias, firewall
  rules por target tags y su orden de evaluación, Private Google Access para salir a las APIs
  de Google sin IP externa ni Cloud NAT, Flow Logs, y el diagnóstico con Connectivity Tests de
  una conexión que no funciona.
- **[`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md)** — el contrato de la plataforma
  (`PORT`, concurrencia, escalado a cero, timeouts, `min-instances` y lo que cuesta), una
  service account por servicio en vez de la de Compute Engine con `roles/editor`, invocación
  autenticada con identity token, revisiones y reparto de tráfico para un canary, y un secreto
  montado desde Secret Manager.
- **[`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md)** — escritura idempotente y
  transaccional en Firestore, el índice compuesto que el emulador no te exige y el servicio sí,
  push subscription con token OIDC, política de reintentos, un mensaje envenenado que acaba en
  el dead-letter topic, y un trigger de Eventarc con sus permisos de service agent.
- **[`L07`](l07-observabilidad-logs-metricas-y-auditoria.md)** — logs estructurados en JSON
  que Cloud Logging sepa parsear, log-based metrics, una alerting policy que se dispare de
  verdad, Error Reporting, Cloud Trace, y qué registran —y qué no— los Cloud Audit Logs sin
  habilitar los Data Access logs.
- **[`L08`](l08-costos-y-destruccion-verificada.md)** — leer el informe de facturación y
  atribuir el gasto por label, limpiar Artifact Registry, y el teardown en tres capas:
  `terraform destroy`, barrido de verificación con Cloud Asset Inventory y el proyecto entero
  como unidad de borrado.

Los cuatro apéndices se consultan en cualquier momento y no tienen prerrequisitos:
[`A01`](a01-gcloud-de-supervivencia.md) para la mecánica de la CLI —configuraciones,
`--format`, `--filter`, `--flatten`, impersonation, ADC—,
[`A02`](a02-costos-trampas-y-recursos-huerfanos.md) para el catálogo de qué cobra y qué
sobrevive a un borrado, [`A03`](a03-catalogo-de-errores-y-diagnostico.md) para el catálogo de
errores de GCP —`SERVICE_DISABLED`, `PERMISSION_DENIED`, `403` en una entrega push, cuota
agotada, `deletion_protection`— con el comando que confirma cada causa, y
[`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) para la rutina de §7.4, que es la única
pieza del curso que se *hace* en vez de leerse.

> 💡 **Truco.** Si vienes con poco tiempo, el recorrido mínimo que sigue enseñando algo es
> [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) → [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) → [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) → [`L08`](l08-costos-y-destruccion-verificada.md): blindas la cuenta, entiendes IAM, despliegas algo con
> identidad propia y lo destruyes verificando. Los demás labs se pueden intercalar después sin
> rehacer nada, salvo [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md), que necesita [`L03`](l03-terraform-desde-la-cli.md) porque su infraestructura se crea con Terraform.

### 7.3 El proyecto es la unidad de destrucción, con letra pequeña

Es la mejor herramienta de teardown que ofrece GCP y conviene entenderla bien desde el primer
día, porque cambia cómo se diseña todo el laboratorio: **todo lo que crees vive dentro de un
proyecto, y borrar el proyecto se lleva el contenido entero**. Por eso la serie crea un
proyecto dedicado en [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) en vez de reutilizar uno existente.

La letra pequeña, que [`L08`](l08-costos-y-destruccion-verificada.md) desarrolla:

- El borrado no es inmediato: el proyecto queda **30 días** en estado de recuperación antes de
  desaparecer, y durante ese tiempo sigue contando para tu cuota de proyectos.
- **Borrar el proyecto no corta la facturación al instante.** Puede seguir acumulando cargos
  hasta el cierre del ciclo, así que lo correcto es deshabilitar la facturación **antes** de
  iniciar el borrado.
- Un **lien** sobre el proyecto bloquea el borrado hasta que lo quites.
- Y no todo vive dentro del proyecto: el presupuesto y las alertas cuelgan de la cuenta de
  facturación, y las organization policies de la jerarquía. Eso sobrevive y hay que limpiarlo
  aparte.

> ⚠️ **El barrido por labels no sirve para demostrar un teardown en GCP.** Es la diferencia más
> importante frente a un laboratorio equivalente en otra nube, y conviene tenerla clara antes de
> [`L08`](l08-costos-y-destruccion-verificada.md): los recursos que crea un controlador en tu nombre —las forwarding rules de un `Ingress`
> de GKE, las reglas de firewall de un balanceador— **no llevan tus labels**, así que un barrido
> por `project=inv_lab` pasa justo por encima de los huérfanos que buscas. Los labels sirven para
> **atribuir gasto**; para **demostrar que no quedó nada** hace falta Cloud Asset Inventory más un
> barrido dirigido a los sospechosos (forwarding rules, addresses, disks, firewall rules), y los
> recommenders de recursos ociosos como red final.

> 🧠 **Modelo mental.** `terraform destroy` es el ejercicio; el borrado del proyecto es la red
> de seguridad. Usar solo la red de seguridad te ahorra dinero pero no te enseña nada: el
> objetivo de [`L08`](l08-costos-y-destruccion-verificada.md) es que el `destroy` deje el inventario vacío **antes** de que borres el
> proyecto.

**Lo que necesitas antes de empezar [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md):** una cuenta de Google con acceso a una cuenta de
facturación, el SDK de Google Cloud (`gcloud`) instalado, un método de pago válido y —esto no es
negociable— la disposición a hacer el teardown al final de cada sesión aunque sean las once de la
noche. Dos herramientas más entran en escena a mitad de camino y conviene tenerlas listas antes:
**Terraform**, desde [`L03`](l03-terraform-desde-la-cli.md), y **Docker**, desde
[`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md), donde las imágenes se construyen en local
antes de subirlas a Artifact Registry.

**Cuánto teórico conviene llevar leído.** Los labs se pueden hacer sin haber leído los
documentos teóricos, pero rinden mucho más con el documento que sostiene cada uno:
[`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) con [`05`](05-seguridad-iam-jerarquia-kms-secretos.md),
[`L03`](l03-terraform-desde-la-cli.md) con [`09`](09-terraform-iac.md),
[`L04`](l04-red-vpc-firewall-y-diagnostico.md) con [`01`](01-infraestructura-global-y-redes.md),
[`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) con [`02`](02-computo-contenedores-y-balanceo.md),
[`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) con [`04`](04-firestore-bigtable-nosql.md) y [`07`](07-pubsub-eventarc-integracion.md), y
[`L07`](l07-observabilidad-logs-metricas-y-auditoria.md) con [`08`](08-observabilidad-auditoria-gobierno.md).

---

### 7.4 La rutina de recurso: CLI, API y destrucción

Los labs recorren un sistema completo, pero hay un aprendizaje que no se consigue recorriendo
nada: **saber crear, inspeccionar, modificar y destruir un recurso cualquiera desde cero**. Es
lo que se pregunta en una entrevista con la forma *"¿cómo harías X en GCP?"*, y es lo que no
sabes hacer cuando llevas dos años tocando solo la consola web.

Para eso el curso define **una rutina fija, la misma para todos los servicios**, desarrollada
en [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) y aplicable a cualquier recurso que
te interese:

```text
1. Crear        gcloud ... create
2. Inspeccionar gcloud ... describe --format=json     ¿qué atributos tiene de verdad?
3. Modificar    gcloud ... update                     ¿qué campo es mutable y cuál obliga a recrear?
4. Destruir     gcloud ... delete
5. Verificar    gcloud ... list                       ¿qué quedó vivo que no esperabas?
6. Repetir todo lo anterior desde un SDK
```

Los pasos 1 a 5 son media hora. **El paso 6 es donde está el aprendizaje**, y GCP tiene un
puente para llegar hasta él que conviene no perderse:

```bash
gcloud pubsub topics create inv-events --log-http
```

`--log-http` es un flag global de `gcloud` que imprime la petición y la respuesta HTTP
completas. Es decir: te enseña **exactamente qué llamada REST hace el comando que acabas de
escribir**, con su URL, su método, su cuerpo y su respuesta. A partir de ahí, escribir esa misma
llamada con una librería cliente deja de ser un ejercicio de documentación y pasa a ser una
traducción. Es, con diferencia, la forma más rápida de entender que la CLI no es "otra cosa"
distinta de la API: es un cliente de la API.

Tres cosas que la rutina enseña y que ningún documento teórico transmite igual de bien:

- **Las operaciones de larga duración.** Casi todo `create` y `delete` en GCP devuelve una
  `Operation`, no el recurso. `gcloud` espera a que termine por ti —salvo que le pases
  `--async`— y por eso parece síncrono; desde un SDK tienes que esperarla tú, explícitamente.
  Ese es el primer sitio donde se rompe el código de quien pasó de la CLI a la librería.
- **De dónde saca credenciales tu código.** El script falla hasta que las Application Default
  Credentials están bien puestas, y ahí la diferencia entre `gcloud auth login` y
  `gcloud auth application-default login` que [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) explica en prosa se vuelve una excepción en
  tu terminal. Es la mejor forma de que no se olvide.
- **Qué campo es mutable.** Intentar cambiar un atributo inmutable devuelve un error concreto, y
  es la misma frontera que Terraform marca como `must be replaced` en [`L03`](l03-terraform-desde-la-cli.md). Verlo desde los dos
  lados fija el concepto.

El costo de la rutina es deliberadamente ridículo —un topic, un bucket, una service account o
una firewall rule no cobran nada por existir— y cada vuelta cabe en una tarde. Lo que queda
después no es el recurso: es **el script y el fragmento de código anotados**, que valen como
material de repaso y como portafolio.

> 💡 **Truco.** Aplica la rutina al servicio que más te intimide antes de una entrevista. La
> diferencia entre "sé lo que es un Managed Instance Group" y "lo he creado, roto y borrado
> desde la CLI y desde código" se nota en la primera repregunta.

---

## 8. 🧪 Emuladores locales: qué sirve y qué miente

Para correr el sistema en local sin gastar cuota. GCP tiene una ventaja aquí: varios de los
emuladores son oficiales y vienen en el propio SDK (`gcloud emulators`). La columna que
importa es la de fidelidad: usar un emulador creyendo que se comporta igual que el servicio
real es la forma más común de aprender algo falso.

| Servicio GCP | Sustituto local | Fidelidad |
|---|---|---|
| Firestore | `gcloud emulators firestore` (oficial) | Alta para la API. No exige índices compuestos como el servicio real ni aplica security rules igual. |
| Pub/Sub | `gcloud emulators pubsub` (oficial) | Media. La API sí; la autenticación OIDC del push, el IAM y varias políticas de entrega, no. |
| Bigtable | `gcloud emulators bigtable` (oficial) | Alta para la API; sin el comportamiento real de particiones ni hot spots. |
| Spanner | Spanner emulator (oficial) | Alta para la API; sin el comportamiento de replicación ni las cuotas. |
| Cloud Run | `docker run` de la misma imagen | Media. La imagen es idéntica; el contrato de plataforma —`PORT`, concurrencia, escalado a cero, identidad del servicio— no se emula. |
| Cloud Storage | `fake-gcs-server` (terceros) | Media. Cubre la API básica; no el IAM, ni las clases de almacenamiento, ni las políticas de retención. |
| Cloud SQL | PostgreSQL o MySQL en contenedor | No aplica: el motor es el mismo; lo administrado no se emula. |
| Identity Platform | Keycloak (terceros) | Sirve para OIDC y JWT como concepto, no como producto. |
| IAM, VPC, facturación, Terraform contra GCP | Ninguno | No se emulan de forma útil. |

> 💡 **Truco.** Corre la misma suite de pruebas contra el emulador y contra GCP real, y anota
> cada diferencia que encuentres. Esa lista —"qué me mintió el emulador"— es material de
> entrevista de primera calidad, porque demuestra que entiendes el servicio y no solo su API.

---

## 9. 🧪 Ampliaciones opcionales

Drills sueltos, **no acumulativos**, que se encienden y se destruyen en la misma sesión. Cada
uno cubre exactamente los conceptos que §3 y §4 identificaron como "específicos de GCP" en un
producto excluido del tronco. La red no aparece aquí porque en GCP sale gratis y por eso
subió al tronco como [`L04`](l04-red-vpc-firewall-y-diagnostico.md); es el ejemplo más claro de
que el reparto entre lab y drill lo decide la nube y no la costumbre.

| Drill | Qué añade que no aprendes en local | Costo aproximado por sesión de 3 h |
|---|---|---|
| GKE Autopilot, solo la costura | Workload Identity Federation, Ingress/Gateway → Cloud Load Balancing, clusters VPC-native y agotamiento de IPs | Control plane cubierto por el crédito del Free Tier; se paga lo que piden los Pods y el forwarding rule si expones algo |
| Application Load Balancer global + Cloud Armor | Forwarding rules, backend services, health checks, certificados administrados, reglas WAF | ~$0.08 solo en forwarding rule, más lo de Cloud Armor |
| Cloud SQL con IP privada | Alta disponibilidad regional, read replicas, PITR, Private Service Connect | Factura por hora de instancia y por almacenamiento; verifica en la calculadora |
| Compute Engine y MIG sobre la VPC de [`L04`](l04-red-vpc-firewall-y-diagnostico.md) | Plantillas de instancia, autohealing, metadata server como fuente de credenciales | ~$0.00 con una `e2-micro` dentro del Always Free |
| BigQuery | Particionado, clustering, lectura del plan de consulta, streaming | ~$0.00 dentro de 1 TiB de consulta al mes |
| Cloud Build y Cloud Deploy | Pipeline real, service account del build, despliegue progresivo | ~$0.00 dentro de 2.500 build-minutes al mes |

Cada drill se recorre con la rutina de §7.4: crear, inspeccionar, modificar, destruir y
verificar, primero desde `gcloud` y después desde el SDK. Eso es lo que convierte un drill en
aprendizaje en vez de en una visita guiada.

> ⚠️ Los dos primeros drills son los únicos con recursos que cobran por hora de forma continua,
> y los únicos cuyo teardown deja residuos si lo haces mal. En el de GKE el orden importa y no es
> negociable: **primero `kubectl delete` de los `Ingress`, los `Service` de tipo `LoadBalancer` y
> los `PersistentVolumeClaim`; se espera a que el controlador termine de verdad; y solo entonces
> se borra el cluster.** Borrar el `Ingress` es lo que se lleva las forwarding rules, los backend
> services y los URL maps; borrar el `Service`, lo que se lleva el NEG. Y ojo con la prisa: la
> propia documentación advierte que si borras un namespace y acto seguido el cluster, los
> volúmenes pueden no llegar a borrarse, porque GKE no espera a que terminen esas operaciones.
> Después se verifica con el barrido de [`L08`](l08-costos-y-destruccion-verificada.md) antes de
> cerrar la sesión.

---

## 10. 🧭 Relación con el resto del repositorio

```text
docker-container-legacy    → cómo funciona un contenedor por dentro
                             namespaces, cgroups, overlayfs, capas, PID 1

laboratorio local          → cómo funcionan muchos contenedores juntos
(en preparación)             Kubernetes, mensajería, observabilidad, pipelines

repaso-gcp-entrevistas     → qué cambia cuando el dueño de la infraestructura
+ serie práctica L01-L08     es otro: identidad, jerarquía, red, IaC, servicios
                             administrados y costo
```

Cada nivel explica los fallos del siguiente, y por eso el reparto de §2 funciona. Quien
entendió cgroups reconoce un `OOMKilled` sin buscarlo. Quien operó Kubernetes en local solo
tiene que aprender la parte específica de GCP cuando llega a GKE —que son, exactamente, los
tres conceptos del drill.

---

## 11. 📝 Decisiones: las cerradas y las que siguen abiertas

Las cuatro que bloqueaban la escritura de los labs ya están decididas, y los documentos escritos
las sostienen. Se dejan anotadas con su porqué, porque el criterio vale más que la elección:

| Decisión | Elegida | Por qué |
|---|---|---|
| Lenguaje de los servicios de Cloud Run y del SDK de [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) | **Python** | Las librerías `google-cloud-*` son las más completas y las que menos ceremonia piden para un fragmento de veinte líneas; la imagen es pequeña, que es justo lo que protege la única cuota que el tronco consume de verdad (Artifact Registry) |
| Despliegue de Cloud Run en [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) | **Imagen preconstruida** (`docker build` → Artifact Registry → `gcloud run deploy --image`) | Enseña de dónde sale el único cargo real del tronco y respeta la regla de "primero el mecanismo, después la comodidad". `--source` se menciona como atajo, diciendo qué esconde |
| Reparto Terraform / `gcloud` | **Terraform la infraestructura, `gcloud` el despliegue** | Terraform administra buckets, Firestore, topic, subscriptions, service accounts y bindings —lo que [`L08`](l08-costos-y-destruccion-verificada.md) tiene que poder destruir y verificar—; los despliegues de Cloud Run van con `gcloud`, para no meter un `plan`/`apply` en cada iteración de una revisión |
| Lenguaje del SDK para la rutina de §7.4 | **Python**, con el lector libre de usar otro | Un solo lenguaje escrito; no se escriben cuatro versiones del mismo fragmento |

Y las que siguen abiertas, sin bloquear nada:

1. **Región.** La serie asume `us-central1`, que es donde vive buena parte del Always Free.
   Repetir [`L03`](l03-terraform-desde-la-cli.md) en `southamerica-east1` y comparar el informe de facturación sería un
   ejercicio de FinOps de media hora.
2. **Terraform frente a Infrastructure Manager.** El tronco usa Terraform local con state en
   Cloud Storage. Infrastructure Manager —el servicio administrado que ejecuta Terraform— es la
   ampliación natural, y desde el fin de soporte de Deployment Manager es la única opción
   nativa. Queda por decidir si entra como sección de [`L03`](l03-terraform-desde-la-cli.md) o como drill de §9.
3. **Si [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) merece dividirse.** IAM da para dos sesiones si se entra en IAM Deny policies,
   condiciones y Workload Identity Federation. La propuesta actual lo deja en una y manda
   Workload Identity Federation al drill de GKE, pero es la frontera menos firme de la serie.
4. **Dónde vive la rutina.** [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) la define una vez y cada lab la aplica a su servicio, que es
   lo propuesto. La alternativa es no tener [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) y repetir el ciclo dentro de cada lab, más
   redundante pero más autosuficiente por documento.
5. **Repositorio de código.** Si el HCL, los scripts y los fragmentos de SDK van a vivir en un
   repo público como portafolio, conviene decidirlo antes de escribirlos. La rutina de §7.4 lo
   hace más atractivo: lo que produce es exactamente material presentable.
6. **Nombres de archivo de los labs.** ✅ Cerrada: los doce documentos existen ya con estos
   nombres, así que dejan de ser una suposición y pasan a ser un contrato. Si alguno cambia, hay
   que revisar los enlaces entrantes en la misma edición.

---

## 🧠 Preguntas rápidas

1. ¿Qué condición tiene que cumplir un tema para entrar al laboratorio de pago?
2. ¿En qué se diferencian el crédito de bienvenida y el Free Tier, y por qué el laboratorio se diseña contra el segundo?
3. ¿Por qué el argumento "el control plane de Kubernetes es caro" no sirve en GCP, y cuál es el argumento correcto para no montar el microservicio en GKE?
4. De los ocho aprendizajes que se esperan de "un microservicio en GKE", ¿cuáles son realmente específicos de GCP?
5. ¿Qué pregunta decide si un producto dudoso merece un lab de nube, un drill o un contenedor local?
6. ¿Por qué el laboratorio no pone un Application Load Balancer global delante de Cloud Run?
7. ¿Por qué el lab evita Cloud NAT y qué usa en su lugar cuando algo tiene que hablar con las APIs de Google desde una subnet privada?
8. ¿Cuál es el único cargo real que genera el tronco de la serie, y por qué aparece?
9. ¿Un presupuesto de Cloud Billing detiene el gasto? Si no, ¿qué hay que montar para que algo ocurra automáticamente?
10. ¿Qué le falta al emulador de Pub/Sub respecto del servicio real, y por qué importa para [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md)?
11. ¿Qué tres cosas hay que saber antes de usar `gcloud projects delete` como mecanismo de teardown?
12. ¿Qué queda fuera del proyecto y por lo tanto sobrevive a su borrado?
13. ¿Qué estado deja [`L03`](l03-terraform-desde-la-cli.md) y qué asume [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) sobre él?
14. ¿Por qué BigQuery entra como drill opcional y no como exclusión, a diferencia de Cloud SQL?
15. ¿Qué tres características de GCP hacen que la serie tenga ocho labs y no cuatro?
16. ¿Por qué la red es un lab del tronco en GCP y no un drill opcional?
17. ¿Por qué el contrato de Cloud Run y el flujo de eventos se practican en labs separados?
18. ¿Qué hace `--log-http` y por qué es el puente entre la CLI y el SDK?
19. ¿Por qué un `create` desde un SDK necesita código que desde `gcloud` no hiciste falta escribir?
20. ¿Por qué un barrido por labels no demuestra que un proyecto quedó limpio?
21. ¿En qué orden hay que borrar los objetos de Kubernetes y el cluster, y qué pasa si lo haces al revés?

---

## 📚 Referencias oficiales

- Programa gratuito de Google Cloud (crédito y Free Tier): https://cloud.google.com/free
- Cuotas del Free Tier por producto: https://cloud.google.com/free/docs/free-cloud-features
- Preguntas frecuentes de la prueba gratuita: https://cloud.google.com/signup-faqs
- Calculadora de precios: https://cloud.google.com/products/calculator
- Precios de Google Kubernetes Engine: https://cloud.google.com/kubernetes-engine/pricing
- Precios de Cloud Load Balancing: https://cloud.google.com/load-balancing/pricing
- Precios de red de VPC (IP externas, Flow Logs): https://cloud.google.com/vpc/network-pricing
- Precios de Cloud NAT: https://cloud.google.com/nat/pricing
- Precios de Cloud SQL: https://cloud.google.com/sql/pricing
- Precios de Cloud Run: https://cloud.google.com/run/pricing
- Precios de Pub/Sub: https://cloud.google.com/pubsub/pricing
- Precios de Firestore: https://cloud.google.com/firestore/pricing
- Precios de Artifact Registry: https://cloud.google.com/artifact-registry/pricing
- Precios de BigQuery: https://cloud.google.com/bigquery/pricing
- Crear, editar o eliminar presupuestos y alertas: https://cloud.google.com/billing/docs/how-to/budgets
- Notificaciones programáticas de presupuesto: https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications
- Deshabilitar la facturación con notificaciones: https://cloud.google.com/billing/docs/how-to/disable-billing-with-notifications
- Eliminar y restaurar proyectos: https://cloud.google.com/resource-manager/docs/delete-restore-projects
- Proteger proyectos con liens: https://cloud.google.com/resource-manager/docs/project-liens
- Solución de problemas al eliminar un proyecto: https://cloud.google.com/resource-manager/docs/troubleshooting-project-deletion
- Cloud Asset Inventory: https://cloud.google.com/asset-inventory/docs
- Private Google Access: https://cloud.google.com/vpc/docs/private-google-access
- Emuladores del SDK de Google Cloud: https://cloud.google.com/sdk/gcloud/reference/emulators
- Flags globales de `gcloud` (incluido `--log-http`): https://cloud.google.com/sdk/gcloud/reference
- Librerías cliente de Google Cloud: https://cloud.google.com/apis/docs/cloud-client-libraries
- Credenciales predeterminadas de la aplicación (ADC): https://cloud.google.com/docs/authentication/application-default-credentials
- Operaciones de larga duración en las APIs de Google Cloud: https://google.aip.dev/151
- Borrar un cluster de GKE (qué retiene GKE al borrarlo): https://cloud.google.com/kubernetes-engine/docs/how-to/deleting-a-cluster
- Por qué se borran Ingress y Service antes que el cluster: https://cloud.google.com/kubernetes-engine/docs/how-to/internal-load-balance-ingress
- PersistentVolume en GKE y políticas de recuperación: https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes
- Diagnóstico de balanceo de carga en GKE: https://cloud.google.com/kubernetes-engine/docs/troubleshooting/load-balancing
- Buscar recursos con Cloud Asset Inventory: https://cloud.google.com/asset-inventory/docs/searching-resources
- `gcloud asset search-all-resources`: https://cloud.google.com/sdk/gcloud/reference/asset/search-all-resources
- Catálogo de recommenders de Active Assist: https://cloud.google.com/recommender/docs/recommenders
- Insights de direcciones IP sin usar (Network Analyzer): https://cloud.google.com/network-intelligence-center/docs/network-analyzer/insights/vpc-network/unused-ip-address
- Reservar una IP externa estática (y qué pasa si no se adjunta): https://cloud.google.com/vpc/docs/reserve-static-external-ip-address
- Recomendaciones de recursos ociosos (discos e IP): https://cloud.google.com/compute/docs/viewing-and-applying-idle-resources-recommendations
- Baja de Deployment Manager: https://cloud.google.com/deployment-manager/docs/deprecations
- Infrastructure Manager y Terraform: https://cloud.google.com/infrastructure-manager/docs/terraform

### Herramientas de terceros (opcional)

No forman parte del material de referencia del curso; se listan solo porque el laboratorio
local las utiliza.

- Terraform (CLI y lenguaje): https://developer.hashicorp.com/terraform/docs
- Provider de Terraform para Google Cloud: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- kind (Kubernetes in Docker): https://kind.sigs.k8s.io/
- fake-gcs-server: https://github.com/fsouza/fake-gcs-server
- Keycloak: https://www.keycloak.org/documentation
