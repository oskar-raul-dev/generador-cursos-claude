# L04 — Red: VPC, firewall y diagnóstico

> **Objetivo:** montar la red del laboratorio con Terraform y aprender a diagnosticarla sin
> enviar un solo paquete: alcance de la VPC, orden de evaluación de las firewall rules, Private
> Google Access en lugar de Cloud NAT, Flow Logs y Connectivity Tests.
> **Se asume leído:** [`L03`](l03-terraform-desde-la-cli.md). Rinde mucho más con
> [`01`](01-infraestructura-global-y-redes.md) leído.
> **Costo:** **$0.00**. Una VPC, sus subnets, sus firewall rules y un Connectivity Test no cobran
> nada por existir, y este lab **no levanta ninguna VM, ningún Cloud NAT y ningún load balancer**.
> **Duración:** 2–3 horas.
> **Prerrequisitos:** [`L03`](l03-terraform-desde-la-cli.md) completo, con el backend de Terraform funcionando y la API
> `compute.googleapis.com` habilitada desde [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md).
> **Qué queda encendido al terminar:** la VPC `inv-lab-vpc`, la subnet `inv-lab-subnet` y sus
> firewall rules. Cero cargas de trabajo, cero direcciones IP reservadas.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Por qué la red es un lab y no un drill](#1--por-qué-la-red-es-un-lab-y-no-un-drill) ·
[VPC global, subnet regional](#2--vpc-global-subnet-regional) ·
[La red del lab en HCL](#3--la-red-del-lab-en-hcl) ·
[Reglas implícitas](#4--las-reglas-que-ya-están-y-nadie-escribió) ·
[Prioridad y targets](#5--prioridad-targets-y-el-orden-de-evaluación) ·
[Firewall efectivo](#6--qué-reglas-se-aplican-de-verdad) ·
[Private Google Access](#7--private-google-access-en-lugar-de-cloud-nat) ·
[Flow Logs](#8--flow-logs-lo-que-registran-y-lo-que-cuestan) ·
[Connectivity Tests](#9--diagnóstico-sin-paquetes-connectivity-tests) ·
[Lo que el lab no monta](#10--lo-que-el-lab-no-monta-y-por-qué) ·
[Teardown](#11--teardown-de-este-lab) ·
[Checklist](#-checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 Por qué la red es un lab y no un drill

La doctrina de esta serie dice que en la nube se practica lo que **solo** existe en la nube, y que
lo demás se practica en local. Con la red hay una tentación evidente: montar contenedores con
`docker network` y decir que ya está.

No está, y la razón es doble.

**La primera: en GCP la red es gratis.** Una VPC, sus subnets, sus firewall rules, Private Google
Access y los Connectivity Tests no cuestan **nada** mientras no levantes una VM que se salga de la
cuota gratuita ni reserves una IP. En otras nubes, practicar red implica pagar por un NAT gateway
desde el minuto uno; aquí no. Un tema que se pregunta en toda entrevista de arquitectura y que
además es gratis practicar no tiene por qué quedarse en el capítulo teórico.

**La segunda: el modelo de GCP no se parece al de un `docker network`, ni al de otras nubes.** La
VPC es de alcance global, la subnet es regional, las reglas de firewall no se adjuntan a
instancias sino que se seleccionan por tags o por service account, y hay reglas implícitas que
nadie escribió y que deciden el comportamiento por defecto. Nada de eso lo enseña un contenedor.

> 🧠 **Modelo mental.** Lo que este lab entrena no es "crear una VPC" —eso son tres comandos—:
> es **poder responder por qué una conexión no ocurre**, con un dato en la mano y sin haber
> enviado un paquete. Ese es el ejercicio, y por eso §9 es el destino del documento.

---

## 2. 🧱 VPC global, subnet regional

La primera propiedad de GCP que hay que interiorizar, porque contradice la intuición de casi
todo el mundo:

```text
VPC        = GLOBAL     una sola red puede tener subnets en todas las regiones
Subnet     = REGIONAL   abarca todas las zonas de UNA región
Instancia  = ZONAL      vive en una zona concreta
```

Consecuencia práctica: **dos recursos en `us-central1` y en `europe-west1` pueden estar en la
misma VPC y hablarse por IP privada sin peering, sin túnel y sin nada**. La VPC no es un objeto
regional que haya que replicar; el enrutamiento entre subnets de la misma VPC es automático.

La segunda decisión es el modo de la red:

| Modo | Qué hace | Cuándo |
|---|---|---|
| Auto-mode | Crea una subnet por región automáticamente, con rangos predefinidos | Casi nunca. Los rangos predefinidos complican evitar solapamientos |
| Custom-mode | Tú creas cada subnet con el rango que decides | El caso normal, y el de este lab |

> 📝 **Contexto.** Cada proyecto nuevo trae una VPC llamada `default` en auto-mode, con subnets en
> todas las regiones y unas cuantas firewall rules permisivas ya creadas —entre ellas una que
> permite SSH desde `0.0.0.0/0`—. Es cómoda para empezar y es exactamente lo que no quieres en
> nada que se parezca a producción. Este lab crea su propia VPC en custom-mode y no toca la
> `default`.

---

## 3. 🧱 La red del lab en HCL

**Teardown antes de crear:** todo lo de esta sección lo administra Terraform y se destruye con
`terraform destroy`. Ninguno de estos recursos cobra, y ninguno deja huérfanos… **con una
excepción que conviene saber ya: si algún día pones un load balancer sobre esta VPC, sus reglas
de firewall de health check y sus forwarding rules las crea el controlador y no las administra
Terraform.** Ese es el caso que persigue [`L08`](l08-costos-y-destruccion-verificada.md).

```hcl
# network.tf — la red del laboratorio

resource "google_compute_network" "vpc" {
  name                    = "inv-lab-vpc"
  auto_create_subnetworks = false   # custom-mode: ninguna subnet aparece sola
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "inv-lab-subnet"
  network       = google_compute_network.vpc.id
  region        = "us-central1"
  ip_cidr_range = "10.10.0.0/24"

  # salir a las APIs de Google sin IP externa y sin Cloud NAT
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"   # menos muestras, menos volumen de logs
    flow_sampling        = 0.5                 # la mitad de los flujos, no todos
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
```

Campo por campo, porque cada uno es una decisión:

- **`auto_create_subnetworks = false`** es lo que convierte la red en custom-mode. Si lo dejas en
  `true`, GCP crea una subnet en **cada región**, con rangos que tú no elegiste, y descubrirlo
  después es incómodo.
- **`routing_mode`**: `REGIONAL` significa que un Cloud Router solo anuncia las rutas de su propia
  región; `GLOBAL` las anuncia todas. Solo importa cuando hay conectividad híbrida —VPN o
  Interconnect—, que este lab no tiene. Se deja explícito para que la decisión no sea invisible.
- **`ip_cidr_range = "10.10.0.0/24"`** son 256 direcciones, de las cuales GCP reserva cuatro en
  cada subnet (la primera, la penúltima, la última y la del gateway). Elegir un `/24` en un rango
  privado poco común evita solapamientos el día que esta VPC tenga que hablar con otra.
- **`private_ip_google_access = true`** es el protagonista de §7.
- **`log_config`** activa los Flow Logs, con su letra pequeña en §8.

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

---

## 4. 🧱 Las reglas que ya están y nadie escribió

Antes de crear una sola regla, hay que saber qué hay. Toda VPC de GCP tiene dos **reglas
implícitas** que no aparecen en ninguna lista y que no se pueden borrar:

```text
implícita  EGRESS   allow  a 0.0.0.0/0    prioridad 65535   ← todo lo que sale, sale
implícita  INGRESS  deny   de 0.0.0.0/0   prioridad 65535   ← nada de lo que entra, entra
```

De ahí salen las dos frases que hay que poder decir:

> 🧠 **Modelo mental.** En una VPC de GCP, **el ingress está denegado por defecto y el egress
> permitido por defecto**. Por eso una VM recién creada puede salir a Internet (si tiene por dónde)
> y nadie puede entrar a ella hasta que escribas una regla que lo permita.

Compruébalo:

```bash
gcloud compute firewall-rules list --filter='network:inv-lab-vpc'
```

```text
Listed 0 items.
```

Cero reglas, y sin embargo el comportamiento ya está definido. Las implícitas no se listan porque
no son objetos: son el fondo sobre el que se evalúan las tuyas.

> ⚠️ **La confusión típica de entrevista**, y conviene nombrarla: *"una firewall rule de GCP es
> como un security group adjunto a la instancia"*. **No lo es.** Una firewall rule vive **en la
> VPC**, no en la instancia, y selecciona a qué cargas de trabajo aplica mediante **target tags**
> o **target service accounts**. La misma regla puede aplicar a cien instancias o a ninguna, y
> añadir un tag a una instancia cambia qué reglas la afectan sin tocar la regla.

---

## 5. 🧱 Prioridad, targets y el orden de evaluación

Ahora las reglas del lab, y una que existe solo para enseñar el orden.

```hcl
# firewall.tf

# 1. tráfico interno entre cargas de trabajo etiquetadas como del lab
resource "google_compute_firewall" "allow_internal" {
  name      = "inv-lab-allow-internal"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["10.10.0.0/24"]
  target_tags   = ["inv-lab"]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}

# 2. una regla DENY con prioridad MÁS ALTA (número más bajo): gana sobre la anterior
resource "google_compute_firewall" "deny_internal_debug" {
  name      = "inv-lab-deny-internal-debug"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  priority  = 900

  source_ranges = ["10.10.0.0/24"]
  target_tags   = ["inv-lab-quarantine"]

  deny {
    protocol = "tcp"
    ports    = ["8080"]
  }
}
```

- **`priority`**: **el número más bajo gana**. Es lo contrario de lo que mucha gente asume, y es
  una pregunta de entrevista frecuente. El rango va de 0 a 65535 y el default es 1000 — el mismo
  que las implícitas usan como 65535, es decir, siempre el último recurso.
- **`direction`**: `INGRESS` (default) o `EGRESS`. Una regla de egress usa `destination_ranges`
  en lugar de `source_ranges`; mezclarlos es un error de validación inmediato.
- **`source_ranges`** es de dónde viene el tráfico. Para ingress puede ser también
  `source_tags` o `source_service_accounts`.
- **`target_tags`** es a qué cargas de trabajo aplica la regla. Sin `target_tags` ni
  `target_service_accounts`, **la regla aplica a toda la VPC**, que casi nunca es lo que quieres.
- **`allow` / `deny`** son bloques distintos, y una regla es de un tipo o del otro. GCP **sí
  admite reglas DENY explícitas**, a diferencia de lo que ocurre en IAM con las allow policies:
  son dos sistemas distintos y confundirlos es otro clásico.

El orden de evaluación completo, para tenerlo en una imagen:

```text
1. Hierarchical firewall policies   (Organization / Folder)  ← si las hay, mandan primero
2. Reglas de la VPC                  por prioridad ascendente
3. Reglas implícitas                 prioridad 65535
```

> 📝 **Contexto.** Las **hierarchical firewall policies** se definen en la organización o en una
> carpeta y se aplican a todos los proyectos debajo, antes que cualquier regla de VPC. Son la
> respuesta correcta a "cómo garantizo que nadie abra el 22 al mundo en ningún proyecto". Si tu
> cuenta no tiene organización, no puedes practicarlas; el vocabulario sí entra en entrevista.

```bash
terraform apply
gcloud compute firewall-rules list \
  --filter='network:inv-lab-vpc' \
  --format='table(name, priority, direction, sourceRanges.list(), targetTags.list(), allowed[].map().firewall_rule().list():label=ALLOW, denied[].map().firewall_rule().list():label=DENY)'
```

```text
NAME                        PRIORITY  DIRECTION  SOURCE_RANGES  TARGET_TAGS          ALLOW     DENY
inv-lab-deny-internal-debug  900      INGRESS    10.10.0.0/24   inv-lab-quarantine             tcp:8080
inv-lab-allow-internal      1000      INGRESS    10.10.0.0/24   inv-lab                tcp:8080
```

Ese `--format` es largo a propósito y merece la explicación, porque es el patrón para consultar
cualquier campo que sea una lista de objetos:
`allowed[]` toma la lista de protocolos permitidos, `.map()` aplica lo siguiente a cada elemento,
`.firewall_rule()` formatea cada uno como `tcp:8080`, `.list()` los junta en una cadena y `:label=`
renombra la columna. Si te parece demasiado, la salida honesta es `--format=json` y `jq`: no hay
premio por hacerlo todo en una línea 😉.

---

## 6. 🩺 Qué reglas se aplican de verdad

Listar las reglas de la VPC responde a "qué reglas existen". La pregunta útil cuando algo no
conecta es otra: **"¿qué reglas se aplican a *esta* carga de trabajo?"**, y tiene comando propio:

```bash
gcloud compute network-firewall-policies get-effective-firewalls \
  --network=inv-lab-vpc \
  --global
```

Devuelve el conjunto efectivo **ya combinado**: las políticas jerárquicas que vengan de arriba,
las policies de red y las reglas de la VPC, en el orden en que se evalúan. Es la diferencia entre
leer tres listas y confiar en tu aritmética mental, y leer el resultado.

> 🩺 **Diagnóstico.** Cuando una conexión no ocurre, el orden de sospecha es siempre el mismo, de
> lo más barato a lo más caro de comprobar:
>
> ```text
> 1. ¿Hay una regla que lo permita?     el ingress deniega por defecto
> 2. ¿Se aplica a esta carga?           los target tags deciden, no la instancia
> 3. ¿Qué prioridad gana?               número más bajo, y las implícitas son 65535
> 4. ¿Hay ruta hacia el destino?        longest prefix match
> 5. ¿El destino escucha de verdad?     eso ya no es problema de red
> ```

Y las rutas, que son la otra mitad de la respuesta:

```bash
gcloud compute routes list --filter='network:inv-lab-vpc' \
  --format='table(name, destRange, nextHopGateway, priority)'
```

```text
NAME                             DEST_RANGE    NEXT_HOP_GATEWAY                   PRIORITY
default-route-…                  0.0.0.0/0     …/global/gateways/default-internet-gateway  1000
default-route-…                  10.10.0.0/24                                     0
```

Dos rutas que tú no creaste: la de la subnet —tráfico local, prioridad 0— y la de salida a
Internet. Entre varias rutas que coincidan con un destino gana **la más específica**, que es lo que
significa *longest prefix match*: una ruta a `10.10.0.0/24` gana sobre una a `0.0.0.0/0` para
cualquier destino dentro de ese rango, con independencia de la prioridad.

---

## 7. 🧱 Private Google Access, en lugar de Cloud NAT

Aquí está la decisión de arquitectura más rentable de todo el lab, y conviene plantear el problema
antes que la solución.

**El problema.** Tienes una carga de trabajo en una subnet privada, sin IP externa —porque no
quieres exponerla—, y necesita hablar con las APIs de Google: escribir en Cloud Storage, leer un
secreto, publicar en Pub/Sub. Esas APIs viven en direcciones **públicas** (`*.googleapis.com`).
Sin IP externa, no hay camino.

**La respuesta refleja** es Cloud NAT: un gateway administrado que da salida a Internet a lo que no
tiene IP pública. Funciona, y cobra por hora de gateway **y** por GiB procesado.

**La respuesta correcta para este caso** es otra:

> 🧠 **Modelo mental.** **Private Google Access** permite que una instancia **sin IP externa**
> alcance las APIs y servicios de Google usando su IP interna. Se activa **por subnet**, no cuesta
> nada, y el tráfico no sale a Internet. Cloud NAT solo hace falta cuando el destino es Internet
> de verdad —descargar un paquete de PyPI, llamar a una API de terceros—, no cuando el destino es
> Google.

```bash
gcloud compute networks subnets describe inv-lab-subnet \
  --region us-central1 \
  --format='value(privateIpGoogleAccess)'
```

```text
True
```

Ese `True` viene del `private_ip_google_access = true` del HCL de §3. Si algún día una carga de
trabajo tuya no alcanza las APIs de Google desde una subnet privada, **este es el primer comando**,
antes de pensar en NAT, en rutas o en IAM.

> 💰 **Costo.** Cloud NAT cobra por hora de gateway y por GiB procesado; Private Google Access no
> tiene cargo adicional. Es el mismo tipo de decisión que en [`L00`](l00-idea-lab-practico.md)
> saca al Application Load Balancer del tronco: el camino barato no es un atajo pedagógico, es el
> diseño correcto para este requisito. Verifica las tarifas vigentes en la
> [calculadora](https://cloud.google.com/products/calculator) antes de encender un NAT en
> cualquier otro contexto.

Hay una tercera opción del mismo vecindario que conviene distinguir, porque cae en entrevista:
**Private Service Connect** publica un servicio concreto —de Google o de un tercero— detrás de un
**endpoint con IP interna dentro de tu VPC**. Private Google Access te lleva a las APIs públicas
por dentro; Private Service Connect te trae el servicio a una IP tuya. No son sustitutos.

---

## 8. 🧱 Flow Logs: lo que registran y lo que cuestan

Los activaste en §3 con `log_config`. Qué hacen exactamente:

- Muestrean las conexiones que atraviesan la subnet y registran metadatos —IPs, puertos,
  protocolo, bytes, paquetes, latencia—, **no el contenido**. No son un `tcpdump`.
- Se activan **por subnet**, no por VM ni por VPC.
- Son la fuente que usa el análisis de red y la herramienta habitual para responder "¿quién habló
  con quién y cuánto" a posteriori.

Los tres parámetros que decides tú, y los tres son de volumen:

- **`flow_sampling = 0.5`** registra la mitad de los flujos. Es una fracción entre 0 y 1, y es el
  dial que más mueve el costo.
- **`aggregation_interval = "INTERVAL_10_MIN"`** agrega las muestras en ventanas de diez minutos
  en vez de cinco segundos. Menos entradas, menos detalle temporal.
- **`metadata = "INCLUDE_ALL_METADATA"`** añade los campos anotados (nombre de la instancia, de la
  VPC, geografía). Más útil y más pesado.

> 💰 **Costo.** Los Flow Logs generan volumen, y ese volumen se paga: si van a Cloud Logging,
> consumen la cuota de ingesta —los primeros 50 GiB por proyecto son gratis— y la página de precios
> de red de VPC detalla los cargos de generación. En este lab **no hay ninguna VM ni ningún tráfico
> dentro de la subnet**, así que el volumen real es cero; el `flow_sampling = 0.5` está ahí para que
> el dial esté escrito y no para ahorrar hoy. En una red con tráfico de verdad, dejar el muestreo
> al 1.0 "por si acaso" es una de las formas más comunes de inflar la factura de logs.

---

## 9. 🩺 Diagnóstico sin paquetes: Connectivity Tests

El destino del lab. La herramienta que casi nadie menciona en una entrevista y que responde a
"cómo depurarías esta conexión" mejor que cualquier `ping`.

> 🧠 **Modelo mental.** Un **Connectivity Test hace análisis de configuración, no envía tráfico.**
> Recorre tu VPC, tus reglas y tus rutas reales y simula el camino, diciendo **en qué salto se cae
> y por qué regla**. Funciona con la máquina apagada, con la máquina inexistente, y de madrugada.

**Prueba 1 — el camino a las APIs de Google desde la subnet privada.**

```bash
gcloud network-management connectivity-tests create pga-a-googleapis \
  --source-ip-address=10.10.0.5 \
  --source-network=projects/inv-lab-472913/global/networks/inv-lab-vpc \
  --destination-ip-address=199.36.153.8 \
  --destination-port=443 \
  --protocol=TCP
```

- `--source-ip-address` es una IP **dentro de tu subnet**. No hace falta que exista nada en ella:
  el análisis es sobre la configuración de red, no sobre un host.
- `--source-network` desambigua a qué VPC pertenece esa IP, en formato de nombre completo.
- `--destination-ip-address=199.36.153.8` es una dirección del rango `private.googleapis.com`, que
  es el destino por el que sale el tráfico a las APIs cuando hay Private Google Access.
- `--destination-port=443` y `--protocol=TCP` completan la 5-tupla que el análisis necesita.

```bash
gcloud network-management connectivity-tests describe pga-a-googleapis \
  --format='value(reachabilityDetails.result, reachabilityDetails.verifyTime)'
```

```text
REACHABLE  2026-09-06T18:41:02Z
```

El resultado es `REACHABLE`, `UNREACHABLE`, `AMBIGUOUS` o `UNDETERMINED`, y el detalle completo
—en `--format=json`— trae **la traza salto a salto**, incluida la regla concreta que dropeó el
tráfico cuando no llega.

**Prueba 2 — provocar un `UNREACHABLE` a propósito.** Un destino en el 8080 desde fuera del rango
permitido:

```bash
gcloud network-management connectivity-tests create bloqueado-por-firewall \
  --source-ip-address=192.168.99.9 \
  --destination-ip-address=10.10.0.5 \
  --destination-network=projects/inv-lab-472913/global/networks/inv-lab-vpc \
  --destination-port=8080 \
  --protocol=TCP

gcloud network-management connectivity-tests describe bloqueado-por-firewall --format=json
```

En la traza vas a ver el paso `FIREWALL_RULE` y el nombre de la regla responsable — o la mención
de la **regla implícita de deny ingress** cuando ninguna de las tuyas coincidió. Esa es la
diferencia entre "no funciona" y "no funciona porque el origen `192.168.99.9` no está en
`source_ranges` y cae en la deny implícita".

**Los tests son recursos, y se borran:**

```bash
gcloud network-management connectivity-tests delete pga-a-googleapis --quiet
gcloud network-management connectivity-tests delete bloqueado-por-firewall --quiet
```

No cobran nada, pero se acumulan y no los administra Terraform: son exactamente el tipo de recurso
creado a mano que `terraform destroy` no ve, del que hablaba
[`L03` §10](l03-terraform-desde-la-cli.md#10--lo-que-terraform-no-ve).

---

## 10. ⚖ Lo que el lab no monta, y por qué

Cuatro exclusiones, cada una con su razón y su destino. Una exclusión explicada es contenido; una
exclusión silenciosa es un hueco del temario.

**Cloud NAT.** Cobra por hora de gateway y por GiB procesado, y este laboratorio no lo necesita:
no hay VMs privadas que deban salir a Internet, y para llegar a las APIs de Google está Private
Google Access (§7), que no cuesta nada. → El concepto se explica en
[`01`](01-infraestructura-global-y-redes.md); aquí se practica su alternativa.

**Máquinas virtuales.** Una `e2-micro` en una región de EE. UU. entra en el Always Free, así que el
problema no es el precio: es que el ciclo de vida de una VM no enseña nube, y que un disco olvidado
sí cuesta. Todo este lab se hace **sin una sola VM**, y el diagnóstico de §9 demuestra que se puede.
→ Drill opcional de [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales).

**Load balancers.** Un forwarding rule global cuesta del orden de $0.025/h —unos $18 al mes— y es
completamente evitable: Cloud Run publica una URL HTTPS con certificado administrado sin cobrar por
ella. Es la trampa de costo número uno de los proyectos de práctica. → Se explica en
[`06`](06-cloud-dns-conectividad.md) y se practica en el drill de [`L00`](l00-idea-lab-practico.md) §9.

**Serverless VPC Access connector.** Es lo que conectaría los servicios de Cloud Run de [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) con
esta VPC. No se monta, y aquí la razón es puramente económica y hay que decirla:

> 💰 **Costo.** Un conector de Serverless VPC Access **factura por instancia y por hora mientras
> exista**, aunque no pase tráfico: es de la familia de recursos de
> [`A02` §3](a02-costos-trampas-y-recursos-huerfanos.md#3--el-catálogo-de-lo-que-cobra-por-existir),
> los que cobran por existir. El laboratorio no lo necesita porque `inv-api` e `inv-projector` solo
> hablan con APIs de Google —Firestore, Pub/Sub, Secret Manager—, y a esas se llega por la red
> pública de Google con la identidad del servicio, sin pasar por tu VPC. Un
> conector solo hace falta cuando el destino tiene **IP privada dentro de tu red**: una Cloud SQL
> con IP privada, un Memorystore, un servicio interno. Verifica la tarifa vigente en la
> [calculadora](https://cloud.google.com/products/calculator) antes de encender uno.

> ⚠️ **Y la consecuencia que hay que aceptar sin disimulo:** esta VPC va a quedarse vacía. El
> sistema de `L05`–`L06` **no la usa**. Está aquí porque la red es materia de entrevista, porque
> en GCP practicarla es gratis y porque el diagnóstico de §9 es una habilidad real — no porque el
> inventario la necesite. Fingir lo contrario sería montar un conector que cobra para justificar
> un lab.

---

## 11. 🧹 Teardown de este lab

| Recurso | ¿Cobra? | Qué hacer |
|---|---|---|
| VPC `inv-lab-vpc` y subnet `inv-lab-subnet` | No | Se quedan hasta [`L08`](l08-costos-y-destruccion-verificada.md); se van con `terraform destroy` |
| Firewall rules del lab | No | Igual: las administra Terraform |
| Flow Logs | Solo por volumen | Sin tráfico, cero. Se desactivan quitando `log_config` |
| Connectivity Tests | No | **Borrados ya** en §9. No los administra Terraform |
| VPC `default` del proyecto | No | No se toca. Se va con el proyecto en [`L08`](l08-costos-y-destruccion-verificada.md) |

Verificación, y aquí conviene mirar más allá de lo que crees haber creado:

```bash
# lo que administra Terraform
terraform state list

# lo que existe de verdad en el proyecto
gcloud asset search-all-resources \
  --scope=projects/inv-lab-472913 \
  --filter='assetType:compute.googleapis.com' \
  --format='table(assetType, name, location)'

# y los sospechosos habituales, que no llevan tus labels
gcloud compute addresses list        --format='table(name, region, status)'
gcloud compute forwarding-rules list --format='table(name, region, IPAddress)'
gcloud compute disks list            --format='table(name, zone, users.list())'
```

Los tres últimos comandos tienen que salir vacíos. Son los tipos de recurso que producen el 90 %
de las facturas sorpresa, y ninguno de ellos lleva labels: por eso se consultan uno a uno y no con
un filtro por `project=inv_lab`.

---

## 📋 Checklist de salida

- [ ] La VPC es custom-mode: `gcloud compute networks describe inv-lab-vpc --format='value(autoCreateSubnetworks)'` devuelve `False`.
- [ ] La subnet tiene `privateIpGoogleAccess: True`.
- [ ] Comprobaste que una VPC nueva tiene **cero** firewall rules listadas y aun así deniega el ingress.
- [ ] Puedes decir, sin mirar, qué prioridad gana entre 900 y 1000.
- [ ] Ejecutaste `get-effective-firewalls` y sabes en qué se diferencia de `firewall-rules list`.
- [ ] Un Connectivity Test devolvió `REACHABLE` hacia las APIs de Google.
- [ ] Otro devolvió `UNREACHABLE` y **leíste en la traza qué regla lo bloqueó**.
- [ ] Los dos Connectivity Tests están borrados.
- [ ] `gcloud compute addresses list`, `forwarding-rules list` y `disks list` salen vacíos.
- [ ] Puedes explicar por qué el lab no monta Cloud NAT ni un conector de Serverless VPC Access.

## 🏁 La señal de que quedó bien

La VPC existe con sus dos firewall rules y su Private Google Access activado, no hay una sola IP
reservada, forwarding rule ni disco en el proyecto, y puedes explicarle a alguien por qué una
conexión falla señalando la regla concreta en la traza de un test — sin haber enviado un paquete y
sin haber encendido una máquina.

---

## 🧠 Preguntas rápidas

1. ¿Qué alcance tienen una VPC, una subnet y una instancia en GCP?
2. Dos servicios en regiones distintas dentro de la misma VPC, ¿necesitan peering para hablarse por IP privada?
3. ¿Qué diferencia a una VPC auto-mode de una custom-mode, y por qué el lab usa la segunda?
4. ¿Cuáles son las dos reglas implícitas de toda VPC y qué comportamiento por defecto producen?
5. ¿Por qué una firewall rule de GCP no es un security group adjunto a una instancia?
6. Entre una regla de prioridad 900 y una de 1000, ¿cuál gana?
7. ¿Qué pasa si escribes una firewall rule sin `target_tags` ni `target_service_accounts`?
8. ¿En qué orden se evalúan las hierarchical firewall policies, las reglas de VPC y las implícitas?
9. ¿Qué te da `get-effective-firewalls` que no te dé `firewall-rules list`?
10. ¿Qué significa *longest prefix match* y cómo se relaciona con la prioridad de una ruta?
11. ¿Qué problema resuelve Private Google Access y por qué evita tener que montar Cloud NAT?
12. ¿Cuándo sí hace falta Cloud NAT, entonces?
13. ¿En qué se diferencian Private Google Access y Private Service Connect?
14. ¿Qué registran los Flow Logs y qué **no** registran? ¿Qué tres parámetros mueven su volumen?
15. ¿Por qué un Connectivity Test funciona con la máquina apagada, y qué te dice que un `ping` no puede darte?
16. ¿Por qué el laboratorio no monta un conector de Serverless VPC Access, y cuándo haría falta uno de verdad?

---

## 📚 Referencias oficiales

- Descripción general de VPC: https://cloud.google.com/vpc/docs/vpc
- Subredes: https://cloud.google.com/vpc/docs/subnets
- Reglas de firewall de VPC: https://cloud.google.com/firewall/docs/firewalls
- Componentes y prioridad de las reglas de firewall: https://cloud.google.com/firewall/docs/firewall-policies-rule-details
- Políticas de firewall jerárquicas: https://cloud.google.com/firewall/docs/firewall-policies
- Obtener las reglas de firewall efectivas: https://cloud.google.com/firewall/docs/getting-effective-firewalls
- Rutas en VPC: https://cloud.google.com/vpc/docs/routes
- Private Google Access: https://cloud.google.com/vpc/docs/private-google-access
- Configurar Private Google Access: https://cloud.google.com/vpc/docs/configure-private-google-access
- Private Service Connect: https://cloud.google.com/vpc/docs/private-service-connect
- Cloud NAT: https://cloud.google.com/nat/docs/overview
- Precios de Cloud NAT: https://cloud.google.com/nat/pricing
- Registros de flujo de VPC: https://cloud.google.com/vpc/docs/flow-logs
- Usar los registros de flujo de VPC: https://cloud.google.com/vpc/docs/using-flow-logs
- Precios de red de VPC: https://cloud.google.com/vpc/network-pricing
- Connectivity Tests: https://cloud.google.com/network-intelligence-center/docs/connectivity-tests/how-to/running-connectivity-tests
- Estados de un Connectivity Test: https://cloud.google.com/network-intelligence-center/docs/connectivity-tests/concepts/overview
- Acceso a VPC sin servidores (Serverless VPC Access): https://cloud.google.com/vpc/docs/serverless-vpc-access
- Precios de Cloud Load Balancing: https://cloud.google.com/load-balancing/pricing
- `google_compute_network`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
- `google_compute_subnetwork`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
- `google_compute_firewall`: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
