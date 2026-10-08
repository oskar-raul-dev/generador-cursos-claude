# 03 — Conectividad privada y DNS

> **Objetivo:** llegar a los servicios de Azure y a on-premises sin pasar por Internet, y
> diagnosticar el fallo más frecuente de Azure: un nombre que resuelve a la IP equivocada.
> **Se asume leído:** [`02` — redes](02-redes-vnet-nsg-y-enrutamiento.md): VNet, subnets, NSG y rutas.
> **Se toca más con:** [`02`](02-redes-vnet-nsg-y-enrutamiento.md), sobre el que se apoya, y los
> capítulos de datos (`06`, `07`, `08`), cuyos servicios se consumen por private endpoint.
> **Se practica en:** [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) (private endpoint a la storage account con su Private DNS zone, y la
> resolución que falla sin el VNet link). Ver [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [El problema](#1--el-problema-el-servicio-tiene-una-ip-pública) ·
[Service Endpoints](#2--service-endpoints) · [Private Endpoints](#3--private-endpoints-y-private-link) ·
[⚖ Service vs Private](#4--service-endpoint-frente-a-private-endpoint) ·
[La resolución DNS](#5--la-resolución-dns-de-un-private-endpoint) ·
[Private DNS zones](#6--private-dns-zones) · [168.63.129.16](#7--1686312916-el-resolver-de-la-plataforma) ·
[DNS Private Resolver](#8--dns-private-resolver-y-la-resolución-híbrida) ·
[Azure DNS público](#9--azure-dns-público) · [VPN y ExpressRoute](#10--vpn-gateway-y-expressroute) ·
[Diagnóstico](#11--diagnóstico-el-nombre-resuelve-a-la-ip-pública) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El problema: el servicio tiene una IP pública

Tu API corre en una VNet privada. La storage account, el Key Vault, la base de datos y Service Bus
**no viven en tu VNet**: son servicios multi-tenant con un endpoint público, como
`invlab472913.blob.core.windows.net`, que resuelve a una IP pública de Microsoft.

Para un banco, "el tráfico va a una IP pública" es una frase que termina la conversación, aunque en
realidad ese tráfico ya viaje por la red troncal de Microsoft ([`02` §6](02-redes-vnet-nsg-y-enrutamiento.md#6--rutas-del-sistema-y-udr)). El requisito real
suele ser doble:

1. que el servicio **no acepte conexiones desde Internet**;
2. que tu aplicación **llegue a él por una IP privada de tu red**, incluida la red de on-premises.

Azure resuelve eso con dos mecanismos que se confunden constantemente —service endpoints y private
endpoints—, y el segundo arrastra un problema de DNS que es, con diferencia, la causa más frecuente
de incidencias de red en Azure.

---

## 2. 🧱 Service Endpoints

Un **service endpoint** se activa **en una subnet**, para un tipo de servicio (`Microsoft.Storage`,
`Microsoft.Sql`, `Microsoft.KeyVault`…). Hace dos cosas:

- el tráfico de esa subnet hacia el servicio sale con la **IP privada** de la VM como origen, en vez
  de con una IP pública, y va por la red troncal por una ruta más específica que el `0.0.0.0/0`;
- el servicio puede identificar esa subnet, así que en su firewall añades una **regla de VNet**:
  "acepta solo tráfico de `inv-lab-snet`".

Lo que **no** cambia, y es la clave:

- **el servicio sigue teniendo su IP pública y su DNS sigue resolviendo a ella**; tu VM sigue
  conectándose a una IP pública, solo que el servicio sabe de qué subnet viene;
- **no llega desde on-premises**: un service endpoint es una propiedad de una subnet de Azure. Para
  permitir on-premises tendrías que abrir en el firewall del servicio las IPs públicas de tu NAT;
- **abre el servicio entero, no una instancia**: con el service endpoint de Storage activo, tu subnet
  puede alcanzar *cualquier* storage account de Azure, incluida la de un atacante. Para acotarlo a
  cuentas concretas existen las *service endpoint policies*.

No tiene costo. Microsoft recomienda hoy private endpoints para acceso privado, y service endpoints
cuando basta con restringir por subnet y se quiere evitar el costo y la complejidad de DNS.

---

## 3. 🧱 Private Endpoints y Private Link

Un **private endpoint** es una **NIC con una IP privada de tu subnet** que representa a **una
instancia concreta** de un servicio —esta storage account, este Key Vault—. El servicio "entra" en tu
red: le hablas a `10.20.1.5`, y la plataforma lleva esa conexión, por **Azure Private Link**, al
recurso de destino.

Las propiedades que importan:

- **apunta a un recurso y a un subrecurso**: una storage account tiene subrecursos `blob`, `file`,
  `queue`, `table`, `dfs`, `web`. Un private endpoint por subrecurso: si tu app usa blobs y colas,
  necesitas dos;
- **protege contra la exfiltración**: el private endpoint solo llega a *ese* recurso, no a cualquier
  cuenta del servicio;
- **las conexiones son unidireccionales**: solo el cliente inicia; el servicio no puede abrir
  conexiones hacia tu red;
- **se alcanza desde toda la red conectada**: la propia VNet, VNets peereadas (locales o globales) y
  on-premises por VPN o ExpressRoute. Es exactamente lo que el service endpoint no daba;
- **vive en la región y la suscripción de su VNet**, pero el recurso de destino puede estar en otra
  región;
- **tiene un flujo de aprobación**: automático si tienes permisos sobre el recurso, manual si no
  (queda `Pending` hasta que el dueño lo aprueba). Solo un private endpoint `Approved` pasa tráfico.

> ⚠️ **Crear un private endpoint no cierra el acceso público.** El servicio sigue aceptando tráfico
> por su endpoint público hasta que pones `publicNetworkAccess` en `Disabled` o restringes su
> firewall. Es la mitad olvidada del requisito del banco.

Por defecto, los NSG y las UDR **no se aplican** al tráfico hacia un private endpoint; hay que activar
las *network policies* de la subnet para que lo hagan. Y la NIC del private endpoint no muestra
effective routes ni effective security rules en el portal.

> 💰 **Costo.** Un private endpoint cuesta **$0.01/h** más **$0.01/GB** procesado en el primer
> tramo, exista o no tráfico. Una arquitectura con un private endpoint por subrecurso y por servicio
> multiplica esa hora rápidamente; en [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) vive una sola hora.

**Private Link Service** es el mismo mecanismo visto desde el otro lado: publicar **tu propio**
servicio, detrás de un Load Balancer Standard, para que otros lo consuman por private endpoint desde
sus VNets, sin peering y aunque los espacios de direcciones se solapen.

---

## 4. ⚖ Service endpoint frente a private endpoint

| Criterio | Service endpoint | Private endpoint |
|---|---|---|
| A qué IP te conectas | La IP pública del servicio | Una IP privada de tu subnet |
| Alcance | Todo el servicio (cualquier cuenta) | Una instancia y un subrecurso |
| Desde on-premises | ❌ | ✅ por VPN o ExpressRoute |
| Cambia el DNS | ❌ | ✅ hay que configurarlo (§5) |
| Costo | Sin cargo | Por hora y por GB |

```text
Regla de entrevista:
¿Solo necesito que el servicio acepte tráfico de mi subnet?        → service endpoint
¿Necesito IP privada, acceso desde on-premises o anti-exfiltración? → private endpoint
```

---

## 5. 🧱 La resolución DNS de un private endpoint

Aquí está el diagnóstico más frecuente de Azure, y la razón por la que el capítulo existe.

**El problema:** creas el private endpoint, deshabilitas el acceso público, y tu aplicación empieza a
fallar con `403` o con timeouts. El private endpoint está `Approved`. El NSG permite todo. ¿Qué pasó?

Pasó que tu aplicación sigue conectándose a `invlab472913.blob.core.windows.net`, **ese nombre
todavía resuelve a la IP pública** y el servicio, con el acceso público deshabilitado, la rechaza.
Crear el private endpoint no cambia lo que responde el DNS: eso lo hace una **Private DNS zone
vinculada a tu VNet**.

El mecanismo es una cadena de CNAME que Azure publica en el DNS público para todo recurso que admite
private endpoints:

```text
Desde DENTRO de la VNet, con la Private DNS zone privatelink.blob.core.windows.net vinculada:

invlab472913.blob.core.windows.net
   │ CNAME (DNS público de Azure)
   ▼
invlab472913.privatelink.blob.core.windows.net
   │ la zona privada vinculada a la VNet tiene un registro A
   ▼
10.20.1.5                          ← la IP del private endpoint


Desde FUERA de la VNet (Internet, o una VNet sin la zona vinculada):

invlab472913.blob.core.windows.net
   │ CNAME
   ▼
invlab472913.privatelink.blob.core.windows.net
   │ no hay zona privada: el DNS público sigue la cadena
   ▼
<endpoint público del clúster de almacenamiento>  →  IP pública
```

Cuatro consecuencias que se preguntan:

- **la cadena de connection string no cambia**: tu aplicación sigue usando el nombre público; es el
  DNS quien decide a qué IP llega. Nunca se configura la app con `privatelink.blob.core.windows.net`;
- **la parte `privatelink` del CNAME es pública y resoluble desde cualquier sitio**, a propósito, para
  que los escenarios híbridos y las migraciones graduales no rompan a los clientes existentes. Que el
  nombre resuelva no da acceso: con el acceso público deshabilitado, el servicio rechaza la conexión
  de todas formas;
- **el nombre de la zona privada no es libre**: para que la configuración automática funcione, hay
  que usar el nombre recomendado por servicio —`privatelink.blob.core.windows.net`,
  `privatelink.vaultcore.azure.net`, `privatelink.database.windows.net`,
  `privatelink.documents.azure.com`, `privatelink.servicebus.windows.net`—;
- **nunca crees una zona privada con el nombre público** (`blob.core.windows.net`): la documentación
  lo desaconseja expresamente, porque todas las cuentas que no tengan registro en tu zona dejarían de
  resolver.

Y un efecto secundario que sorprende: con la zona `privatelink.blob.core.windows.net` vinculada,
**una storage account que no es tuya pero tiene private endpoints en otra red** publica su CNAME
hacia `privatelink`, la consulta termina en tu zona, no encuentra registro y devuelve `NXDOMAIN`:
tu VM deja de poder alcanzar por su endpoint público una cuenta ajena a la que antes llegaba. La funcionalidad
*fallback to Internet* del VNet link resuelve ese caso reenviando la consulta a la resolución
pública.

---

## 6. 🧱 Private DNS zones

Una **Private DNS zone** es una zona DNS que solo resuelve para las VNets que vinculas con ella.

- **VNet link**: sin link, la zona no existe para esa VNet. Una zona puede vincularse a muchas VNets,
  en cualquier región y suscripción: los datos de la zona se guardan como recurso global y no
  dependen de una región. Las VNets vinculadas no necesitan estar peereadas entre sí para resolver.
- **Autoregistration**: opcional en el link. Registra automáticamente un registro A por cada VM de la
  VNet y lo borra cuando la VM se borra. Una VNet solo puede tener **un** link con autoregistration.
- **Split-horizon**: una zona privada y una pública pueden tener el mismo nombre y responder distinto
  dentro y fuera de la VNet.
- **Zone group** del private endpoint: la forma de que Azure cree y borre solo el registro A del
  private endpoint en la zona correcta.

El conjunto completo para el private endpoint de blobs del laboratorio:

```bash
az network private-endpoint create \
  --name inv-lab-pe-blob \
  --resource-group inv-lab-rg \
  --vnet-name inv-lab-vnet \
  --subnet inv-lab-snet \
  --private-connection-resource-id "$(az storage account show --name invlab472913 --resource-group inv-lab-rg --query id --output tsv)" \
  --group-id blob \
  --connection-name inv-lab-pe-blob-conn
```

- `--vnet-name` y `--subnet` deciden de qué subnet sale la IP privada del private endpoint.
- `--private-connection-resource-id` es el **resource ID** del recurso de destino. Aquí se obtiene
  con un `az storage account show … --query id --output tsv` anidado, para no copiar a mano el ID
  largo del [`01` §9](01-infraestructura-global-y-resource-manager.md#9--azure-resource-manager-y-el-resource-id).
- `--group-id blob` elige el **subrecurso**. Si pones `file`, tendrás un private endpoint que funciona
  perfectamente… para Azure Files, y tu código de blobs seguirá yendo a la IP pública.
- `--connection-name` es el nombre de la conexión de Private Link que verá el dueño del recurso en su
  lista de conexiones para aprobar o rechazar.

```bash
az network private-dns zone create \
  --resource-group inv-lab-rg \
  --name privatelink.blob.core.windows.net

az network private-dns link vnet create \
  --resource-group inv-lab-rg \
  --zone-name privatelink.blob.core.windows.net \
  --name inv-lab-vnet-link \
  --virtual-network inv-lab-vnet \
  --registration-enabled false

az network private-endpoint dns-zone-group create \
  --resource-group inv-lab-rg \
  --endpoint-name inv-lab-pe-blob \
  --name default \
  --private-dns-zone privatelink.blob.core.windows.net \
  --zone-name blob
```

- `az network private-dns zone create --name` usa **exactamente** el nombre recomendado para blobs. Un
  nombre distinto crea una zona válida que nadie consulta.
- `link vnet create --registration-enabled false` vincula la zona a la VNet **sin** autoregistration:
  en esta zona solo deben vivir los registros de private endpoints, no los de las VMs. Sin este link,
  el paso siguiente crea el registro, pero ninguna VM lo ve: es el fallo que [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) provoca a
  propósito.
- `dns-zone-group create` asocia el private endpoint con la zona: Azure crea el registro A
  `invlab472913` → IP privada y lo borra si borras el private endpoint. `--zone-name blob` es solo la
  etiqueta de esa configuración dentro del grupo.

Y la mitad olvidada del requisito:

```bash
az storage account update \
  --name invlab472913 \
  --resource-group inv-lab-rg \
  --public-network-access Disabled
```

- `--public-network-access Disabled` cierra el endpoint público de la cuenta: a partir de aquí solo se
  llega por el private endpoint. Si lo haces antes de tener el DNS bien resuelto, tu propia sesión de
  `az` desde tu portátil pierde el acceso a los datos de la cuenta, porque no está en la VNet.

> 💰 **Costo.** Una Private DNS zone cuesta **$0.50 al mes** por zona en el primer tramo, más las
> consultas. En una organización se centralizan las zonas `privatelink.*` en la suscripción del hub
> y se vinculan a todas las spokes, en vez de crear una por aplicación.

---

## 7. 🧱 168.63.129.16, el resolver de la plataforma

Si una VNet usa el DNS por defecto de Azure, sus VMs resuelven a través de **`168.63.129.16`**, una
IP pública virtual que es la misma en todas las regiones y que Microsoft nunca cambia. No es solo DNS:

- es el **resolver DNS** que consulta, en orden, las Private DNS zones vinculadas y luego la
  resolución pública;
- por ella el **agente de la VM** informa a la plataforma de que está listo;
- de ella vienen los **health probes** del Load Balancer;
- sirve el **DHCP** de la VNet.

Tres reglas prácticas:

- el tráfico hacia `168.63.129.16` **no está sujeto a tus NSG ni a tus UDR** por defecto;
- **solo se alcanza desde dentro de Azure**: un servidor DNS de on-premises no puede reenviarle
  consultas a través de una VPN;
- bloquearla en el firewall local de la VM rompe el agente, el DNS y los health probes a la vez.

La segunda regla es la que obliga a la sección siguiente.

---

## 8. 🧱 DNS Private Resolver y la resolución híbrida

**El problema:** un servidor en on-premises tiene que resolver `invlab472913.blob.core.windows.net`
a la IP del private endpoint, y tu DNS corporativo no ve tus Private DNS zones.

Antes se resolvía con VMs de DNS dentro de la VNet haciendo de reenviadores. **Azure DNS Private
Resolver** es el servicio administrado que las sustituye, con alta disponibilidad y redundancia de
zona incluidas:

- un **inbound endpoint** es una IP privada de tu VNet que acepta consultas. Tu DNS de on-premises
  configura un *conditional forwarder* para `blob.core.windows.net` hacia esa IP, y la consulta se
  resuelve en Azure, con tus zonas privadas;
- un **outbound endpoint** con un **DNS forwarding ruleset** hace lo inverso: reenvía desde Azure
  hacia tus DNS de on-premises los dominios corporativos (`corp.banco.local`), con reglas por
  sufijo.

```text
on-premises                          Azure (hub)
DNS corporativo ── conditional ──► inbound endpoint (10.x.x.x)
  forwarder para                        │
  blob.core.windows.net                 ▼
                                   Private DNS zone privatelink.blob.core.windows.net
                                        │
                                        ▼
                                   10.20.1.5 (private endpoint)
```

Cada endpoint necesita **una subnet propia, delegada a `Microsoft.Network/dnsResolvers`**, de entre
`/28` y `/24`. El resolver es regional y referencia una sola VNet; en hub-and-spoke vive en el hub.

---

## 9. 🧱 Azure DNS público

**Azure DNS** aloja tus zonas públicas en los servidores de nombres de Microsoft. Lo que se pregunta:

- **no es un registrador**: compras el dominio en otro sitio y **delegas** en Azure DNS configurando
  en el registrador los registros NS que te asigna la zona;
- una zona contiene **record sets** (A, AAAA, CNAME, MX, TXT, CAA…);
- los **alias records** apuntan a un recurso de Azure —una IP pública, un perfil de Front Door o de
  Traffic Manager— en vez de a una IP fija, se actualizan solos si cambia la IP del recurso y
  permiten apuntar el **apex** del dominio (`banco.com`, sin `www`) a un recurso, cosa que un CNAME no
  permite.

El balanceo por DNS con Traffic Manager y la entrega global con Front Door se ven en [`05`](05-balanceo-entrega-global-y-api-management.md).

---

## 10. 🧱 VPN Gateway y ExpressRoute

Para unir on-premises con tus VNets hay dos productos, y la diferencia es de naturaleza, no de
velocidad.

- **VPN Gateway**: túneles IPsec **sobre Internet**. *Site-to-site* conecta tu red con la VNet;
  *point-to-site* conecta equipos individuales. Admite modo *active-active* para alta disponibilidad
  y vive en una subnet obligatoria llamada `GatewaySubnet`.
- **ExpressRoute**: un **circuito privado** contratado a un proveedor de conectividad, que **no pasa
  por Internet**, con ancho de banda fijo (de 50 Mbps a 10 Gbps por proveedor, más con ExpressRoute
  Direct) y dos sesiones BGP redundantes. Tiene dos *peerings*:
  - **private peering**: extiende tu red a tus VNets por IP privada;
  - **Microsoft peering**: llega a los servicios de Microsoft por IP pública, sin Internet de por
    medio.

> Nunca respondas: "ExpressRoute está cifrado porque es privado". Mejor: "ExpressRoute es un circuito
> privado, no un túnel cifrado; si el requisito es cifrar, se añade IPsec encima o MACsec en
> ExpressRoute Direct".

La elección, en una línea: **VPN** cuando basta con conectividad cifrada por Internet y un costo
bajo; **ExpressRoute** cuando se necesita ancho de banda y latencia predecibles o el cumplimiento
exige no usar Internet. En banca es habitual tener los dos: ExpressRoute como vía principal y VPN
como respaldo.

Ninguno de los dos entra en el laboratorio: un gateway cobra por hora y una conexión a on-premises no
existe en una suscripción de práctica.

---

## 11. 🩺 Diagnóstico: el nombre resuelve a la IP pública

La secuencia para el síntoma "creé el private endpoint y no funciona", que completa el paso 1 del
diagnóstico del [`02` §11](02-redes-vnet-nsg-y-enrutamiento.md#11--diagnóstico-de-conectividad):

```text
1. Desde DENTRO de la VNet, ¿el FQDN público resuelve a la IP privada?
   nslookup invlab472913.blob.core.windows.net
   ├── resuelve a 10.20.x.x       → el DNS está bien; sigue con ruta y NSG (capítulo 02)
   └── resuelve a una IP pública  → sigue en 2
2. ¿Existe la zona privatelink con el nombre EXACTO recomendado para ese subrecurso?
3. ¿La zona está vinculada a ESTA VNet (VNet link)?
4. ¿La zona tiene el registro A del recurso? (zone group del private endpoint)
5. ¿La VNet usa el DNS de Azure o un DNS propio? Si es propio, ¿reenvía a 168.63.129.16
   o a un inbound endpoint del DNS Private Resolver?
6. Desde on-premises: ¿hay conditional forwarder hacia el inbound endpoint?
7. ¿La conexión de Private Link está Approved?
```

El caso real con la salida literal de `nslookup` en cada punto lo produce [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) contra la
suscripción del laboratorio.

> 🩺 **Diagnóstico.** Si desde tu portátil la cuenta resuelve a una IP pública y te da `403`
> después de deshabilitar el acceso público, no hay nada roto: tu portátil no está en la VNet. Es el
> comportamiento esperado, y la razón por la que en banca los pipelines de despliegue corren en
> agentes dentro de la red privada.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Service endpoint y private endpoint son lo mismo" | El primero identifica tu subnet ante una IP pública; el segundo pone una IP privada en tu red |
| "Con el private endpoint creado, ya funciona" | Falta la Private DNS zone con el nombre recomendado, vinculada a la VNet |
| "Crear un private endpoint cierra el acceso público" | Hay que deshabilitar `publicNetworkAccess` o restringir el firewall |
| "Hay que cambiar la connection string a `privatelink`" | La app sigue usando el nombre público; el DNS decide la IP |
| "Un service endpoint funciona desde on-premises" | Solo aplica a subnets de Azure |
| "El DNS de on-premises puede reenviar a 168.63.129.16" | Solo se alcanza desde Azure; hace falta un inbound endpoint del DNS Private Resolver |
| "ExpressRoute está cifrado" | Es un circuito privado; el cifrado se añade con IPsec o MACsec |
| "Un private endpoint para la cuenta cubre blobs y colas" | Es un private endpoint por subrecurso |

---

## 🧠 Preguntas rápidas

1. ¿Qué cambia y qué no cambia en la conexión de una VM con Storage cuando activas un service endpoint en su subnet?
2. ¿Por qué un service endpoint no protege contra la exfiltración de datos y un private endpoint sí?
3. ¿Qué es exactamente un private endpoint y de dónde saca su IP?
4. Creaste un private endpoint para una storage account. ¿El acceso público queda cerrado?
5. Tu app usa blobs y colas de la misma storage account por private endpoint. ¿Cuántos private endpoints necesitas?
6. ¿Qué connection string debe usar la aplicación cuando accede a un recurso por private endpoint?
7. Describe la cadena de resolución de `invlab472913.blob.core.windows.net` desde dentro de una VNet con la Private DNS zone vinculada y desde Internet.
8. ¿Por qué nunca debes crear una Private DNS zone llamada `blob.core.windows.net`?
9. ¿Qué es `168.63.129.16`, para qué sirve además del DNS y desde dónde se alcanza?
10. ¿Cómo resuelve un servidor de on-premises el FQDN de un recurso con private endpoint?
11. ¿Cuándo elegirías ExpressRoute en vez de VPN Gateway, y está ExpressRoute cifrado por defecto?
12. ¿Qué ventaja tiene un alias record de Azure DNS sobre un CNAME para el apex de un dominio?
13. Creaste el private endpoint y deshabilitaste el acceso público, y tu aplicación dentro de la VNet recibe `403`. ¿Qué revisas y en qué orden?

---

## 📚 Referencias oficiales

- ¿Qué es un private endpoint?: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview
- ¿Qué es Azure Private Link?: https://learn.microsoft.com/en-us/azure/private-link/private-link-overview
- Configuración DNS de private endpoints y nombres de zona recomendados: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
- Network policies para private endpoints: https://learn.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy
- ¿Qué es Private Link Service?: https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview
- Service endpoints de VNet: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview
- Service endpoint policies: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoint-policies-overview
- Azure Private DNS: https://learn.microsoft.com/en-us/azure/dns/private-dns-overview
- Fallback to Internet en Private DNS: https://learn.microsoft.com/en-us/azure/dns/private-dns-fallback
- La IP 168.63.129.16: https://learn.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16
- Azure DNS Private Resolver: https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview
- Resolución de nombres para VMs y resolución híbrida: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-name-resolution-for-vms-and-role-instances
- Alias records de Azure DNS: https://learn.microsoft.com/en-us/azure/dns/dns-alias
- Delegar un dominio en Azure DNS: https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns
- ¿Qué es VPN Gateway?: https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways
- Circuitos y peerings de ExpressRoute: https://learn.microsoft.com/en-us/azure/expressroute/expressroute-circuit-peerings
- Cifrado en ExpressRoute: https://learn.microsoft.com/en-us/azure/expressroute/expressroute-about-encryption
- Precios de Private Link: https://azure.microsoft.com/en-us/pricing/details/private-link/
- Precios de Azure DNS: https://azure.microsoft.com/en-us/pricing/details/dns/
- `az network private-endpoint`: https://learn.microsoft.com/en-us/cli/azure/network/private-endpoint
- `az network private-dns`: https://learn.microsoft.com/en-us/cli/azure/network/private-dns
- `az storage account update`: https://learn.microsoft.com/en-us/cli/azure/storage/account#az-storage-account-update
