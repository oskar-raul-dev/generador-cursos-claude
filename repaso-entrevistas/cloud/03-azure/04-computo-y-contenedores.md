# 04 — Cómputo y contenedores

> **Objetivo:** elegir dónde corre una aplicación Java en Azure y defender la elección: VMs, VM Scale
> Sets, App Service, Container Apps, AKS y Functions, con Container Registry como origen de las
> imágenes.
> **Se asume leído:** [`01`](01-infraestructura-global-y-resource-manager.md) (zonas y resource
> groups) y [`02`](02-redes-vnet-nsg-y-enrutamiento.md) (VNets y salida a Internet).
> **Se toca más con:** [`05` — balanceo y entrega](05-balanceo-entrega-global-y-api-management.md), que pone tráfico delante de estas
> plataformas, y el [`09`](09-identidad-entra-id-y-managed-identities.md) (identidad), que les da una managed identity.
> **Se practica en:** [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) (Container Apps y Container Registry). VMs, App Service y AKS quedan fuera
> del tronco: ver [`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones).
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [El mapa](#1--el-mapa-cuánto-administras-tú) · [VMs](#2--virtual-machines) ·
[VM Scale Sets](#3--vm-scale-sets) · [App Service](#4--app-service) ·
[Container Apps](#5--container-apps) · [Revisiones y tráfico](#6--revisiones-y-reparto-de-tráfico) ·
[Escalado](#7--escalado-con-keda-y-escala-a-cero) · [AKS](#8--aks-a-nivel-de-decisión) ·
[Functions](#9--azure-functions) · [Container Registry](#10--container-registry) ·
[Spring Boot](#11--dónde-correr-spring-boot-hoy) · [Decisión](#12--la-decisión) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El mapa: cuánto administras tú

Te piden correr una API Spring Boot en Azure. Hay seis respuestas posibles, y la pregunta que las
ordena no es "cuál es la mejor", sino **cuánto quieres administrar tú y cuánto delegas**:

```text
Más control, más trabajo                                  Menos control, menos trabajo
        │                                                               │
   VM ── VM Scale Set ── AKS ── Container Apps ── App Service ── Functions
        │                 │            │                │             │
   sistema operativo   Kubernetes   contenedor      código o      una función
   y todo lo demás     completo     sin Kubernetes  contenedor    por evento
```

Tres ejes cambian de un extremo al otro: quién parchea el sistema operativo, quién decide cuántas
instancias hay y **si puedes escalar a cero** —pagar nada cuando no hay tráfico—. El resto del
capítulo recorre cada plataforma con esos tres ejes delante.

---

## 2. 🧱 Virtual Machines

Una VM es cómputo con el sistema operativo a tu cargo: parches, agentes, runtime de Java, arranque
del servicio. Lo que se pregunta:

- **tamaños y familias**: B (burstable, barata, para cargas intermitentes), D (propósito general), E
  (memoria), F (cómputo), y las especializadas (N con GPU, L con almacenamiento local, M con mucha
  memoria). El nombre codifica familia, vCPU y variantes: `Standard_D4s_v5` es de propósito general,
  4 vCPU, admite discos Premium (`s`), quinta generación;
- **discos**: todo disco es un managed disk, que factura aunque la VM esté detenida ([`06`](06-almacenamiento-storage-accounts.md));
- **"detenida" no es "desasignada"**: una VM apagada desde el sistema operativo sigue reservando el
  hardware y **sigue facturando cómputo**. Solo `az vm deallocate` (o detenerla desde Azure) libera
  el hardware y deja de cobrar el cómputo; el disco sigue cobrando;
- **Spot**: capacidad sobrante a precio muy reducido que Azure puede reclamar con poco aviso. Sirve
  para cargas interrumpibles, nunca para tu API de producción.

**Availability set frente a Availability Zones:** un *availability set* reparte VMs entre dominios de
fallo (racks) y de actualización **dentro de un datacenter**; las zonas las reparten entre datacenters
separados. Un availability set no protege de la caída de un datacenter, y no se combina con zonas: se
elige uno de los dos, y en una región con zonas la respuesta moderna es zonas.

> 💰 **Costo.** Una B1ls cuesta **$0.0052/h** en `eastus2`; una B2ats v2, **$0.0094/h**; su disco de
> sistema Standard SSD de 32 GiB (E4), **$2.40 al mes**. La VM se deja de cobrar al desasignarla; el
> disco, solo al borrarlo.

---

## 3. 🧱 VM Scale Sets

Un **VM Scale Set** (VMSS) gestiona un grupo de VMs como una unidad: autoscale por métricas o por
horario, reparto entre zonas, políticas de actualización y reparación automática de instancias. Tiene
dos modos de orquestación, que se eligen al crearlo y **no se pueden cambiar después**:

| Criterio | Flexible (recomendado) | Uniform |
|---|---|---|
| Qué son las instancias | VMs estándar de Azure | VMs propias del scale set |
| Mezclar tamaños, Spot y bajo demanda | ✅ | ❌ |
| APIs de VM, RBAC por instancia, Azure Backup | ✅ | ❌ |
| Salida a Internet por defecto | ❌ requiere método explícito | ✅ |

La fila de la salida conecta con el [`02` §7](02-redes-vnet-nsg-y-enrutamiento.md#7--salida-a-internet): un scale set Flexible es *secure by default* y
sus instancias no tienen salida implícita a Internet; si tu aplicación llama a una API externa, le
hace falta un NAT Gateway o equivalente. Uniform queda para casos concretos, como los node pools de
AKS o Service Fabric, que lo usan por debajo.

---

## 4. 🧱 App Service

**El problema:** quieres desplegar un JAR y que alguien más se ocupe del sistema operativo, del
balanceo entre instancias, del certificado TLS y de los despliegues sin caída.

**App Service** es una plataforma para aplicaciones web y APIs. La pieza que hay que entender primero
es el **App Service plan**:

> Regla importante: el plan es el cómputo; las apps viven dentro del plan y comparten sus
> instancias.

Escalas el plan, no la app: si pones cuatro apps en un plan de dos instancias, las cuatro corren en
las mismas dos instancias. El plan define el tier (Free, Basic, Standard, Premium, Isolated), el
tamaño y el número de instancias, y **factura por hora aunque las apps no reciban tráfico**: App
Service no escala a cero.

Para Java ofrece tres stacks: **Java SE** (tu JAR con servidor embebido, el caso típico de Spring
Boot), **Tomcat** (despliegas un WAR) y **JBoss EAP**. También acepta un contenedor propio.

**Deployment slots**, la característica que más se pregunta:

- desde el tier **Standard** puedes tener slots, que son apps vivas con su propio host
  (`api-staging.azurewebsites.net`), en el mismo plan y sin cargo extra;
- despliegas en `staging`, lo validas y haces **swap** con producción. Antes de intercambiar las
  rutas, App Service aplica la configuración de producción a las instancias de `staging`, las
  reinicia y **las calienta** con una petición; si alguna falla, el swap se revierte. Producción no
  se toca hasta que la otra está lista;
- el rollback es otro swap inmediato;
- algunas configuraciones **viajan con el swap** (app settings, connection strings, versión de Java)
  y otras **se quedan en el slot** (dominios, escalado, managed identity, integración con VNet, y las
  app settings que marques como *slot setting*). Olvidar marcar como slot setting la URL de la base
  de datos de staging es la forma clásica de apuntar producción a la base de pruebas.

Otras dos piezas: **Always On**, que evita que la app se descargue tras un rato sin tráfico, y **VNet
integration**, que permite que la app **salga** hacia recursos de tu VNet. La entrada privada a la app
es otra cosa: un private endpoint ([`03`](03-conectividad-privada-y-dns.md)).

---

## 5. 🧱 Container Apps

**El problema:** tienes una imagen de contenedor y quieres revisiones, reparto de tráfico, escala
basada en eventos y escala a cero, sin administrar un cluster de Kubernetes.

**Azure Container Apps** es una plataforma serverless de contenedores construida sobre Kubernetes,
KEDA y Envoy, **sin exponerte la API de Kubernetes**. Ese es el trato: renuncias a los objetos de
Kubernetes a cambio de no operar un cluster. Sus piezas:

- **Environment**: la frontera de red y de logs que comparten varias apps. Las apps de un mismo
  environment se ven entre sí por nombre;
- **Container app**: un servicio de larga duración, con **ingress** HTTP o TCP opcional, externo
  (Internet) o interno (solo el environment o la VNet);
- **Job**: una tarea que termina, disparada manualmente, por horario o por eventos;
- **Revisión**: una instantánea inmutable de la app (§6);
- **Réplica**: una instancia en ejecución de una revisión.

Dos planes:

- **Consumption**: serverless, escala a cero, pagas por vCPU-segundo y GiB-segundo mientras hay
  réplicas y por requests;
- **Dedicated** con *workload profiles*: hardware dedicado o GPU dentro del mismo tipo de
  environment, con un cargo de gestión por hora además del cómputo.

Crear la app del laboratorio con su identidad y su registry:

```bash
az containerapp create \
  --name inv-api \
  --resource-group inv-lab-rg \
  --environment inv-lab-env \
  --image invlabacr472913.azurecr.io/inv-api:0.1.0 \
  --user-assigned inv-api-id \
  --registry-server invlabacr472913.azurecr.io \
  --registry-identity "$(az identity show --name inv-api-id --resource-group inv-lab-rg --query id --output tsv)" \
  --ingress external \
  --target-port 8080 \
  --min-replicas 0 \
  --max-replicas 3
```

- `--image` usa una **etiqueta fija** (`0.1.0`), nunca `latest`: una revisión es inmutable, y una
  etiqueta móvil hace que dos revisiones "iguales" corran código distinto según cuándo se tiró la
  imagen.
- `--user-assigned inv-api-id` le asigna a la app la managed identity con la que hablará con el resto
  de Azure ([`09`](09-identidad-entra-id-y-managed-identities.md)).
- `--registry-server` y `--registry-identity` le dicen a la plataforma **con qué identidad tirar la
  imagen** del registry privado. La identidad necesita el rol `AcrPull` sobre el registry. Sin
  `--registry-identity`, la alternativa es habilitar el *admin user* del registry y guardar su
  contraseña en la app, que es exactamente la credencial que el curso evita.
- `--ingress external` publica un FQDN HTTPS en Internet, con certificado administrado; `internal` lo
  dejaría visible solo dentro del environment.
- `--target-port 8080` es el puerto en el que **escucha tu contenedor**. Si Spring Boot escucha en
  8080 y declaras otro, la revisión nunca pasa a lista: el tráfico no llega y el log dice que el
  puerto no responde. [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) reproduce ese fallo a propósito.
- `--min-replicas 0` permite la escala a cero, que es el valor por defecto; se escribe para que la
  decisión sea visible. `--max-replicas 3` pone un techo al gasto: el defecto es 10.

> ⚠️ **`az containerapp env create` sin `--logs-workspace-id` crea un Log Analytics workspace nuevo**
> con nombre aleatorio. El laboratorio declara el suyo (`inv-lab-law`) para saber qué existe y qué
> hay que borrar ([`L00` §6](l00-idea-lab-practico.md#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas)).

> 💰 **Costo.** En `eastus2`, Consumption cobra **$0.000024 por vCPU-segundo** activo y **$0.000003 por
> GiB-segundo**, y **$0.40 por millón de requests**. Los primeros 180.000 vCPU-segundos, 360.000
> GiB-segundos y 2 millones de requests por suscripción y mes no se cobran. Con réplicas a cero no hay
> cargo de uso.

---

## 6. 🧱 Revisiones y reparto de tráfico

Una **revisión** es una instantánea inmutable de la app. Qué crea una revisión nueva y qué no es lo
primero que conviene fijar:

- **cambios de ámbito de revisión** —todo lo que está bajo `properties.template`: imagen,
  variables, recursos, reglas de escalado, sufijo de revisión— **crean una revisión nueva**;
- **cambios de ámbito de aplicación** —bajo `properties.configuration`: secretos, ingress, reparto
  de tráfico, modo de revisiones, credenciales del registry— **se aplican a todas las revisiones sin
  crear una nueva**. Con un matiz: un secreto nuevo no lo ve un contenedor en ejecución hasta que la
  revisión se reinicia.

Los modos de revisión:

- **Single** (por defecto): solo una revisión activa. Al desplegar, la nueva arranca, escala hasta
  igualar a la anterior, pasa sus probes y **solo entonces** recibe el tráfico; si falla, el tráfico
  se queda en la anterior. Despliegue sin caída, sin decisiones;
- **Multiple**: varias revisiones activas a la vez, con reparto de tráfico por porcentaje y
  **labels** que dan a una revisión una URL propia estable. Es el modo del canary y del blue/green;
- **Deployment labels** (en preview): etiquetas con nombre (`staging`, `prod`) que se mueven entre
  revisiones.

Se conservan hasta 100 revisiones inactivas, que no cobran y se pueden reactivar para un rollback.

```bash
az containerapp revision set-mode \
  --name inv-api \
  --resource-group inv-lab-rg \
  --mode multiple

az containerapp ingress traffic set \
  --name inv-api \
  --resource-group inv-lab-rg \
  --revision-weight inv-api--v1=80 inv-api--v2=20
```

- `revision set-mode --mode multiple` es un cambio de ámbito de aplicación: no crea revisión, pero
  habilita tener varias activas.
- `ingress traffic set --revision-weight` reparte el tráfico del FQDN de la app entre revisiones por
  nombre; los pesos deben sumar 100. Los nombres siguen el formato `<app>--<sufijo>`. Para un canary
  se empieza por un peso pequeño y se sube mientras las métricas acompañan.

---

## 7. 🧱 Escalado con KEDA y escala a cero

Container Apps escala **horizontalmente** —añade réplicas, no las agranda— con reglas declarativas
implementadas con KEDA:

- **HTTP**: por peticiones concurrentes; el umbral por defecto es **10** por réplica;
- **TCP**: por conexiones concurrentes;
- **Custom**: cualquier scaler de KEDA —Service Bus, Event Hubs, Kafka, Redis, colas de Storage—, y
  también CPU y memoria.

Los defectos que conviene saber de memoria:

```text
Réplicas: mínimo 0, máximo 10 (configurable hasta 1.000)
Polling de scalers de eventos: 30 s
Cooldown antes de bajar de la última réplica a 0: 300 s
Subida: 1, 4, 8, 16, 32… réplicas por paso
```

Tres trampas:

- **las reglas de CPU y memoria no pueden escalar a cero**: necesitan una réplica corriendo para
  medir;
- **sin ingress y sin regla propia, la app escala a cero y no vuelve a arrancar nunca**: no hay
  tráfico HTTP que la despierte. Una app que consume de una cola necesita su regla de KEDA;
- **las reglas de eventos admiten managed identity**: un scaler de Service Bus puede autenticarse con
  la identidad de la app en vez de con una connection string guardada como secreto. Es lo que usa
  `inv-projector` en [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md).

El precio de la escala a cero es el **cold start**, y con la JVM es real: la primera petición tras un
período sin tráfico espera a que arranque el contenedor y Spring Boot. Las salidas son tres, cada una
con su costo:

- `--min-replicas 1`: nunca hay cold start, pero la réplica cobra siempre. Una réplica de 0,5 vCPU
  en reposo consume unos 43.200 vCPU-segundos al día, así que se come la cuota gratuita del mes en
  unos cuatro días; después, cobra la tarifa reducida de réplica inactiva;
- reducir el arranque de la aplicación (menos autoconfiguración, class data sharing, una imagen
  nativa);
- aceptar la latencia de la primera petición cuando el tráfico lo tolera.

---

## 8. 🧱 AKS a nivel de decisión

**Azure Kubernetes Service** es Kubernetes administrado: Azure opera el control plane y tú los nodos,
que son VMs de un scale set. Lo que se pregunta en una entrevista de backend no es cómo operarlo,
sino cuándo elegirlo.

- **Tiers del control plane**: **Free** (sin cargo de gestión, sin SLA financiado, recomendado por
  debajo de 10 nodos y para pruebas), **Standard** (SLA del API server del 99,95 % con zonas o 99,9 %
  sin ellas, hasta 5.000 nodos) y **Premium** (Standard más soporte extendido de versiones, LTS de 24
  meses). **AKS Automatic** es la experiencia preconfigurada que Microsoft recomienda para producción
  y usa Standard.
- **Node pools**: uno de sistema (los componentes de Kubernetes) y los de usuario (tus cargas), cada
  uno con su tamaño de VM y su escalado.
- **Integración con Azure**: un `Service` de tipo `LoadBalancer` crea un Load Balancer y una IP
  pública; la red de los pods consume IPs de tu VNet según el modelo de red elegido; y **workload
  identity** da a un pod una identidad de Entra ID sin secretos ([`09`](09-identidad-entra-id-y-managed-identities.md)).

> Nunca respondas: "elegimos AKS porque es lo estándar". Mejor: "elegimos AKS cuando necesitamos la
> API de Kubernetes —operadores, CRDs, DaemonSets, sidecars a medida, portabilidad entre nubes— y
> tenemos equipo para operarlo; si no, Container Apps da revisiones, escalado por eventos y escala a
> cero sin cluster".

> 💰 **Costo.** El tier Standard cobra **$0.10/h** por cluster por la gestión, y en cualquier tier se
> pagan los nodos como VMs, más discos, balanceador e IPs públicas. Por eso AKS es un drill de
> [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales) y no un lab.

---

## 9. 🧱 Azure Functions

**Functions** ejecuta código disparado por eventos —HTTP, un mensaje de Service Bus, un blob nuevo,
un temporizador— con **triggers** (qué lo dispara) y **bindings** (entradas y salidas declarativas).
El plan de hosting decide casi todo:

| Plan | Escala a cero | Cold start | Red privada |
|---|---|---|---|
| **Flex Consumption** (el recomendado para serverless) | ✅ | Reducido; admite instancias siempre listas | ✅ VNet integration |
| **Premium** | ❌ siempre una instancia caliente | Sin cold start | ✅ |
| **Dedicated** (App Service plan) | ❌ | Sin cold start con Always On | ✅ |
| **Container Apps** | ✅ si mínimo 0 | Según réplicas mínimas | ✅ |

> 📝 **Contexto.** El plan **Consumption** clásico es ahora *legacy*. En Linux no recibe funciones ni
> versiones de lenguaje nuevas y **se retira el 30 de septiembre de 2028**; para apps nuevas, la
> documentación indica Flex Consumption. Mucho material de estudio sigue presentando "el plan
> Consumption" como la opción serverless por defecto.

Dos límites que se preguntan: en Consumption una ejecución dura como máximo 10 minutos (5 por
defecto), y **cualquier función HTTP tiene 230 segundos para responder**, sea cual sea el plan, por el
timeout del balanceador que tiene delante. El trabajo largo se desacopla con una cola o con Durable
Functions ([`16`](16-orquestacion-y-cicd.md)).

---

## 10. 🧱 Container Registry

**Azure Container Registry** (ACR) guarda tus imágenes y artefactos OCI. Tres tiers con las mismas
APIs:

- **Basic**: 10 GiB incluidos, para aprender y cargas pequeñas;
- **Standard**: 100 GiB, suficiente para la mayoría de la producción;
- **Premium**: 500 GiB, y lo exclusivo: **geo-replicación**, **private endpoints**, reglas de IP,
  customer-managed keys y retención de manifiestos sin etiqueta.

Tres prácticas que se preguntan:

- **autenticación con Entra ID**: la plataforma tira la imagen con una managed identity que tiene
  `AcrPull`; el *admin user* (usuario y contraseña compartidos) se deja deshabilitado;
- **ACR Tasks**: construir la imagen en Azure con `az acr build`, sin Docker local. Cómodo, pero
  esconde el paso que [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) quiere que veas;
- **un registry cercano a la carga**: tirar imágenes de otra región cuesta latencia y tráfico; en
  multi-región, geo-replicación.

> 💰 **Costo.** Basic cuesta **$0.1666 al día** en `eastus2`, con 10 GiB incluidos. La unidad es el
> día, no la hora: por eso el laboratorio lo crea una vez y lo borra al final de la serie
> ([`L00` §6](l00-idea-lab-practico.md#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas)).

---

## 11. 🧱 Dónde correr Spring Boot hoy

> 📝 **Contexto.** Durante años la respuesta de manual fue "Azure Spring Apps". Ya no: **todos sus
> planes (Basic, Standard y Enterprise) entraron en período de retiro el 17 de marzo de 2025, no
> aceptan clientes nuevos desde esa fecha y se retiran el 31 de marzo de 2028.** Los clientes
> existentes siguen operando hasta entonces con SLA. Microsoft recomienda migrar a Container Apps o
> a AKS.

La respuesta de 2026, en orden de preferencia para una API típica:

1. **Container Apps**, si ya empaquetas en contenedor y quieres revisiones, canary, escalado por
   eventos o escala a cero;
2. **App Service con Java SE**, si prefieres desplegar un JAR sin tocar contenedores y la app corre
   siempre (no necesitas escala a cero);
3. **AKS**, si la organización ya opera Kubernetes o necesitas su API;
4. **Functions**, para piezas disparadas por eventos, no para la API principal.

Y en cualquiera de ellas: identidad administrada en vez de secretos ([`09`](09-identidad-entra-id-y-managed-identities.md)), configuración
externa, logs a Application Insights ([`14`](14-observabilidad-monitor-log-analytics-app-insights.md)) y health probes de verdad
(`/actuator/health/liveness` y `/readiness`), porque la plataforma decide con ellos cuándo una
instancia recibe tráfico.

---

## 12. ⚖ La decisión

| Necesito… | Elige | Por qué |
|---|---|---|
| Control total del sistema operativo o software no contenedorizable | VM o VMSS Flexible | Solo ahí controlas el SO |
| Desplegar un JAR, slots de staging, sin contenedores | App Service | Slots con swap caliente; el plan corre siempre |
| Contenedores con revisiones, eventos y escala a cero | Container Apps | Sin cluster que operar |
| La API de Kubernetes o portabilidad entre nubes | AKS | Operadores, CRDs, DaemonSets |
| Código corto disparado por eventos | Functions (Flex Consumption) | Triggers y bindings, escala a cero |

```text
Regla de entrevista:
Empieza por la plataforma más administrada que cumpla el requisito,
y baja un escalón solo cuando un requisito concreto te obligue.
```

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Container Apps es AKS administrado" | Corre sobre Kubernetes pero no expone su API |
| "Apagué la VM, ya no cobra" | Apagada desde el SO sigue cobrando; hay que desasignarla, y el disco sigue |
| "App Service escala a cero" | El plan factura por hora siempre |
| "Spring Boot en Azure es Azure Spring Apps" | Cerrado a clientes nuevos desde 2025 y retirado el 31-03-2028 |
| "Functions no tiene cold start" | Solo Premium, Dedicated o instancias siempre listas lo evitan |
| "El plan Consumption es el serverless por defecto" | Es legacy; en Linux se retira el 30-09-2028; el recomendado es Flex Consumption |
| "Un availability set protege de la caída de un datacenter" | Reparte en racks de un datacenter; eso lo hacen las zonas |
| "Con ingress deshabilitado la app escala sola" | Sin regla propia ni mínimo de réplicas, escala a cero y no vuelve |

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia hay entre detener una VM desde el sistema operativo y desasignarla, en términos de facturación?
2. ¿Qué protege un availability set y qué protegen las Availability Zones?
3. ¿Por qué la orquestación Flexible de un VM Scale Set es la recomendada y qué implica para la salida a Internet?
4. En App Service, ¿qué se escala: la app o el plan? ¿Y qué pasa con cuatro apps en un plan de dos instancias?
5. ¿Qué hace App Service antes de intercambiar las rutas en un swap de slots, y qué configuraciones no viajan con el swap?
6. ¿Qué expone Container Apps y qué no expone respecto de Kubernetes?
7. ¿Qué cambios crean una revisión nueva en Container Apps y cuáles se aplican a todas sin crearla?
8. ¿Qué diferencia hay entre el modo de revisión single y el multiple, y cuál usarías para un canary?
9. Una app de Container Apps sin ingress consume de una cola de Service Bus y se quedó a cero réplicas para siempre. ¿Qué falta?
10. ¿Por qué las reglas de escalado por CPU o memoria no pueden llevar una app a cero réplicas?
11. ¿Qué opciones tienes para mitigar el cold start de Spring Boot en Container Apps y qué cuesta cada una?
12. ¿Cuándo elegirías AKS en lugar de Container Apps?
13. ¿Qué plan de Functions es el recomendado para serverless y qué pasa con el plan Consumption en Linux?
14. ¿Cómo debe autenticarse Container Apps para tirar imágenes de un Container Registry privado, y por qué no con el admin user?
15. ¿Qué está pasando con Azure Spring Apps y qué plataformas recomienda Microsoft en su lugar?

---

## 📚 Referencias oficiales

- Tamaños de VM: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/overview
- Estados de energía de una VM y facturación: https://learn.microsoft.com/en-us/azure/virtual-machines/states-billing
- Availability sets: https://learn.microsoft.com/en-us/azure/virtual-machines/availability-set-overview
- Modos de orquestación de VM Scale Sets: https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
- Planes de App Service: https://learn.microsoft.com/en-us/azure/app-service/overview-hosting-plans
- Deployment slots de App Service: https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots
- Configurar una app Java en App Service: https://learn.microsoft.com/en-us/azure/app-service/configure-language-java-deploy-run
- ¿Qué es Azure Container Apps?: https://learn.microsoft.com/en-us/azure/container-apps/overview
- Planes de Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/plans
- Revisiones de Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/revisions
- Reparto de tráfico en Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/traffic-splitting
- Escalado en Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/scale-app
- Managed identity en Container Apps (incluido el pull del registry): https://learn.microsoft.com/en-us/azure/container-apps/managed-identity
- Facturación de Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/billing
- Tiers de AKS: https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers
- ¿Qué es AKS Automatic?: https://learn.microsoft.com/en-us/azure/aks/intro-aks-automatic
- Planes de hosting de Azure Functions: https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale
- Plan Flex Consumption: https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan
- Tiers de Container Registry: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-skus
- Autenticación en Container Registry: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication
- Anuncio de retiro de Azure Spring Apps: https://learn.microsoft.com/en-us/azure/spring-apps/basic-standard/retirement-announcement
- Precios de Container Apps: https://azure.microsoft.com/en-us/pricing/details/container-apps/
- Precios de Container Registry: https://azure.microsoft.com/en-us/pricing/details/container-registry/
- Precios de Virtual Machines Linux: https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/
- `az containerapp`: https://learn.microsoft.com/en-us/cli/azure/containerapp
- `az containerapp ingress traffic`: https://learn.microsoft.com/en-us/cli/azure/containerapp/ingress/traffic
