# A02 — Costos, trampas y recursos huérfanos

> **Objetivo:** saber, antes de crear algo, si cobra por hora, si entra en el Always Free y qué
> deja atrás cuando lo borras. Es el apéndice que se consulta antes de encender un drill y
> después de cada sesión, y el catálogo que sostiene el barrido de
> [`L08`](l08-costos-y-destruccion-verificada.md).
> **Se asume leído:** nada, aunque [`L00` §6](l00-idea-lab-practico.md#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas)
> da el contexto de por qué este documento existe.
> **Precios de referencia:** `us-central1`, orden de magnitud, verificados contra las páginas de
> pricing oficiales enlazadas al final. **Cambian por región y sin aviso: confírmalos en la
> [calculadora](https://cloud.google.com/products/calculator) antes de encender nada.**
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Las tres preguntas](#1--las-tres-preguntas-antes-de-crear-cualquier-cosa) ·
[Qué es gratis de verdad](#2--qué-es-gratis-de-verdad) ·
[Lo que cobra por existir](#3--el-catálogo-de-lo-que-cobra-por-existir) ·
[Lo que cobra por uso](#4--lo-que-cobra-por-uso-y-casi-nunca-te-alcanza) ·
[Recursos huérfanos](#5--el-catálogo-de-huérfanos-qué-sobrevive-a-qué-borrado) ·
[Por qué los labels no bastan](#6--por-qué-un-barrido-por-labels-no-demuestra-nada) ·
[El barrido](#7--el-barrido-de-verificación) ·
[Presupuestos](#8--presupuestos-lo-que-hacen-y-lo-que-no) ·
[Leer la factura](#9--leer-la-factura-y-atribuir-el-gasto) ·
[Las diez trampas](#10--las-diez-trampas-en-una-tabla) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 Las tres preguntas antes de crear cualquier cosa

El gasto de un laboratorio de práctica casi nunca viene de lo que estabas practicando. Viene de
algo que creaste hace tres semanas, que no recuerdas, que no aparece en la consola de tu
proyecto activo y que cobra $0.025 la hora sin hacer absolutamente nada.

Contra eso solo hay un método, y es preguntarse tres cosas **antes** de escribir el `create`:

```text
1. ¿Cobra por existir, o solo por uso?      → §3 y §4
2. ¿Qué cuota del Always Free lo cubre?     → §2
3. Cuando lo borre, ¿qué queda vivo?        → §5
```

La tercera es la que casi nadie se hace y la que produce la factura sorpresa. En GCP hay una
buena razón para hacérsela siempre: **muchos recursos crean otros recursos en tu nombre**, y
esos hijos no siempre mueren con el padre.

> 🧠 **Modelo mental.** Un recurso de nube tiene dos costos: el que pagas mientras lo usas y el
> que pagas mientras te olvidaste de él. El segundo es el caro, porque no tiene techo temporal.

---

## 2. 🧱 Qué es gratis de verdad

Hay tres mecanismos distintos y conviene no mezclarlos, porque el material de estudio los
confunde constantemente.

| Mecanismo | Qué es | Cuándo se acaba |
|---|---|---|
| Crédito de bienvenida | $300 para gastar en casi cualquier producto | A los 90 días o al agotarse |
| Free Tier ("Always Free") | Cuota mensual por producto, sin fecha de caducidad | Se renueva cada mes mientras Google la mantenga |
| Crédito del Free Tier de GKE | $74.40 mensuales aplicados a la tarifa de administración de clusters | Se renueva cada mes; **solo** cubre el control plane |

> 📝 **Contexto.** "GCP es gratis 90 días" es la simplificación que más caro sale. Lo cierto es
> que **el crédito y el Always Free son independientes**: cuando el crédito vence, el Always
> Free sigue. Un laboratorio diseñado contra el crédito caduca en tres meses; uno diseñado
> contra el Always Free, no. Por eso el tronco `L01`–`L08` cabe entero en el segundo.

Las cuotas que sostienen esta serie, tal como las publica Google en la página de Free Tier:

| Producto | Cuota Always Free mensual | Qué la consume en el lab |
|---|---|---|
| Cloud Run | 2 M requests, 360.000 GiB-s, 180.000 vCPU-s | Cada invocación de `inv-api`; el lab no llega ni al 1 % |
| Pub/Sub | 10 GiB de mensajes | Los eventos de `inv-events`, que pesan bytes |
| Firestore | 1 GiB; 50.000 lecturas, 20.000 escrituras, 20.000 borrados **al día** | Escrituras de `events` y `stock` |
| Cloud Storage | 5 GiB-mes en regiones de EE. UU., 5.000 ops clase A, 50.000 clase B | El bucket de state de Terraform y el de datos |
| Cloud Logging | 50 GiB de ingesta por proyecto | Los logs de los tres servicios |
| Cloud Build | 2.500 build-minutes | Nada en el tronco: el curso construye en local |
| Artifact Registry | 0,5 GB de almacenamiento | **Esto sí se agota.** Ver §3 |
| Secret Manager | 6 versiones activas, 10.000 accesos | El secreto de [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) |

> ⚠️ **Las cuotas del Free Tier son por región y por cuenta de facturación, y cambian.** Las de
> Cloud Storage y Compute Engine solo aplican en determinadas regiones de EE. UU., y es la razón
> por la que el baseline del curso fija `us-central1`. Crear el mismo bucket en
> `southamerica-east1` te saca del Always Free sin ningún aviso.

---

## 3. 💰 El catálogo de lo que cobra por existir

Esta es la lista importante: recursos que facturan **mientras existan**, hagas o no hagas nada
con ellos. Son los que producen la factura de la que nadie se acuerda.

| Recurso | Orden de magnitud | Qué lo dispara |
|---|---|---|
| Forwarding rule (regla de un load balancer) | ~$0.025/h → ~$18/mes | Crear cualquier load balancer, o un `Ingress` de GKE |
| IP externa estática **no adjunta** | Tarifa por hora, **más cara que una en uso** | Reservarla "para después" y no adjuntarla |
| Persistent Disk | Por GiB-mes, tenga o no una VM adjunta | Borrar la VM sin borrar el disco |
| Snapshot de disco | Por GiB-mes de datos incrementales | Un snapshot que nadie borra jamás |
| Instancia de Cloud SQL | Por hora de instancia **y** por GiB de almacenamiento | Existir. Detenida sigue cobrando el almacenamiento |
| Cluster de GKE | $0.10/h de administración, más nodos o Pods | Existir, aunque esté vacío |
| Cloud NAT gateway | Por hora de gateway más por GiB procesado | Existir |
| Memorystore | Por hora y por GiB | Existir |
| VPN tunnel / Interconnect | Por hora de túnel o de attachment | Existir |
| Artifact Registry por encima de 0,5 GB | Por GB-mes | Cada `docker push` de una imagen nueva |

Tres de esos merecen su propio párrafo porque son los que tocan a este curso.

**Forwarding rules.** Es la trampa número uno de los proyectos de práctica. No la creas
directamente casi nunca: la crea el load balancer, la crea un `Ingress` de GKE, la crea un
`Service` de tipo `LoadBalancer`. Y sobrevive al borrado del objeto que la pidió si no borras
ese objeto en el orden correcto. Por eso el tronco de la serie no usa ningún load balancer:
Cloud Run ya publica una URL HTTPS con certificado administrado y **no cobra por ella**.

**IP externas estáticas.** Aquí hay una asimetría que sorprende a todo el mundo: una IP externa
reservada **cuesta más cuando no está adjunta a nada** que cuando está en uso. Google lo cobra
así deliberadamente, porque una IP reservada y ociosa es un recurso escaso retenido sin motivo.
Es exactamente el estado en que quedan después de un experimento a medias.

**Artifact Registry.** Es el único cargo real que genera el tronco de esta serie, y aparece por
acumulación: la cuota gratuita es de 0,5 GB y **cada despliegue deja una imagen más**. Cinco
despliegues de una imagen de 200 MB ya se pasan. No es dinero serio —son centavos— pero es la
demostración perfecta de cómo se acumula un costo que nadie decidió. Se limpia en
[`L08`](l08-costos-y-destruccion-verificada.md).

---

## 4. 💰 Lo que cobra por uso, y casi nunca te alcanza

La otra mitad del catálogo: recursos que cuestan $0.00 mientras nadie los toque. Existir es
gratis; usarlos cuesta, y en el volumen de un laboratorio el uso cabe en el Always Free.

| Recurso | Cobra por | Existir vacío cuesta |
|---|---|---|
| Servicio de Cloud Run | vCPU-s, GiB-s y requests mientras atiende | $0.00 con escalado a cero |
| Topic y subscription de Pub/Sub | Volumen de mensajes | $0.00 |
| Base de datos de Firestore | Almacenamiento, lecturas, escrituras, borrados | Casi $0.00 vacía |
| Bucket de Cloud Storage | GiB-mes y operaciones | $0.00 vacío |
| Trigger de Eventarc | Los eventos que entrega (vía Pub/Sub) | $0.00 |
| Service account, rol, binding | Nada | $0.00 |
| VPC, subnet, firewall rule | Nada | $0.00 |
| Secret de Secret Manager | Versiones activas y accesos | $0.00 dentro de la cuota |
| Log-based metric, alerting policy | La ingesta de logs asociada | $0.00 |

> 💰 **Costo.** Esta tabla es la razón de que el laboratorio sea como es. Todo lo del tronco
> vive en esta lista salvo Artifact Registry — y la única excepción se limpia a mano. Cuando
> [`L00`](l00-idea-lab-practico.md) dice "menos de $1 la serie completa", sale de aquí.

Hay una excepción dentro de Cloud Run que conviene marcar, porque el flag es tentador:

> ⚠️ **`--min-instances` rompe el escalado a cero.** Una instancia mínima significa una
> instancia encendida siempre, y por lo tanto vCPU y memoria facturando 24/7 aunque no llegue
> ni un request. Es la forma más fácil de convertir un servicio gratuito en uno que cobra por
> hora. [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) lo activa un momento para verlo y lo vuelve a poner en cero antes de cerrar.

---

## 5. 💰 El catálogo de huérfanos: qué sobrevive a qué borrado

La sección que hay que leer **antes** de borrar, no después. Cada fila es un caso real de "lo
borré y me siguió cobrando".

| Borras… | Sobrevive… | Por qué |
|---|---|---|
| Una VM de Compute Engine | Su Persistent Disk, si no tenía `auto-delete` | El disco es un recurso independiente que estaba adjunto |
| Un disco | Sus snapshots | Un snapshot es un recurso propio con su propio ciclo de vida |
| Un cluster de GKE | Los `PersistentVolume`, con política `Delete` **o** `Retain` | GKE los retiene al borrar el cluster; el `Delete` solo actúa al borrar el PVC con el cluster vivo |
| Un cluster de GKE | Forwarding rules, backend services, URL maps y NEGs | Los creó el controlador en nombre de un `Ingress`/`Service`, y solo se van al borrar ese objeto |
| Un load balancer "desde la consola" | Reglas de firewall de health check, IP reservadas | Se crean como recursos aparte |
| Un servicio de Cloud Run | Las imágenes en Artifact Registry | El registry no sabe quién usa qué |
| Un proyecto | Presupuestos y alertas, Organization Policies | Cuelgan de la cuenta de facturación y de la jerarquía, no del proyecto |
| Un proyecto (recién borrado) | La facturación pendiente del ciclo en curso | El borrado no corta la facturación al instante |
| Una `terraform destroy` exitosa | Todo lo que no está en el state | Terraform solo destruye lo que administra |

Las dos últimas filas son las que más importan en esta serie.

**`terraform destroy` no es un teardown completo.** Solo borra lo que está en su state. Todo lo
que creaste a mano con `gcloud` para probar algo, todo lo que creó un service agent en tu
nombre y todo lo que quedó de un `apply` fallido a medias es invisible para él. Ese es
justamente el ejercicio de [`L08`](l08-costos-y-destruccion-verificada.md): que el `destroy` deje el inventario vacío **antes** de que
uses el borrado del proyecto como red de seguridad.

**Borrar el proyecto tiene letra pequeña.** Es la mejor herramienta de teardown de GCP y aun así
hay que saber tres cosas: el proyecto queda **30 días** en estado de recuperación (y sigue
contando para tu cuota de proyectos), **la facturación no se corta al instante** —lo correcto es
deshabilitar la facturación *antes* de iniciar el borrado—, y un **lien** sobre el proyecto
bloquea el borrado hasta que lo quites.

---

## 6. 🧭 Por qué un barrido por labels no demuestra nada

Es la diferencia más importante entre un teardown que crees que funcionó y uno que sí funcionó.

Los labels son la herramienta correcta para **atribuir gasto**: pones `project=inv_lab` en todo
lo que creas y el informe de facturación te dice cuánto costó el lab. Perfecto para eso.

Pero como prueba de limpieza no sirven, por una razón simple:

> ⚠️ **Los recursos que crea un controlador en tu nombre no llevan tus labels.** Las forwarding
> rules de un `Ingress` de GKE, las reglas de firewall de health check de un balanceador, los
> NEGs: nada de eso pasó por tu `--labels`. Un barrido por `labels.project=inv_lab` pasa justo
> por encima de los huérfanos que estás buscando.

Y hay un segundo motivo, más prosaico: **no todos los tipos de recurso admiten labels**. Una
firewall rule, por ejemplo, no lleva labels; lleva `target-tags`, que son otra cosa.

La conclusión operativa, que es la que se ejecuta en [`L08`](l08-costos-y-destruccion-verificada.md):

```text
labels        →  para saber CUÁNTO costó
Asset Inventory + barrido dirigido  →  para demostrar que NO QUEDÓ NADA
```

---

## 7. 🩺 El barrido de verificación

Tres capas, de la más general a la más específica. Ninguna sustituye a las otras.

**Capa 1 — el inventario completo del proyecto.** Cloud Asset Inventory ve todos los tipos de
recurso, lleven labels o no:

```bash
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --format='table(assetType, name, location)'
```

- `--scope` acepta `projects/`, `folders/` u `organizations/`. Con el proyecto basta para el
  lab.
- Sin `--filter`, devuelve **todo**: es la vista que quieres ver vacía al final de la sesión.
- Requiere que la API `cloudasset.googleapis.com` esté habilitada, y el rol
  `roles/cloudasset.viewer`.

> ⚠️ El índice de Asset Inventory **no es instantáneo**. Un recurso recién borrado puede seguir
> apareciendo unos minutos. Si algo sale en la lista y ya no existe, confírmalo con el `describe`
> del servicio antes de asustarte.

**Capa 2 — el barrido dirigido a los sospechosos.** Los cinco tipos que producen el 90 % de las
facturas sorpresa, uno por uno y sin filtrar por label:

```bash
gcloud compute forwarding-rules list --format='table(name, region, IPAddress)'
gcloud compute addresses list        --format='table(name, region, status)'
gcloud compute disks list            --format='table(name, zone, users.list())'
gcloud compute snapshots list        --format='table(name, diskSizeGb)'
gcloud compute firewall-rules list   --format='table(name, network, direction)'
```

- En `addresses`, la columna `status` es la que importa: `RESERVED` significa reservada y **no
  adjunta**, o sea la tarifa cara. `IN_USE` es la barata.
- En `disks`, `users.list()` muestra a qué VM está adjunto el disco. Vacío significa huérfano.
- Estos comandos son **globales al proyecto**: no los limites por región, porque el huérfano
  suele estar en la región donde probaste algo una vez.

**Capa 3 — los recommenders.** Google mantiene detectores de recursos ociosos que ven cosas que
tú no vas a mirar:

```bash
gcloud recommender recommendations list \
  --project=inv-lab-472913 \
  --location=us-central1-a \
  --recommender=google.compute.disk.IdleResourceRecommender \
  --format='table(name, primaryImpact.category, description)'
```

- `--recommender` selecciona el detector. Hay uno para discos ociosos, otro para direcciones IP
  sin usar, otro para VMs infrautilizadas; el catálogo completo está en las referencias.
- `--location` aquí es zonal o regional según el recommender, y hay que iterarla. Es incómodo, y
  por eso esta capa es la red final y no la primera.

---

## 8. 🧱 Presupuestos: lo que hacen y lo que no

Un presupuesto de Cloud Billing es lo primero que se monta en [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md), antes de crear un solo
recurso. Y conviene entender exactamente qué compra:

> ⚠️ **Un presupuesto no es un tope de gasto.** Un budget con alertas **te avisa** cuando el
> gasto cruza un umbral. No detiene nada, no apaga nada y no impide que se siga facturando.
> Responder "pongo un presupuesto de $10 y así no gasto más" en una entrevista es una respuesta
> incorrecta, y de las que se notan.

Lo que sí puedes hacer, en orden de compromiso creciente:

1. **Alertas por correo.** El default. Umbrales sobre el gasto real o el previsto.
2. **Notificación programática a un topic de Pub/Sub.** El budget publica un mensaje JSON cada
   vez que evalúa. A partir de ahí, tu código decide.
3. **Actuar sobre esa notificación.** El patrón que Google documenta llega hasta **deshabilitar
   la facturación del proyecto** desde una función que consume ese topic. Es drástico —apaga
   todo, no solo lo caro— y por eso el curso lo monta pero deja el disparo comentado.

Dos detalles de alcance que se olvidan siempre: **el presupuesto cuelga de la cuenta de
facturación, no del proyecto**, así que sobrevive al borrado del proyecto y hay que limpiarlo
aparte; y los datos de facturación **se consolidan con retraso**, del orden de horas, así que la
alerta nunca es en tiempo real.

---

## 9. 🩺 Leer la factura y atribuir el gasto

Cuando algo cobró, la pregunta es *qué* cobró. La respuesta vive en los informes de facturación
de la consola, y se lee con tres cortes:

- **Por servicio (SKU).** Te dice el producto y, dentro de él, el concepto exacto. La granularidad
  útil es el SKU: no "Compute Engine", sino "External IP address reserved but unused". Ese nivel
  es el que convierte "me cobraron $3" en "me cobraron una IP olvidada".
- **Por proyecto.** Imprescindible si tienes más de uno bajo la misma cuenta de facturación.
- **Por label.** Aquí es donde el `project=inv_lab` del baseline paga: filtras por él y sabes qué
  parte del gasto es del laboratorio. Recuerda §6: sirve para atribuir, no para demostrar
  limpieza.

> 💡 **Truco.** Si el gasto no cuadra con nada que recuerdes, ordena por SKU descendente y mira
> los tres primeros. En un proyecto de práctica, el culpable está siempre en ese podio, y casi
> siempre es una forwarding rule, una IP reservada o un disco.

Para un análisis serio existe el **export de facturación a BigQuery**, que deja los datos en
una tabla consultable con SQL. Es la herramienta correcta en una empresa y es exagerada para un
lab de $1 — se menciona aquí para que sepas que existe cuando te lo pregunten.

---

## 10. 📋 Las diez trampas, en una tabla

La versión para pegar en la pared.

| # | Trampa | Costo típico | Cómo se evita |
|---|---|---|---|
| 1 | Forwarding rule de un load balancer olvidado | ~$18/mes | No usar LB en el tronco; `gcloud compute forwarding-rules list` al cerrar |
| 2 | IP externa reservada y no adjunta | Tarifa por hora, más cara que en uso | `gcloud compute addresses list` y mirar `status=RESERVED` |
| 3 | Persistent Disk huérfano tras borrar la VM | Por GiB-mes | Crear la VM con `--boot-disk-auto-delete`; verificar con `disks list` |
| 4 | Snapshots que nadie borra | Por GiB-mes, creciente | Política de retención, o borrarlos en el teardown |
| 5 | Cloud SQL detenida | Sigue cobrando almacenamiento | Borrar la instancia, no detenerla |
| 6 | Cluster de GKE vacío | $0.10/h más nodos | Borrar el cluster, no escalar a cero |
| 7 | `Ingress`/`Service` de GKE borrados **después** del cluster | Balanceo huérfano | Borrar los objetos de Kubernetes primero, esperar, y luego el cluster |
| 8 | `--min-instances` en Cloud Run | vCPU y memoria 24/7 | Dejarlo en 0 salvo mientras se demuestra |
| 9 | Imágenes acumuladas en Artifact Registry | Centavos, crecientes | Borrar tags viejos; política de limpieza |
| 10 | Recursos fuera de la región del Always Free | Sale de la cuota gratis sin avisar | Sostener `us-central1` como fija el baseline |

> 🏁 **La señal de que quedaste limpio.**
> `gcloud asset search-all-resources --scope=projects/inv-lab-472913` no devuelve un solo
> recurso facturable, los cinco comandos del barrido dirigido de §7 salen vacíos, y el informe
> de facturación confirma $0.00 a las 48 horas — que es lo que tarda en consolidarse.

---

## 🧠 Preguntas rápidas

1. ¿En qué se diferencian el crédito de bienvenida, el Always Free y el crédito del Free Tier de GKE?
2. Nombra cuatro recursos que cobren por existir aunque nadie los use.
3. ¿Por qué una IP externa estática reservada y no adjunta cuesta más que una en uso?
4. ¿Cuál es el único cargo real que genera el tronco de la serie y por qué aparece por acumulación?
5. Borras una VM. ¿Qué puede quedar vivo y cobrando?
6. Borras un cluster de GKE sin tocar sus objetos de Kubernetes. ¿Qué dos categorías de recursos sobreviven?
7. ¿Por qué un barrido por `labels.project=inv_lab` no demuestra que el proyecto quedó limpio?
8. ¿Para qué sí sirven los labels entonces?
9. ¿Qué te dice la columna `status` de `gcloud compute addresses list` y cuál de sus valores te preocupa?
10. ¿Un presupuesto de Cloud Billing detiene el gasto? Si no, ¿qué hay que montar para que ocurra algo automáticamente?
11. ¿Dónde vive un presupuesto y por qué sobrevive al borrado del proyecto?
12. ¿Qué tres cosas hay que saber antes de usar el borrado de proyecto como mecanismo de teardown?
13. ¿Por qué `terraform destroy` puede terminar con éxito y dejar recursos facturando?
14. ¿Qué hace `--min-instances` en Cloud Run y por qué es peligroso en un lab?
15. ¿Por qué el baseline del curso fija `us-central1` y no una región más cercana?

---

## 📚 Referencias oficiales

- Programa gratuito de Google Cloud (crédito y Free Tier): https://cloud.google.com/free
- Cuotas del Free Tier por producto: https://cloud.google.com/free/docs/free-cloud-features
- Calculadora de precios: https://cloud.google.com/products/calculator
- Precios de red de VPC, incluidas las IP externas: https://cloud.google.com/vpc/network-pricing
- Reservar una IP externa estática: https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address
- Precios de Cloud Load Balancing: https://cloud.google.com/load-balancing/pricing
- Precios de discos y almacenamiento de Compute Engine: https://cloud.google.com/compute/disks-image-pricing
- Precios de Cloud SQL: https://cloud.google.com/sql/pricing
- Precios de Google Kubernetes Engine: https://cloud.google.com/kubernetes-engine/pricing
- Precios de Cloud NAT: https://cloud.google.com/nat/pricing
- Precios de Cloud Run: https://cloud.google.com/run/pricing
- Precios de Pub/Sub: https://cloud.google.com/pubsub/pricing
- Precios de Firestore: https://cloud.google.com/firestore/pricing
- Precios de Cloud Storage: https://cloud.google.com/storage/pricing
- Precios de Artifact Registry: https://cloud.google.com/artifact-registry/pricing
- Crear, editar o eliminar presupuestos y alertas: https://cloud.google.com/billing/docs/how-to/budgets
- Notificaciones programáticas de presupuesto: https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications
- Deshabilitar la facturación con notificaciones: https://cloud.google.com/billing/docs/how-to/disable-billing-with-notifications
- Informes de facturación de Cloud: https://cloud.google.com/billing/docs/how-to/reports
- Export de datos de facturación a BigQuery: https://cloud.google.com/billing/docs/how-to/export-data-bigquery
- Cloud Asset Inventory: https://cloud.google.com/asset-inventory/docs
- Buscar recursos con Cloud Asset Inventory: https://cloud.google.com/asset-inventory/docs/searching-resources
- `gcloud asset search-all-resources`: https://cloud.google.com/sdk/gcloud/reference/asset/search-all-resources
- Catálogo de recommenders de Active Assist: https://cloud.google.com/recommender/docs/recommenders
- Recomendaciones de recursos ociosos (discos e IP): https://cloud.google.com/compute/docs/viewing-and-applying-idle-resources-recommendations
- Eliminar y restaurar proyectos: https://cloud.google.com/resource-manager/docs/creating-managing-projects
- Proteger proyectos con liens: https://cloud.google.com/resource-manager/docs/project-liens
- Borrar un cluster de GKE (qué retiene GKE): https://cloud.google.com/kubernetes-engine/docs/how-to/deleting-a-cluster
- PersistentVolume en GKE y políticas de recuperación: https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes
