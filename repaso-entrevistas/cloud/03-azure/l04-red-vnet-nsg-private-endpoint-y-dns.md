# L04 — Red: VNet, NSG, private endpoint y DNS

> **Objetivo:** practicar los dos diagnósticos de red más frecuentes de Azure con una VM sin IP
> pública: la VM que "no sale" porque su subnet es privada, y el FQDN de una storage account que
> resuelve a la IP pública cuando debería resolver a la privada. Por el camino, un NSG con prioridades
> y service tags, un NAT Gateway, un private endpoint con su Private DNS zone, y Network Watcher para
> confirmar cada hipótesis.
> **Se asume leído:** [`02`](02-redes-vnet-nsg-y-enrutamiento.md) (VNet, NSG, rutas y salida a
> Internet) y [`03`](03-conectividad-privada-y-dns.md) (private endpoints y su DNS).
> **Costo:** **~$0.07 por sesión de una hora** con todo encendido: VM B1ls a $0.0052/h, su disco
> Standard HDD S4 ($1.536 al mes, prorrateado), private endpoint a $0.01/h, NAT Gateway a $0.045/h más
> $0.005/h de su IP pública Standard, y la Private DNS zone a $0.50 al mes como máximo. Todo lo que
> cobra se destruye en este mismo lab.
> **Duración:** 2–3 horas.
> **Prerrequisitos:** [`L03`](l03-bicep-desde-la-cli.md) terminado: la storage account `invlab472913`
> existe y el provider `Microsoft.Network` está registrado.
> **Qué queda encendido al terminar:** `inv-lab-vnet` con `inv-lab-snet` y el NSG `inv-lab-nsg`, que
> no cobran, y el `NetworkWatcherRG` que Azure crea fuera de tu grupo. **Ni VM, ni NAT Gateway, ni
> private endpoint, ni Private DNS zone.**
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [Qué se practica](#1--qué-se-practica-y-por-qué-en-la-nube) ·
[VNet y subnet privada](#2--la-vnet-y-una-subnet-privada) · [NSG](#3--el-nsg-prioridades-y-service-tags) ·
[La VM de diagnóstico](#4--la-vm-de-diagnóstico-sin-ip-pública) ·
[La VM que no contesta](#5--la-vm-que-no-contesta) · [NAT Gateway](#6--nat-gateway-la-salida-explícita) ·
[El NSG que corta](#7--el-nsg-que-corta-la-salida-y-el-service-tag-que-la-devuelve) ·
[Private endpoint](#8--el-private-endpoint-de-blobs) ·
[DNS sin VNet link](#9--la-resolución-que-falla-sin-el-vnet-link) ·
[Acceso público cerrado](#10--cerrar-el-acceso-público-y-leer-el-403-de-red) ·
[Teardown](#11--teardown-de-lo-que-cobra) · [Checklist](#-checklist-de-salida) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Qué se practica, y por qué en la nube

La doctrina de reparto de [`L00` §7.1](l00-idea-lab-practico.md#71-por-qué-nueve-labs) justifica este
lab en una frase: la VNet, sus subnets y sus NSG no cobran, y lo que cobra —una VM y un private
endpoint durante una hora— son centavos, a cambio del diagnóstico más frecuente de Azure. Ningún
contenedor local tiene `168.63.129.16`, Private DNS zones, subnets privadas por defecto ni Network
Watcher.

El lab sigue el método de la guía: **una variable a la vez, y reproducir antes de reparar**. Cada
sección rompe una cosa, la confirma con un comando de diagnóstico y solo entonces la arregla.

```text
§5  la VM no contesta          → subnet privada, sin método de salida      → §6 NAT Gateway
§7  la VM deja de contestar    → NSG que deniega Internet                  → service tag AzureCloud
§9  el FQDN resuelve a pública → Private DNS zone sin VNet link             → el link
§10 la API responde 403        → acceso público cerrado desde fuera        → entrar por la VNet
```

---

## 2. 🧱 La VNet, y una subnet privada

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
SUB=$(az account show --query id --output tsv)

az network vnet create \
  --name inv-lab-vnet \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --address-prefixes 10.20.0.0/16 \
  --tags project=inv-lab env=lab
```

- `--name inv-lab-vnet` admite de 2 a 64 caracteres: letras, dígitos, guiones bajos, puntos y
  guiones, empezando por alfanumérico.
- `--address-prefixes 10.20.0.0/16` es el espacio de direcciones del baseline: 65.536 IPs privadas,
  de las que el lab usará una subnet. Una VNet es **regional**: vive en `eastus2` y abarca todas sus
  zonas ([`02` §2](02-redes-vnet-nsg-y-enrutamiento.md#2--la-vnet-es-regional)).
- No se pasa `--subnet-name`: la subnet se crea aparte para declarar sus propiedades una a una.

> ⚠️ **Crear una VNet habilita Network Watcher en la región**, en un resource group llamado
> `NetworkWatcherRG` que **no es tuyo** y que `az group delete --name inv-lab-rg` no toca. No cobra
> por existir, pero aparece en tu inventario y nadie te avisó ([`L00` §7.3](l00-idea-lab-practico.md#73-el-resource-group-es-la-unidad-de-destrucción-con-letra-pequeña)).
> Compruébalo con `az network watcher list --output table`.

La subnet, **privada de forma explícita**:

```bash
az network vnet subnet create \
  --name inv-lab-snet \
  --resource-group inv-lab-rg \
  --vnet-name inv-lab-vnet \
  --address-prefixes 10.20.1.0/24 \
  --default-outbound-access false
```

- `10.20.1.0/24` da 251 IPs útiles: Azure reserva las cuatro primeras y la última de cada subnet
  ([`02` §3](02-redes-vnet-nsg-y-enrutamiento.md#3--subnets-y-direccionamiento)).
- `--default-outbound-access false` hace **privada** la subnet: sus VMs no reciben la IP de salida
  implícita de Azure. Desde el 31 de marzo de 2026 es el valor por defecto de las VNets nuevas
  creadas con las versiones de API posteriores a esa fecha; el lab lo declara igual, porque lo
  explícito sobrevive a los cambios de default y a una CLI antigua.

```bash
az network vnet subnet show --name inv-lab-snet --vnet-name inv-lab-vnet --resource-group inv-lab-rg \
  --query "{prefix:addressPrefix, defaultOutboundAccess:defaultOutboundAccess}"
```

```text
[PENDIENTE DE CORRIDA] {"prefix": "10.20.1.0/24", "defaultOutboundAccess": false}
```

**Teardown:** la VNet, la subnet y el NSG se quedan hasta [`L09`](l09-costos-y-destruccion-verificada.md); no cobran.

---

## 3. 🧱 El NSG: prioridades y service tags

Un NSG es un filtro **stateful** de 5-tupla que se asocia a una subnet o a una NIC
([`02` §4](02-redes-vnet-nsg-y-enrutamiento.md#4--nsg-el-filtro-stateful)). El del lab va en la
subnet, y la VM no tendrá otro en su NIC.

```bash
az network nsg create --name inv-lab-nsg --resource-group inv-lab-rg --location eastus2 \
  --tags project=inv-lab env=lab --output none

az network vnet subnet update --name inv-lab-snet --vnet-name inv-lab-vnet \
  --resource-group inv-lab-rg --network-security-group inv-lab-nsg --output none

az network nsg show --name inv-lab-nsg --resource-group inv-lab-rg \
  --query "defaultSecurityRules[].{name:name, prio:priority, dir:direction, access:access, dst:destinationAddressPrefix}" \
  --output table
```

- Un NSG recién creado **no está vacío**: trae seis reglas por defecto, de prioridad 65000 a 65500,
  que no se pueden borrar. Se ven en `defaultSecurityRules`, no en `securityRules`.
- `az network vnet subnet update --network-security-group` asocia el NSG a la subnet: desde ese
  momento filtra el tráfico de todas sus NICs.

```text
[PENDIENTE DE CORRIDA] Seis reglas: AllowVnetInBound, AllowAzureLoadBalancerInBound y
DenyAllInBound (entrada); AllowVnetOutBound, AllowInternetOutBound y DenyAllOutBound (salida),
con prioridades 65000, 65001 y 65500.
```

Fíjate en `AllowInternetOutBound`, prioridad 65001: **el NSG deja salir a Internet por defecto**. Si la
VM de la sección siguiente no sale, no será por el NSG. Esa es la trampa del diagnóstico de §5.

---

## 4. 🧱 La VM de diagnóstico, sin IP pública

La VM es un instrumento, no una carga: Network Watcher necesita una NIC para IP flow verify y next hop,
y un sistema operativo para preguntarle al DNS desde dentro de la VNet
([`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones)).

**Teardown antes que el despliegue.** Una VM creada con la CLI **se crea por defecto con su disco y su NIC
en modo *detach***: borrar la VM los deja huérfanos, y el disco cobra. (El portal, en cambio, marca por
defecto el disco del sistema para borrarse con la VM.) Los dos flags `--*-delete-option Delete` de abajo hacen que se vayan con
ella. Se destruye en la sección 11, en esta misma sesión.

```bash
az vm create \
  --name inv-lab-vm \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --image Ubuntu2204 \
  --size Standard_B1ls \
  --vnet-name inv-lab-vnet \
  --subnet inv-lab-snet \
  --public-ip-address "" \
  --nsg "" \
  --admin-username azureuser \
  --generate-ssh-keys \
  --storage-sku Standard_LRS \
  --os-disk-delete-option Delete \
  --nic-delete-option Delete \
  --tags project=inv-lab env=lab
```

- `--size Standard_B1ls` es la VM más pequeña: 1 vCPU y 0,5 GiB, $0.0052/h en `eastus2`. Sobra para
  `nslookup` y `curl`.
- `--public-ip-address ""` **no crea IP pública**. Es lo que obliga a operarla con Run Command en vez
  de SSH.
- `--nsg ""` no crea un NSG en la NIC: el filtro es solo el de la subnet, una variable menos.
- `--generate-ssh-keys` usa (o crea) una clave en `~/.ssh`. No se va a usar, porque no hay IP pública,
  pero la VM Linux necesita un método de autenticación.
- `--storage-sku Standard_LRS` pone el disco del sistema en Standard HDD, el más barato.
- `--os-disk-delete-option Delete` y `--nic-delete-option Delete`: al borrar la VM, se borran su disco
  y su NIC.

> ⚠️ **`Ubuntu2204` es un alias de la CLI que resuelve a la versión `latest` de la imagen de Canonical.**
> Es una excepción declarada a la regla de versiones fijas: la VM vive una hora, solo ejecuta
> `nslookup` y `curl`, y su versión de parche no cambia ningún resultado del lab. En una carga real se
> fija la versión exacta, que da `az vm image list --publisher Canonical --all`.

```text
[PENDIENTE DE CORRIDA] JSON con powerState "VM running", privateIpAddress 10.20.1.4 (la primera
IP libre de la subnet) y publicIpAddress vacío.
```

Guarda la IP privada y comprueba el agente de la VM:

```bash
VM_IP=$(az vm show --name inv-lab-vm --resource-group inv-lab-rg --show-details --query privateIps --output tsv)
az vm get-instance-view --name inv-lab-vm --resource-group inv-lab-rg \
  --query "instanceView.vmAgent.{version:vmAgentVersion, status:statuses[0].displayStatus}"
```

- `--show-details` añade a `az vm show` datos que requieren otra llamada, como las IPs.
- El agente de la VM habla con la plataforma por `168.63.129.16`, que se alcanza siempre desde dentro
  de Azure y no depende de ningún método de salida ([`03` §7](03-conectividad-privada-y-dns.md#7--1686312916-el-resolver-de-la-plataforma)).

```text
[PENDIENTE DE CORRIDA] La versión del agente y status "Ready".
```

---

## 5. 🩺 La VM que no contesta

Pregúntale algo a la VM con Run Command:

```bash
az vm run-command invoke \
  --name inv-lab-vm \
  --resource-group inv-lab-rg \
  --command-id RunShellScript \
  --scripts "nslookup invlab472913.blob.core.windows.net; curl -sS -o /dev/null -w '%{http_code}\n' https://invlab472913.blob.core.windows.net/"
```

- `az vm run-command invoke` entrega un script al agente de la VM a través de la plataforma, sin SSH,
  sin puerto de entrada y sin Bastion. `--command-id RunShellScript` ejecuta un script de shell
  arbitrario como root.
- `--scripts` es el script. Aquí, resolver el FQDN de la cuenta y hacer una petición HTTPS a su
  endpoint de blobs.

```text
[PENDIENTE DE CORRIDA] El comando se queda esperando sin devolver la salida del script (o termina
con un error de tiempo agotado). Si en 5 minutos no hay respuesta, córtalo con Ctrl+C.
```

El agente estaba `Ready`. ¿Qué pasa? La
[documentación de Run Command](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/run-command)
lo dice sin rodeos: **necesita salida por el puerto 443 hacia IPs públicas de Azure para devolver el
resultado**; sin ella, el script puede ejecutarse y el resultado no volver. Y un script ya enviado no
se puede cancelar: se ejecuta hasta terminar o hasta los 90 minutos.

Antes de arreglar, se confirma. Tres preguntas, tres comandos de Network Watcher y de la NIC:

**¿Lo bloquea el NSG?**

```bash
STORAGE_IP=$(dig +short invlab472913.blob.core.windows.net | tail -1)
az network watcher test-ip-flow \
  --vm inv-lab-vm --resource-group inv-lab-rg \
  --direction Outbound --protocol TCP \
  --local "$VM_IP:60000" --remote "$STORAGE_IP:443"
```

- `dig +short` resuelve desde **tu portátil**, fuera de la VNet: da la IP pública de la cuenta. El
  `tail -1` se queda con la última línea, la IP, después de los CNAME.
- `test-ip-flow` (IP flow verify) evalúa las reglas efectivas de los NSG para una 5-tupla concreta y
  dice **qué regla** permite o deniega. `--local` es la IP y un puerto de origen de la VM; `--remote`,
  el destino y su puerto.

```text
[PENDIENTE DE CORRIDA] access "Allow", ruleName "defaultSecurityRules/AllowInternetOutBound".
```

**¿Hay ruta?**

```bash
az network watcher show-next-hop --vm inv-lab-vm --resource-group inv-lab-rg \
  --source-ip "$VM_IP" --dest-ip "$STORAGE_IP"
az network nic show-effective-route-table --resource-group inv-lab-rg \
  --name "$(az vm show --name inv-lab-vm --resource-group inv-lab-rg --query 'networkProfile.networkInterfaces[0].id' --output tsv | xargs basename)" \
  --output table
```

- `show-next-hop` dice a dónde mandaría Azure el paquete: `Internet`, `VirtualNetwork`,
  `VirtualAppliance`, `None`…
- `show-effective-route-table` muestra las rutas **efectivas** de la NIC: las del sistema más las UDR y
  las aprendidas. El `xargs basename` extrae el nombre de la NIC de su resource ID.

```text
[PENDIENTE DE CORRIDA] nextHopType "Internet" y, en la tabla, la ruta del sistema 0.0.0.0/0 con
next hop Internet, junto a 10.20.0.0/16 VirtualNetwork.
```

**¿Tiene la subnet un método de salida?**

```bash
az network vnet subnet show --name inv-lab-snet --vnet-name inv-lab-vnet --resource-group inv-lab-rg \
  --query "{defaultOutboundAccess:defaultOutboundAccess, natGateway:natGateway.id}"
```

```text
[PENDIENTE DE CORRIDA] {"defaultOutboundAccess": false, "natGateway": null}
```

Ahí está. El NSG permite, la ruta existe, pero **la subnet es privada y no tiene ningún método de
salida explícito**: nadie traduce la IP privada a una pública. Es la pregunta 13 de
[`02`](02-redes-vnet-nsg-y-enrutamiento.md), vista de verdad:

> Regla de diagnóstico: IP flow verify dice `Allow` y la conexión falla → el NSG no es el problema.
> Mira las rutas efectivas y si la subnet tiene un método de salida.

---

## 6. 💰 NAT Gateway: la salida explícita

El método de salida que recomienda Microsoft es un **NAT Gateway** asociado a la subnet
([`02` §7](02-redes-vnet-nsg-y-enrutamiento.md#7--salida-a-internet)). Es la primera vez que el lab
enciende algo con cargo fijo.

> 💰 **Costo.** El NAT Gateway cuesta **$0.045/h** más el tráfico que procesa, y necesita una IP
> pública Standard a **$0.005/h**. En la hora que vive en este lab, unos cinco centavos. Olvidado, son
> unos $36 al mes.

**Teardown antes que el despliegue:** en la sección 11 se desasocia de la subnet, se borra el NAT
Gateway y después su IP pública, en ese orden: una IP asociada no se puede borrar.

```bash
az network public-ip create --name inv-lab-nat-pip --resource-group inv-lab-rg --location eastus2 \
  --sku Standard --allocation-method Static --tags project=inv-lab env=lab --output none

az network nat gateway create --name inv-lab-nat --resource-group inv-lab-rg --location eastus2 \
  --public-ip-addresses inv-lab-nat-pip --idle-timeout 4 --tags project=inv-lab env=lab --output none

az network vnet subnet update --name inv-lab-snet --vnet-name inv-lab-vnet \
  --resource-group inv-lab-rg --nat-gateway inv-lab-nat --output none
```

- `az network public-ip create --sku Standard --allocation-method Static`: el NAT Gateway solo admite
  IPs Standard estáticas. Una IP Standard es *secure by default* para la entrada, y aquí solo se usa
  para salir.
- `--idle-timeout 4` son los minutos que una conexión TCP inactiva conserva su puerto SNAT. El rango
  va de 4 a 120, y Microsoft desaconseja subirlo: un timeout largo retiene puertos y acerca el
  agotamiento de SNAT.
- `--nat-gateway` en la subnet la asocia: desde ese momento, **toda** la salida a Internet de la
  subnet sale por la IP del NAT, estable y conocida.

Repite el Run Command de la sección 5:

```text
[PENDIENTE DE CORRIDA] La salida del script: nslookup con el CNAME a
invlab472913.privatelink.blob.core.windows.net y una IP pública; y un código HTTP de curl
(400 o similar: la petición anónima llega a Storage y Storage la rechaza, lo que prueba la
conectividad).
```

- El `nslookup` ya muestra el **CNAME a `privatelink`** que Storage publica para cada cuenta, aunque
  todavía no haya private endpoint: la cadena de [`03` §5](03-conectividad-privada-y-dns.md#5--la-resolución-dns-de-un-private-endpoint)
  existe desde que existe la cuenta. Guárdalo para la sección 9.
- Cualquier código HTTP de `curl` significa que hubo conexión TLS con Storage. Un error de conexión o
  de tiempo agotado habría significado lo contrario.

---

## 7. 🩺 El NSG que corta la salida, y el service tag que la devuelve

Ahora que hay salida, restríngela, como haría cualquier equipo de seguridad: nada a Internet.

```bash
az network nsg rule create --nsg-name inv-lab-nsg --resource-group inv-lab-rg \
  --name deny-internet-out --priority 4000 --direction Outbound --access Deny \
  --protocol '*' --destination-address-prefixes Internet --destination-port-ranges '*' \
  --description "L04: sin salida a Internet" --output none
```

- `--priority 4000`: las reglas propias van de 100 a 4096 y se evalúan de menor a mayor número; gana
  la primera que coincide. 4000 va **antes** que `AllowInternetOutBound` (65001), así que la anula.
- `--destination-address-prefixes Internet` usa el **service tag** `Internet`: todo lo que está fuera
  de la VNet y no es de la plataforma, sin escribir un solo prefijo.

Repite el Run Command:

```text
[PENDIENTE DE CORRIDA] Otra vez sin respuesta. Córtalo con Ctrl+C a los 5 minutos.
```

Y confirma con IP flow verify, que ahora nombra la regla culpable:

```bash
az network watcher test-ip-flow --vm inv-lab-vm --resource-group inv-lab-rg \
  --direction Outbound --protocol TCP --local "$VM_IP:60000" --remote "$STORAGE_IP:443"
```

```text
[PENDIENTE DE CORRIDA] access "Deny", ruleName "securityRules/deny-internet-out".
```

La corrección no es borrar la regla, sino abrir **solo** lo que la plataforma necesita. La
documentación de Run Command lo indica: el service tag **`AzureCloud`**, que agrupa las IPs públicas de
Azure.

```bash
az network nsg rule create --nsg-name inv-lab-nsg --resource-group inv-lab-rg \
  --name allow-azurecloud-https-out --priority 3900 --direction Outbound --access Allow \
  --protocol Tcp --destination-address-prefixes AzureCloud --destination-port-ranges 443 \
  --description "L04: Run Command y servicios de Azure por HTTPS" --output none
```

- `--priority 3900` va antes que la denegación de 4000.
- `AzureCloud` es un service tag de Microsoft: sus prefijos cambian solos cuando Azure añade IPs, y tú
  no los mantienes. Admite variantes por región, como `AzureCloud.EastUS2`.
- `--protocol Tcp --destination-port-ranges 443`: solo HTTPS, no todo.

IP flow verify otra vez, y el Run Command:

```text
[PENDIENTE DE CORRIDA] test-ip-flow: access "Allow", ruleName
"securityRules/allow-azurecloud-https-out". Run Command: vuelve a devolver la salida del script.
```

> 🧠 **Modelo mental.** El NSG decide **si** el paquete puede salir; el NAT Gateway decide **por
> dónde** sale. Hacen falta los dos, y cada uno tiene su comando de diagnóstico: IP flow verify para el
> primero, rutas efectivas y la configuración de la subnet para el segundo.

---

## 8. 🧱 El private endpoint de blobs

Ahora el segundo diagnóstico. Un **private endpoint** pone en tu subnet una IP privada que representa a
**una** instancia y **un** subrecurso de un servicio ([`03` §3](03-conectividad-privada-y-dns.md#3--private-endpoints-y-private-link)).

> 💰 **Costo.** $0.01/h por private endpoint, más el tráfico procesado. Una hora de lab, un centavo.

**Teardown antes que el despliegue:** en la sección 11 se borran el private endpoint, su zone group, el
VNet link y la Private DNS zone. La conexión de Private Link que el endpoint crea en la storage account
desaparece con él.

```bash
SA_ID=$(az storage account show --name invlab472913 --resource-group inv-lab-rg --query id --output tsv)

az network private-endpoint create \
  --name inv-lab-pe-blob \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --vnet-name inv-lab-vnet \
  --subnet inv-lab-snet \
  --private-connection-resource-id "$SA_ID" \
  --group-id blob \
  --connection-name inv-lab-pe-blob-conn \
  --tags project=inv-lab env=lab
```

- `--private-connection-resource-id` es el resource ID de la cuenta: la **instancia** concreta, no el
  servicio Storage entero. Por eso un private endpoint protege contra la exfiltración y un service
  endpoint no.
- `--group-id blob` es el **subrecurso**. Si la app usara también colas, haría falta otro private
  endpoint con `queue`, con su propia zona.
- `--connection-name` nombra la conexión de Private Link que queda registrada en la cuenta. Como eres
  Owner de los dos lados, se aprueba sola.
- El private endpoint crea una NIC con una IP de la subnet. No se pasa `--ip-config`: Azure elige la
  primera libre.

```text
[PENDIENTE DE CORRIDA] JSON del private endpoint con provisioningState Succeeded, la conexión en
estado Approved y customDnsConfigs con el FQDN invlab472913.blob.core.windows.net y una IP
10.20.1.x.
```

> 📝 **Contexto.** La storage account la gestiona el Deployment Stack de [`L03`](l03-bicep-desde-la-cli.md) con `denyDelete`, sin
> aplicar el deny a los subrecursos. La conexión de Private Link es un subrecurso de la cuenta, así
> que el stack no impide crearla ni borrarla.

Ahora la zona y el registro, **pero todavía sin VNet link**:

```bash
az network private-dns zone create --name privatelink.blob.core.windows.net \
  --resource-group inv-lab-rg --tags project=inv-lab env=lab --output none

az network private-endpoint dns-zone-group create \
  --endpoint-name inv-lab-pe-blob --resource-group inv-lab-rg \
  --name default --private-dns-zone privatelink.blob.core.windows.net --zone-name blob --output none

az network private-dns record-set a list --zone-name privatelink.blob.core.windows.net \
  --resource-group inv-lab-rg --query "[].{name:name, ip:aRecords[0].ipv4Address}" --output table
```

- La zona se llama **exactamente** `privatelink.blob.core.windows.net`, el nombre recomendado para el
  subrecurso `blob`. Nunca `blob.core.windows.net`: interceptaría la resolución de todas las cuentas de
  Azure para las VNets vinculadas ([`03` §6](03-conectividad-privada-y-dns.md#6--private-dns-zones)).
- El **zone group** conecta el private endpoint con la zona: crea y mantiene solo el registro A
  `invlab472913` con la IP privada del endpoint.
- `record-set a list` confirma que el registro existe en la zona.

```text
[PENDIENTE DE CORRIDA] Una fila: invlab472913 con la IP privada del private endpoint.
```

---

## 9. 🩺 La resolución que falla sin el VNet link

El registro existe. Pregúntale al DNS **desde dentro de la VNet**:

```bash
az vm run-command invoke --name inv-lab-vm --resource-group inv-lab-rg --command-id RunShellScript \
  --scripts "nslookup invlab472913.blob.core.windows.net" --query "value[0].message" --output tsv
```

- `--query "value[0].message"` extrae la salida del script de la respuesta de Run Command, que la
  envuelve en un JSON con `stdout` y `stderr`.

```text
[PENDIENTE DE CORRIDA] El CNAME a invlab472913.privatelink.blob.core.windows.net y una IP
PÚBLICA, la misma que en la sección 6.
```

Es el síntoma de [`03` §11](03-conectividad-privada-y-dns.md#11--diagnóstico-el-nombre-resuelve-a-la-ip-pública):
la zona tiene el registro, pero **la VNet no la consulta**. La VM pregunta a `168.63.129.16`, y ese
resolver solo usa las Private DNS zones **vinculadas a la VNet** desde la que se pregunta. Sin link, la
cadena CNAME sigue por el DNS público y termina en la IP pública.

El orden de revisión de `03` §11, con su comando:

```bash
# 1. ¿la zona tiene el nombre exacto y el registro A?  → sí, sección 8
# 2. ¿está vinculada a ESTA VNet?
az network private-dns link vnet list --zone-name privatelink.blob.core.windows.net \
  --resource-group inv-lab-rg --output table
```

```text
[PENDIENTE DE CORRIDA] Vacío: no hay ningún VNet link.
```

La corrección:

```bash
az network private-dns link vnet create \
  --name inv-lab-vnet-link \
  --resource-group inv-lab-rg \
  --zone-name privatelink.blob.core.windows.net \
  --virtual-network inv-lab-vnet \
  --registration-enabled false \
  --tags project=inv-lab env=lab --output none
```

- `--virtual-network` acepta el nombre (en el mismo grupo) o el resource ID de la VNet.
- `--registration-enabled false`: la zona **no** registra automáticamente las VMs de la VNet. El
  autorregistro es para zonas de nombres de tus propias VMs, no para las de Private Link.

Y la misma pregunta:

```text
[PENDIENTE DE CORRIDA] El CNAME a invlab472913.privatelink.blob.core.windows.net y la IP
PRIVADA 10.20.1.x del private endpoint.
```

> 🧠 **Modelo mental.** La aplicación usa siempre `invlab472913.blob.core.windows.net`, nunca el nombre
> `privatelink`. Es el DNS, a través de la cadena CNAME y de la zona vinculada, el que decide si ese
> nombre es una IP pública o una privada. Por eso el mismo `application.properties` funciona dentro y
> fuera de la VNet, y por eso el fallo es siempre de DNS y nunca de la app.

---

## 10. 🩺 Cerrar el acceso público, y leer el 403 de red

Crear el private endpoint **no cierra** el endpoint público de la cuenta ([`03` §3](03-conectividad-privada-y-dns.md#3--private-endpoints-y-private-link)).
Ciérralo y mira qué ve el mundo exterior, que ahora eres tú desde el portátil:

```bash
az storage account update --name invlab472913 --resource-group inv-lab-rg \
  --public-network-access Disabled --query publicNetworkAccess

az storage blob list --account-name invlab472913 --container-name events-archive \
  --auth-mode login --output table
```

- `--public-network-access Disabled` rechaza todo el tráfico que no llegue por un private endpoint,
  sin excepciones de IP ni de VNet.
- Tu usuario tiene `Storage Blob Data Contributor` en `events-archive` desde [`L02`](l02-entra-id-rbac-y-managed-identities.md): si falla, **no** es
  por permisos.

```text
[PENDIENTE DE CORRIDA] "Disabled", y después un 403 con el código AuthorizationFailure y el mensaje
"This request isn't authorized to perform this operation".
```

Es el tercer código de Storage de [`L02` §5](l02-entra-id-rbac-y-managed-identities.md#5--el-owner-que-no-puede-escribir-un-blob),
el de **red**: `AuthorizationFailure`, no `AuthorizationPermissionMismatch`. Mismo `403`, causa
completamente distinta, y el código es lo único que las separa.

Reabre el acceso público **antes** de destruir el private endpoint: [`L05`](l05-container-apps-revisiones-trafico-y-escala.md)–[`L08`](l08-observabilidad-kql-y-auditoria.md) no tienen VNet y
necesitan la cuenta alcanzable.

```bash
az storage account update --name invlab472913 --resource-group inv-lab-rg \
  --public-network-access Enabled --query publicNetworkAccess
```

```text
[PENDIENTE DE CORRIDA] "Enabled"
```

> ⚠️ **`publicNetworkAccess` no está declarado en `main.bicep`.** Cambiarlo a mano es drift sobre un
> recurso gestionado por el stack. Aquí se devuelve al estado original en la misma sesión; si lo
> dejaras cambiado, el siguiente despliegue del stack podría mantenerlo o devolverlo al valor por
> defecto según cómo trate el provider una propiedad omitida. Un what-if lo diría.

---

## 11. 🧪 Teardown de lo que cobra

En este orden, porque cada paso libera la dependencia del siguiente:

```bash
# 1. la VM, con su disco y su NIC (delete options de la sección 4)
az vm delete --name inv-lab-vm --resource-group inv-lab-rg --yes

# 2. el private endpoint y su DNS
az network private-endpoint delete --name inv-lab-pe-blob --resource-group inv-lab-rg
az network private-dns link vnet delete --name inv-lab-vnet-link --zone-name privatelink.blob.core.windows.net \
  --resource-group inv-lab-rg --yes
az network private-dns zone delete --name privatelink.blob.core.windows.net --resource-group inv-lab-rg --yes

# 3. el NAT Gateway: primero se desasocia, después se borra, y al final su IP
az network vnet subnet update --name inv-lab-snet --vnet-name inv-lab-vnet --resource-group inv-lab-rg \
  --remove natGateway --output none
az network nat gateway delete --name inv-lab-nat --resource-group inv-lab-rg
az network public-ip delete --name inv-lab-nat-pip --resource-group inv-lab-rg

# 4. las reglas propias del NSG, para dejar el NSG como lo encontrará L09
az network nsg rule delete --nsg-name inv-lab-nsg --resource-group inv-lab-rg --name deny-internet-out
az network nsg rule delete --nsg-name inv-lab-nsg --resource-group inv-lab-rg --name allow-azurecloud-https-out
```

- `az vm delete --yes` borra la VM sin confirmación; con las delete options, el disco y la NIC se van
  con ella.
- Una zona con VNet links no se puede borrar: primero el link. El zone group se fue con el private
  endpoint.
- `--remove natGateway` es el argumento genérico de actualización de la CLI: quita la propiedad
  `natGateway` de la subnet. Una IP pública asociada a un NAT Gateway no se puede borrar hasta borrar
  el NAT.

Y la verificación, buscando **huérfanos** además de lo que borraste:

```bash
az resource list --resource-group inv-lab-rg \
  --query "[?contains(type, 'Microsoft.Network') || contains(type, 'Microsoft.Compute')].{name:name, type:type}" \
  --output table
az disk list --resource-group inv-lab-rg --output table
az network public-ip list --resource-group inv-lab-rg --output table
```

```text
[PENDIENTE DE CORRIDA] Solo inv-lab-vnet (virtualNetworks) e inv-lab-nsg
(networkSecurityGroups). Ningún disco, ninguna IP pública, ninguna NIC.
```

> ⚠️ **`NetworkWatcherRG` sigue ahí**, con `NetworkWatcher_eastus2` dentro. No cobra y no es tuyo:
> [`L09`](l09-costos-y-destruccion-verificada.md) decide qué hacer con él. No lo borres a mano a mitad de la serie.

---

## 📋 Checklist de salida

- [ ] `az network vnet subnet show` de `inv-lab-snet` devuelve `defaultOutboundAccess: false` y ningún NAT Gateway.
- [ ] Viste Run Command sin respuesta, y confirmaste con IP flow verify (`Allow`), next hop (`Internet`) y la subnet (sin método de salida) antes de arreglarlo.
- [ ] Viste IP flow verify nombrar `deny-internet-out` y después `allow-azurecloud-https-out`.
- [ ] Viste el FQDN resolver a la IP pública sin VNet link y a la privada con él.
- [ ] Viste el `403 AuthorizationFailure` con el acceso público cerrado, y la cuenta vuelve a estar en `Enabled`.
- [ ] `az resource list` del grupo no muestra VM, disco, NIC, NAT Gateway, IP pública, private endpoint ni Private DNS zone.
- [ ] Sabes que `NetworkWatcherRG` existe y por qué.

## 🏁 La señal de que quedó bien

En `inv-lab-rg` solo quedan de red `inv-lab-vnet` e `inv-lab-nsg` (sin reglas propias),
`az storage account show --name invlab472913 --query publicNetworkAccess` devuelve `Enabled`, y puedes
explicar por qué la VM no contestaba aunque el NSG la dejaba salir.

---

## 🧠 Preguntas rápidas

1. ¿Qué significa `--default-outbound-access false` en una subnet y qué cambió el 31 de marzo de 2026?
2. ¿Por qué la VM de diagnóstico no tiene IP pública y cómo se opera sin SSH ni Bastion?
3. ¿Qué necesita Run Command para devolver el resultado de un script y qué pasa si no lo tiene?
4. IP flow verify devuelve `Allow` y la VM no llega a Storage. ¿Qué dos comprobaciones haces después?
5. ¿Por qué la regla `deny-internet-out` con prioridad 4000 anula `AllowInternetOutBound`?
6. ¿Qué es el service tag `AzureCloud` y por qué es mejor que escribir los prefijos de Azure a mano?
7. ¿Qué hace el NSG y qué hace el NAT Gateway en la salida de una subnet?
8. ¿Por qué borrar una VM puede dejar costos, y qué flags de `az vm create` lo evitan?
9. ¿Qué crea el zone group de un private endpoint y por qué no basta para que la VM resuelva la IP privada?
10. ¿Qué consulta `168.63.129.16` para resolver un nombre de `privatelink` y qué condición debe cumplir la zona?
11. Tu usuario tiene rol de datos y recibe `403 AuthorizationFailure`. ¿Qué pasa y en qué se diferencia de `AuthorizationPermissionMismatch`?
12. ¿Por qué no debes crear una Private DNS zone llamada `blob.core.windows.net`?
13. ¿En qué orden se destruye un NAT Gateway y por qué?
14. ¿Qué deja este lab fuera de `inv-lab-rg` y por qué no lo borras a mano?

---

## 📚 Referencias oficiales

- Crear una VNet (quickstart): https://learn.microsoft.com/en-us/azure/virtual-network/quickstart-create-virtual-network
- Acceso de salida por defecto y subnets privadas: https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access
- Reglas de seguridad de un NSG (reglas por defecto y prioridades): https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview
- Service tags: https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview
- Referencia de `az network nsg rule`: https://learn.microsoft.com/en-us/cli/azure/network/nsg/rule
- Referencia de `az vm create`: https://learn.microsoft.com/en-us/cli/azure/vm
- Buscar imágenes de VM con la CLI: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
- Run Command en VMs Linux: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/run-command
- Network Watcher (habilitación y `NetworkWatcherRG`): https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-create
- IP flow verify: https://learn.microsoft.com/en-us/azure/network-watcher/ip-flow-verify-overview
- Next hop: https://learn.microsoft.com/en-us/azure/network-watcher/next-hop-overview
- Rutas efectivas para diagnosticar enrutamiento: https://learn.microsoft.com/en-us/azure/virtual-network/diagnose-network-routing-problem
- NAT Gateway: https://learn.microsoft.com/en-us/azure/nat-gateway/nat-overview
- Referencia de `az network nat gateway`: https://learn.microsoft.com/en-us/cli/azure/network/nat/gateway
- Private endpoints: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview
- Configuración DNS de los private endpoints: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
- Private DNS zones y VNet links: https://learn.microsoft.com/en-us/azure/dns/private-dns-virtual-network-links
- Referencia de `az network private-endpoint`: https://learn.microsoft.com/en-us/cli/azure/network/private-endpoint
- Errores 403 de Storage: https://learn.microsoft.com/en-us/troubleshoot/azure/azure-storage/blobs/authentication/storage-troubleshoot-403-errors
- Precios de Private Link: https://azure.microsoft.com/en-us/pricing/details/private-link/
- Precios de NAT Gateway: https://azure.microsoft.com/en-us/pricing/details/azure-nat-gateway/
- Precios de Azure DNS: https://azure.microsoft.com/en-us/pricing/details/dns/
- Precios de IPs públicas: https://azure.microsoft.com/en-us/pricing/details/ip-addresses/
