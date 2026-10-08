# 02 — Redes: VNet, NSG y enrutamiento

> **Objetivo:** diseñar y diagnosticar la red privada de una aplicación en Azure: VNet, subnets,
> NSG, rutas, salida a Internet y conexión entre redes.
> **Se asume leído:** [`01` — infraestructura global y Resource Manager](01-infraestructura-global-y-resource-manager.md),
> sobre todo regions y zonas.
> **Se toca más con:** [`01`](01-infraestructura-global-y-resource-manager.md), que define dónde vive
> la red, y [`03` — conectividad privada y DNS](03-conectividad-privada-y-dns.md), que usa esta red
> para llegar a los servicios de Azure sin pasar por Internet.
> **Se practica en:** [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) (VNet, NSG, effective routes e IP flow verify con una VM de diagnóstico).
> Ver [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [VNet](#2--la-vnet-es-regional) · [Subnets](#3--subnets-y-direccionamiento) ·
[NSG](#4--nsg-el-filtro-stateful) · [ASG y service tags](#5--application-security-groups-y-service-tags) ·
[Rutas](#6--rutas-del-sistema-y-udr) · [Salida a Internet](#7--salida-a-internet) ·
[IP públicas](#8--ip-públicas) · [Peering](#9--vnet-peering) ·
[Hub-and-spoke](#10--hub-and-spoke-y-azure-firewall) · [Diagnóstico](#11--diagnóstico-de-conectividad) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El problema

Tu API corre en una VM (o en una plataforma que se inyecta en tu red) y tiene que hablar con una
base de datos, recibir tráfico solo del balanceador y salir a Internet para llamar a un proveedor de
pagos. Cada una de esas tres frases es una decisión de red distinta en Azure:

- **con quién puede hablar** una máquina lo decide un **NSG**;
- **por dónde sale** un paquete lo decide la **tabla de rutas** de su subnet;
- **con qué IP pública sale** a Internet lo decide el **método de salida** explícito que
  configures, y esto cambió hace poco.

El capítulo recorre esas tres piezas sobre la unidad básica, la VNet, y cierra con la secuencia de
diagnóstico que usa [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md).

---

## 2. 🧱 La VNet es regional

Una **Virtual Network** (VNet) es tu red privada en Azure: un espacio de direcciones IP propio,
aislado de las VNets de otros clientes y de las tuyas propias, sobre el que creas subnets. Es una
red de capa 3: no hay broadcast, ni multicast, ni VLANs.

La propiedad que más confunde a quien llega con la intuición de otro modelo es el alcance:

> Regla importante: una VNet vive en una sola región, pero abarca todas las Availability Zones de
> esa región.

Consecuencias directas:

- dos aplicaciones en `eastus2` y `centralus` **nunca** están en la misma VNet: para que se hablen
  por IP privada hace falta **peering global** (§9) u otro mecanismo de conexión;
- una subnet, que vive dentro de la VNet, también es regional: **no hay subnets "por zona"**; las
  VMs de las tres zonas pueden compartir subnet;
- crear una VNet no cuesta nada. Lo que cuesta es lo que pongas dentro o lo que la conecte.

```bash
az network vnet create \
  --name inv-lab-vnet \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --address-prefixes 10.20.0.0/16
```

- `--address-prefixes` define el **address space** de la VNet: uno o varios bloques CIDR, que luego
  repartes en subnets. Si lo omites, la CLI usa `10.0.0.0/16`, que es exactamente el rango que
  eligen todos por defecto y el que va a solaparse cuando quieras conectar esta red con otra.
- `--location` es la región de la VNet y, por tanto, de todas sus subnets. No se puede cambiar
  después.

> ⚠️ **Planifica el direccionamiento antes de crear la primera VNet.** Dos VNets con espacios de
> direcciones solapados no se pueden conectar por peering, y renumerar una red con cargas vivas es
> una migración. El curso usa `10.20.0.0/16` para el laboratorio precisamente para no pisar el
> `10.0.0.0/16` por defecto.

---

## 3. 🧱 Subnets y direccionamiento

Una subnet es un rango dentro del address space de la VNet donde se colocan las NICs de las VMs, los
private endpoints ([`03`](03-conectividad-privada-y-dns.md)) y los servicios que se inyectan en tu red. Tres cosas que se
preguntan:

- **Azure reserva cinco direcciones de cada subnet**: las cuatro primeras y la última. En
  `10.20.1.0/24` son la dirección de red (`.0`), el gateway por defecto (`.1`), dos para mapear el DNS
  de Azure en la red (`.2` y `.3`) y el broadcast (`.255`). Una `/24` da 251 IPs útiles, no 254.
- **La subnet más pequeña es `/29`** (tres IPs útiles después de las cinco reservadas).
- **Algunos servicios exigen una subnet delegada** (dedicada a ese servicio) o de un tamaño mínimo;
  cada capítulo que introduce uno lo dice.

Y una propiedad nueva que cambia una respuesta clásica de entrevista:

> 📝 **Contexto.** Cada subnet tiene la propiedad `defaultOutboundAccess`. Si vale `false`, la subnet
> es **privada**: sus VMs no reciben la IP de salida implícita que Azure daba antes (§7). Desde el
> **31 de marzo de 2026**, las VNets nuevas creadas con versiones de API posteriores a esa fecha tienen
> subnets privadas por defecto, y el portal ya lo hacía antes. Las VNets existentes no cambian.

```bash
az network vnet subnet create \
  --name inv-lab-snet \
  --resource-group inv-lab-rg \
  --vnet-name inv-lab-vnet \
  --address-prefixes 10.20.1.0/24

az network vnet subnet update \
  --name inv-lab-snet \
  --resource-group inv-lab-rg \
  --vnet-name inv-lab-vnet \
  --default-outbound false
```

- `--vnet-name` indica la VNet padre: una subnet no existe fuera de su VNet, y su resource ID cuelga
  del de la VNet.
- `--address-prefixes` tiene que caer **dentro** del address space de la VNet y no solaparse con otra
  subnet; si no, la operación falla antes de crear nada.
- `--default-outbound false` marca la subnet como privada de forma explícita. Se escribe aunque la
  versión de API que use tu CLI ya lo haga por defecto, porque un Bicep o un Terraform que fija una
  versión de API antigua **deja la propiedad en `null`**, que implícitamente permite la salida por
  defecto. Lo explícito no depende de qué versión de API use cada herramienta.
- Si la subnet ya tiene VMs, el cambio no se aplica a ellas hasta que las detienes y desasignas.

---

## 4. 🧱 NSG: el filtro stateful

**El problema:** tu API debe aceptar HTTPS solo desde la subnet del balanceador y nada más.

Un **Network Security Group** (NSG) es una lista de reglas que permiten o deniegan tráfico por la
tupla de cinco elementos: origen, puerto de origen, destino, puerto de destino y protocolo. Se asocia
a una **subnet**, a una **NIC**, o a las dos. Las propiedades que hay que tener claras:

- **Prioridad de 100 a 4096**: se evalúan de menor a mayor número, y **la primera que coincide
  gana**; no se sigue evaluando. No puede haber dos reglas con la misma prioridad y dirección.
- **Admite `Allow` y `Deny`.**
- **Es stateful**: si permites una conexión saliente, la respuesta entra sin necesidad de una regla
  de entrada, y viceversa. Borrar una regla no corta las conexiones ya establecidas; solo afecta a
  las nuevas.
- **Tiene reglas por defecto que no se pueden borrar**, con prioridades 65000 a 65500, que solo puedes
  anular con una regla de número menor:

| Dirección | Regla por defecto | Prioridad | Efecto |
|---|---|---|---|
| Entrada | `AllowVNetInBound` | 65000 | Permite todo el tráfico entre direcciones de la VNet |
| Entrada | `AllowAzureLoadBalancerInBound` | 65001 | Permite los health probes del balanceador |
| Entrada | `DenyAllInbound` | 65500 | Deniega todo lo demás |
| Salida | `AllowVnetOutBound` | 65000 | Permite todo el tráfico hacia la VNet |
| Salida | `AllowInternetOutBound` | 65001 | **Permite toda la salida a Internet** |
| Salida | `DenyAllOutBound` | 65500 | Deniega todo lo demás |

La fila que más se olvida es `AllowInternetOutBound`: **un NSG recién creado deja salir a Internet
todo lo que tenga una ruta hacia fuera.** Si quieres controlar la salida, necesitas reglas propias de
salida con prioridad menor que 65001.

Cuando hay NSG en la subnet **y** en la NIC, el tráfico tiene que pasar los dos:

```text
Tráfico entrante:  Internet → NSG de la subnet → NSG de la NIC → VM
Tráfico saliente:  VM → NSG de la NIC → NSG de la subnet → destino
```

Si cualquiera de los dos lo deniega, se deniega. Es una de las causas más frecuentes de "el NSG
permite el puerto y aun así no conecta": estás mirando uno de los dos.

```bash
az network nsg rule create \
  --resource-group inv-lab-rg \
  --nsg-name inv-lab-nsg \
  --name AllowHttpsFromVnet \
  --priority 200 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --destination-port-ranges 443
```

- `--priority 200` deja espacio por debajo (100–199) para reglas más específicas que quieras
  anteponer después, como un `Deny` puntual. Numerar de 100 en 100 es una convención, no una regla de
  Azure.
- `--direction Inbound` y `--access Allow` fijan dirección y efecto. Sin `--direction`, la CLI usa
  `Inbound` por defecto, que es justo lo que confunde cuando querías una regla de salida.
- `--source-address-prefixes VirtualNetwork` usa un **service tag** (§5) en vez de un CIDR: significa
  el address space de la VNet y de las redes conectadas. Si pones `*`, abres el puerto a Internet
  entera.
- `--destination-port-ranges 443` es el puerto de destino. El puerto de origen, que no se indica,
  queda en `*`, que es lo correcto: el cliente usa un puerto efímero.

Un matiz de plataforma: el tráfico hacia `168.63.129.16` y `169.254.169.254` —el resolver DNS de
Azure, el servicio de metadatos y los health probes— **no está sujeto a tus NSG por defecto**. El
[`03`](03-conectividad-privada-y-dns.md) vuelve sobre `168.63.129.16`.

> ⚠️ **Un NSG no es un firewall centralizado.** Es un filtro distribuido por subnet o NIC que no
> inspecciona contenido ni entiende nombres de dominio. Filtrar salida por FQDN, inspeccionar TLS o
> centralizar la política de toda una organización es trabajo de Azure Firewall (§10), que es otro
> producto con otro precio.

---

## 5. 🧱 Application Security Groups y service tags

Escribir IPs en reglas de NSG envejece mal: las IPs cambian, los servicios de Azure tienen cientos de
rangos. Dos mecanismos lo evitan.

- **Service tags**: nombres administrados por Microsoft que representan grupos de prefijos IP de un
  servicio o un concepto: `VirtualNetwork`, `Internet`, `AzureLoadBalancer`, `Storage`,
  `Storage.EastUS2`, `AzureCloud`. Microsoft los actualiza cuando cambian los rangos. Se usan en NSG,
  en rutas y en Azure Firewall.
- **Application Security Groups** (ASG): etiquetas que tú asignas a NICs —`asg-api`, `asg-db`— y que
  usas como origen o destino en las reglas. La regla "permite 5432 desde `asg-api` hacia `asg-db`"
  sigue valiendo aunque escales de 2 a 20 VMs, sin tocar el NSG.

```text
Regla mental:
Service tag = grupo de IPs que administra Microsoft (un servicio de Azure, Internet, tu VNet)
ASG         = grupo de NICs que administras tú (un rol de tu aplicación)
```

---

## 6. 🧱 Rutas del sistema y UDR

**El problema:** tienes que obligar a que todo el tráfico de salida de una subnet pase por un
firewall para inspeccionarlo.

Azure crea automáticamente una tabla de **rutas del sistema** para cada subnet. Las que importan:

| Prefijo | Next hop | Significado |
|---|---|---|
| Address space de la VNet | Virtual network | El tráfico entre subnets se enruta solo |
| `0.0.0.0/0` | Internet | Todo lo demás sale hacia Internet |
| `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `100.64.0.0/10` | None | Rangos privados no usados: se descartan |

Dos detalles de la ruta `0.0.0.0/0 → Internet`: el tráfico hacia las IPs públicas de servicios de
Azure **no sale a Internet**, se queda en la red troncal de Microsoft; y que exista la ruta no
significa que haya una IP pública con la que salir (§7).

Otras rutas del sistema aparecen solas cuando activas algo: peering (`Virtual network peering`),
un gateway (`Virtual network gateway`) o un service endpoint (`VirtualNetworkServiceEndpoint`).

Para cambiar el comportamiento creas una **route table** con **User Defined Routes** (UDR) y la
asocias a la subnet. Cada subnet tiene como máximo una route table. Los next hop que puedes usar en
una UDR son `VirtualAppliance` (la IP de un firewall o una NVA), `VirtualNetworkGateway`, `VnetLocal`,
`Internet` y `None` (descartar).

**Cómo elige Azure la ruta:**

1. **Longest prefix match**: gana la ruta con el prefijo más específico. Para `10.20.1.5`, una ruta a
   `10.20.1.0/24` gana a una a `10.20.0.0/16`.
2. Si hay empate de prefijo: **UDR > BGP > ruta del sistema**.

Con una excepción que cuesta encontrar: las rutas del sistema de VNet, peering y service endpoint son
preferidas incluso frente a rutas BGP más específicas, y las de service endpoint no se pueden anular
ni con una UDR.

El patrón clásico del firewall central es una UDR `0.0.0.0/0 → VirtualAppliance 10.0.100.4` en las
subnets de las cargas. Al ponerla, **todo** va al firewall, incluido el tráfico hacia las IPs públicas
de los servicios de Azure, salvo lo que tenga una ruta más específica.

> ⚠️ **No pongas la NVA en la misma subnet que enruta a través de ella.** La documentación advierte
> que puede producir bucles de enrutamiento. La NVA vive en su propia subnet, normalmente en el hub
> (§10), y necesita "IP forwarding" habilitado en su NIC.

---

## 7. 🧱 Salida a Internet

Aquí está la sobregeneralización más común del capítulo, y la respuesta correcta cambió en 2026.

La respuesta clásica era: *"una VM sin IP pública igual sale a Internet"*. Era cierto por un
mecanismo llamado **default outbound access**: si una VM no tenía un método de salida explícito,
Azure le asignaba una IP pública de salida implícita, propiedad de Microsoft, que podía cambiar sin
aviso, no admitía ping ni paquetes fragmentados y daba IPs de salida inconsistentes al escalar.

> 📝 **Contexto.** Para las versiones de API publicadas después del **31 de marzo de 2026**, las VNets
> nuevas tienen subnets privadas por defecto (`defaultOutboundAccess = false`): sus VMs **no tienen
> salida a Internet** hasta que configures un método explícito. No es un apagado general: las VNets
> existentes siguen como estaban, y una herramienta que fije una versión de API anterior sigue
> creando subnets con la salida implícita.

> Nunca respondas: "una VM sin IP pública no sale a Internet" ni "sí sale". Mejor: "depende de si la
> subnet es privada; en cualquier caso, en producción configuro un método de salida explícito,
> normalmente un NAT Gateway".

Los métodos explícitos, y el orden en que Azure los aplica cuando coexisten para una conexión nueva:

```text
UDR 0.0.0.0/0 → firewall o gateway  >  NAT Gateway  >  IP pública en la NIC
  >  outbound rules del Load Balancer  >  ruta del sistema a Internet
```

- **NAT Gateway** es el método que Microsoft recomienda: se asocia a la subnet, no admite conexiones
  entrantes no solicitadas, escala los puertos SNAT solo y da IPs de salida estables (hasta 16 IPs
  públicas o un prefijo). Tiene dos SKUs: **Standard**, zonal, y **StandardV2**, zone-redundant, con
  IPv6 y flow logs, al mismo precio.
- **IP pública en la NIC**: la VM sale con su propia IP. Útil para una VM suelta; mala idea para una
  flota.
- **Outbound rules de un Load Balancer Standard**: comparte las IPs del balanceador entre su backend,
  con riesgo de agotar puertos SNAT.
- **Firewall o NVA** con una UDR `0.0.0.0/0`: la opción cuando además quieres inspeccionar la salida.

> 💰 **Costo.** NAT Gateway cuesta **$0.045/h** en `eastus2` más el tráfico procesado, exista o no
> tráfico. Por eso el laboratorio no lo usa: la VM de diagnóstico de [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) vive en una subnet privada y
> no necesita salir a Internet ([`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones)).

---

## 8. 🧱 IP públicas

Dos datos bastan para la entrevista:

- **La SKU Basic se retiró el 30 de septiembre de 2025.** Las que siguen existiendo funcionan, pero
  sin soporte ni SLA. Todo lo nuevo es SKU **Standard**.
- **Standard es "secure by default"**: una IP pública Standard **no deja entrar tráfico** hasta que un
  NSG lo permita, a diferencia de Basic, que estaba abierta. Además es siempre estática y puede ser
  zonal o zone-redundant.

> 💰 **Costo.** Una IP pública Standard estática cuesta **$0.005/h** en `eastus2`, esté o no asociada a
> algo. Una IP olvidada tras borrar una VM es el huérfano más barato y más frecuente de una
> suscripción de práctica.

---

## 9. 🧱 VNet peering

**El problema:** tu API en una VNet tiene que llegar a una base de datos en otra VNet, sin pasar por
Internet.

**VNet peering** conecta dos VNets para que sus recursos se hablen por IP privada, sobre la red
troncal de Microsoft, sin gateways ni cifrado adicional, con la misma latencia que dentro de una VNet
cuando están en la misma región. Hay **peering local** (misma región) y **peering global** (regiones
distintas); funciona también entre suscripciones y entre tenants.

Tres reglas que se preguntan siempre:

- **No es transitivo.** Si A está peereada con B y B con C, A no llega a C. Hace falta un peering A–C,
  o que B enrute con una NVA o un firewall (§10).
- **Los address spaces no pueden solaparse.**
- **Gateway transit**: una VNet puede usar el VPN o ExpressRoute gateway de la VNet con la que está
  peereada para llegar a on-premises ([`03`](03-conectividad-privada-y-dns.md)), sin tener gateway propio.

> 💰 **Costo.** El peering en sí no cobra por existir, pero el tráfico sí: hay un cargo por GB de
> entrada y de salida en cada lado, mayor en peering global. En `eastus2`, el tráfico de peering
> global cuesta **$0.035/GB** de entrada y otro tanto de salida. El tráfico entre zonas de una misma
> VNet, en cambio, no se cobra.

---

## 10. 🧱 Hub-and-spoke y Azure Firewall

Como el peering no es transitivo, la topología estándar de una organización es **hub-and-spoke**:

```text
                     on-premises
                          │  VPN / ExpressRoute
                ┌─────────┴─────────┐
                │        HUB        │  Azure Firewall, gateway, DNS, Bastion
                └──┬──────┬──────┬──┘
          peering  │      │      │  peering
              ┌────┴─┐ ┌──┴───┐ ┌┴─────┐
              │ app1 │ │ app2 │ │ app3 │  spokes: una por carga o por equipo
              └──────┘ └──────┘ └──────┘
       UDR 0.0.0.0/0 → IP privada del firewall en cada spoke
```

- los **spokes** se peerean solo con el hub, y una UDR en cada spoke manda el tráfico al firewall del
  hub, que es quien enruta entre spokes y hacia fuera;
- el hub concentra lo compartido: la conectividad híbrida, el firewall, la resolución DNS y el
  acceso de administración;
- **Virtual WAN** es la versión administrada de esta topología para organizaciones con muchas
  regiones y sucursales; se nombra, no se profundiza.

**Azure Firewall** es el firewall administrado que se pone en el hub: stateful, con reglas de red y
de aplicación, filtrado por FQDN, inteligencia de amenazas y, en el tier Premium, inspección TLS. Se
ofrece en Basic, Standard y Premium.

> 💰 **Costo.** Azure Firewall cobra por hora de despliegue más el tráfico procesado: **$0.395/h** el
> Basic y **$1.25/h** el Standard en `eastus2`. Es el recurso más caro de una topología hub-and-spoke
> de práctica y la razón por la que el laboratorio no lo incluye.

**DDoS Protection** (protección de red por VNet) y **Azure Bastion** (acceso RDP/SSH por el
navegador sin IPs públicas en las VMs) también viven normalmente en el hub; basta con saber qué
problema resuelve cada uno.

---

## 11. 🩺 Diagnóstico de conectividad

Cuando "no conecta", la tentación es abrir puertos al azar. La secuencia que evita eso:

```text
1. ¿El nombre resuelve a la IP que esperas?          → capítulo 03 (DNS y private endpoints)
2. ¿Hay ruta hacia esa IP?                           → effective routes / next hop
3. ¿Los NSG dejan pasar, en subnet Y en NIC?         → effective security rules / IP flow verify
4. Si es tráfico hacia Internet, ¿hay método de salida? → subnet privada, NAT Gateway, IP pública
5. ¿El servicio escucha realmente en ese puerto?
6. ¿Connection troubleshoot confirma el recorrido completo?
```

Las herramientas de los pasos 2 y 3, contra la NIC de la VM de diagnóstico de [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md):

```bash
az network nic show-effective-route-table \
  --resource-group inv-lab-rg \
  --name inv-lab-vmVMNic \
  --output table

az network nic list-effective-nsg \
  --resource-group inv-lab-rg \
  --name inv-lab-vmVMNic
```

- `show-effective-route-table` muestra la tabla de rutas **efectiva** de la NIC: las del sistema, las
  UDR y las BGP ya combinadas, con su estado `Active` o `Invalid`. Es la única forma de ver qué ruta
  gana de verdad, en vez de deducirlo de la route table.
- `list-effective-nsg` muestra las reglas que se aplican a la NIC combinando el NSG de la subnet y el
  de la NIC, con los service tags expandidos a prefijos.
- `--name inv-lab-vmVMNic` es el nombre de la NIC que `az vm create` genera por defecto para una VM
  llamada `inv-lab-vm`. Las dos órdenes necesitan que la VM esté encendida: con la VM desasignada, la
  NIC no tiene estado efectivo que mostrar.

Y para el paso 3 con un caso concreto, **IP flow verify** de Network Watcher:

```bash
az network watcher test-ip-flow \
  --resource-group inv-lab-rg \
  --vm inv-lab-vm \
  --direction Outbound \
  --protocol TCP \
  --local 10.20.1.4:60000 \
  --remote 203.0.113.10:443
```

- `test-ip-flow` evalúa si un paquete con esa tupla se permitiría o denegaría, y **devuelve el nombre
  de la regla** que decidió. No envía ningún paquete: es una simulación sobre la configuración.
- `--direction` y `--protocol` fijan el sentido y el protocolo del paquete simulado.
- `--local` es la IP privada y el puerto de la VM (`IP:puerto`); `--remote`, el destino. Aquí
  `203.0.113.10` es una dirección de documentación (TEST-NET-3), usada como ejemplo de destino
  público.
- Necesita que Network Watcher esté habilitado en la región, lo que ocurre solo al crear la primera
  VNet, en el resource group `NetworkWatcherRG` ([`L00` §7.3](l00-idea-lab-practico.md#73-el-resource-group-es-la-unidad-de-destrucción-con-letra-pequeña)).

> 🩺 **Diagnóstico.** Si IP flow verify dice `Allow` y aun así no conecta, el problema no es el NSG:
> revisa la ruta (paso 2), el método de salida (paso 4) o el servicio (paso 5). Si dice `Deny`, te dice
> qué regla lo niega y en qué NSG, y el problema ya tiene nombre.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "La VNet es global" | Es regional y abarca las zonas de su región; entre regiones hace falta peering |
| "El peering es transitivo" | No lo es; A–B y B–C no dan A–C |
| "Una VM sin IP pública siempre sale a Internet" | Depende de si la subnet es privada, que es el default para VNets nuevas desde el 31-03-2026 |
| "Un NSG recién creado bloquea la salida" | `AllowInternetOutBound` permite toda la salida por defecto |
| "Si el NSG de la NIC permite el puerto, el tráfico pasa" | También tiene que pasar el NSG de la subnet |
| "Un NSG es un firewall" | Es un filtro de 5-tupla distribuido; FQDN e inspección son de Azure Firewall |
| "Una `/24` da 254 IPs" | Da 251: Azure reserva cinco direcciones por subnet |
| "Una IP pública Standard está abierta como la Basic" | Standard es secure by default: cerrada hasta que un NSG lo permita |

---

## 🧠 Preguntas rápidas

1. ¿Una VNet puede abarcar dos regiones? ¿Y dos Availability Zones?
2. ¿Cuántas direcciones reserva Azure en cada subnet y cuáles son?
3. ¿En qué orden evalúa Azure las reglas de un NSG y qué pasa cuando una coincide?
4. Hay un NSG en la subnet y otro en la NIC. ¿Qué tiene que pasar para que un paquete entrante llegue a la VM?
5. ¿Qué regla por defecto de un NSG permite la salida a Internet y cómo se restringe esa salida?
6. ¿Qué diferencia a un service tag de un Application Security Group?
7. Dos rutas coinciden con el destino: una a `10.20.0.0/16` y otra a `10.20.1.0/24`. ¿Cuál usa Azure para `10.20.1.5` y por qué?
8. ¿Qué significa que una subnet sea privada (`defaultOutboundAccess = false`) y qué cambió el 31 de marzo de 2026?
9. ¿Qué método de salida a Internet recomienda Microsoft y por qué es mejor que la salida por defecto?
10. VNet A está peereada con B, y B con C. ¿Puede A hablar con C?
11. ¿Por qué la topología estándar de una organización es hub-and-spoke y qué vive en el hub?
12. ¿Cuándo pondrías Azure Firewall en vez de confiar solo en NSG?
13. IP flow verify devuelve `Allow` para el tráfico de tu VM hacia una API externa, pero la conexión sigue fallando. ¿Qué revisas a continuación?
14. ¿Qué diferencia de seguridad hay entre una IP pública Standard y la antigua Basic?

---

## 📚 Referencias oficiales

- Preguntas frecuentes de Virtual Network (alcance regional, IPs reservadas, tamaños): https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq
- ¿Qué es Azure Virtual Network?: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
- Network security groups: https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview
- Service tags: https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview
- Application security groups: https://learn.microsoft.com/en-us/azure/virtual-network/application-security-groups
- Enrutamiento del tráfico de la VNet (rutas del sistema y UDR): https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview
- Default outbound access y subnets privadas: https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access
- ¿Qué es Azure NAT Gateway?: https://learn.microsoft.com/en-us/azure/nat-gateway/nat-overview
- Retiro de las IP públicas Basic y diferencias con Standard: https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-basic-upgrade-guidance
- VNet peering: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview
- Topología hub-and-spoke: https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke
- ¿Qué es Azure Firewall?: https://learn.microsoft.com/en-us/azure/firewall/overview
- Precios de Azure Firewall: https://azure.microsoft.com/en-us/pricing/details/azure-firewall/
- Precios de NAT Gateway: https://azure.microsoft.com/en-us/pricing/details/azure-nat-gateway/
- Precios de Virtual Network (IPs públicas y peering): https://azure.microsoft.com/en-us/pricing/details/virtual-network/
- Diagnosticar un problema de enrutamiento: https://learn.microsoft.com/en-us/azure/virtual-network/diagnose-network-routing-problem
- Diagnosticar un problema de filtrado de tráfico: https://learn.microsoft.com/en-us/azure/virtual-network/diagnose-network-traffic-filter-problem
- IP flow verify de Network Watcher: https://learn.microsoft.com/en-us/azure/network-watcher/ip-flow-verify-overview
- Flow logs de VNet (y retiro de los flow logs de NSG): https://learn.microsoft.com/en-us/azure/network-watcher/vnet-flow-logs-overview
- `az network vnet`: https://learn.microsoft.com/en-us/cli/azure/network/vnet
- `az network nsg rule`: https://learn.microsoft.com/en-us/cli/azure/network/nsg/rule
- `az network nic`: https://learn.microsoft.com/en-us/cli/azure/network/nic
- `az network watcher test-ip-flow`: https://learn.microsoft.com/en-us/cli/azure/network/watcher#az-network-watcher-test-ip-flow
