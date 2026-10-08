# 01 — Infraestructura global y redes AWS

> **Objetivo:** poder dibujar una VPC en una pizarra y defender cada decisión: por qué
> esa subnet es pública, por qué ese tráfico sale por ahí y qué firewall lo filtra.
> **Se asume leído:** nada. Este es el primer documento del curso.
> **Se conecta con:** [`02`](02-computo-contenedores-y-balanceo.md) (qué corre dentro
> de estas subnets) y [`06`](06-route53-dns-conectividad.md) (cómo se llega desde fuera).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Jerarquía mental](#1--jerarquía-mental) · [Region](#2--region) · [Availability Zone — AZ](#3--availability-zone--az) · [VPC — Virtual Private Cloud](#4--vpc--virtual-private-cloud) · [CIDR](#5--cidr) · [Subnet](#6--subnet) · [Route Table](#7--route-table) · [Public, private e isolated subnet](#8--public-private-e-isolated-subnet) · [Internet Gateway — IGW](#9--internet-gateway--igw) · [Public IPv4, private IPv4 y Elastic IP](#10--public-ipv4-private-ipv4-y-elastic-ip) · [ENI — Elastic Network Interface](#11--eni--elastic-network-interface) · [NAT Gateway](#12--nat-gateway) · [Security Group — SG](#13--security-group--sg) · [Network ACL — NACL](#14--network-acl--nacl) · [SG vs NACL](#15--sg-vs-nacl) · [VPC Endpoints](#16--vpc-endpoints) · [VPC Peering](#17--vpc-peering) · [Transit Gateway — TGW](#18--transit-gateway--tgw) · [IPv6 y Egress-Only Internet Gateway](#19--ipv6-y-egress-only-internet-gateway) · [Troubleshooting de red](#20--troubleshooting-de-red) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

## 1. 🧭 Jerarquía mental

```text
AWS
└── Region
    └── VPC                     ← regional
        ├── AZ-a
        │   ├── Public Subnet   ← zonal
        │   └── Private Subnet
        ├── AZ-b
        │   ├── Public Subnet
        │   └── Private Subnet
        ├── Route Tables
        ├── Security Groups
        ├── NACLs
        ├── Internet Gateway
        ├── NAT Gateway
        └── VPC Endpoints
```

---

## 2. 🧱 Region

Una **AWS Region** es un área geográfica independiente donde AWS opera infraestructura.

Ejemplos:

```text
us-east-1      N. Virginia
us-east-2      Ohio
us-west-2      Oregon
eu-west-1      Ireland
eu-central-1   Frankfurt
sa-east-1      São Paulo
```

### Selección de Region

Considera:

- cercanía a usuarios y latencia;
- disponibilidad del servicio o feature requerido;
- requisitos regulatorios/residencia de datos;
- costo;
- estrategia de disaster recovery.

### Regla de entrevista

```text
Region ≠ datacenter
Region contiene múltiples Availability Zones.
```

---

## 3. 🧱 Availability Zone — AZ

Una **Availability Zone** es una ubicación aislada dentro de una Region. Cada Region AWS tiene al menos tres AZ según la documentación global actual.

```text
us-east-2
├── us-east-2a
├── us-east-2b
└── us-east-2c
```

### Objetivo

```text
AZ = failure isolation boundary
```

Un diseño altamente disponible suele distribuir workloads entre varias AZ:

```text
             ALB
          /       \
       AZ-a       AZ-b
        │           │
      App         App
        \           /
         \         /
          RDS Multi-AZ
```

### AZ name vs AZ ID

Los nombres tipo `us-east-1a` tuvieron históricamente mapping específico por cuenta en Regions antiguas. Un AZ ID como `use1-az1` identifica de forma estable la ubicación física. AWS cambió el comportamiento para cuentas nuevas desde noviembre de 2025 en Regions antiguas, pero el concepto de AZ ID sigue siendo importante para coordinación entre cuentas.

---

## 4. 🧱 VPC — Virtual Private Cloud

Una **VPC** es una red virtual lógicamente aislada.

Características base:

- pertenece a una sola Region;
- puede abarcar varias AZ de esa Region;
- tiene uno o más rangos CIDR;
- contiene subnets;
- define routing y conectividad;
- Security Groups y NACL controlan tráfico en distintos niveles.

Ejemplo:

```text
VPC: 10.0.0.0/16
```

---

## 5. 🧱 CIDR

Ejemplo:

```text
10.0.0.0/16
```

Tabla mental IPv4:

| CIDR | Direcciones matemáticas |
|---:|---:|
| `/16` | 65.536 |
| `/20` | 4.096 |
| `/24` | 256 |
| `/28` | 16 |
| `/32` | 1 |

Evita rangos superpuestos si en el futuro vas a conectar VPC mediante peering/TGW/VPN.

---

## 6. 🧱 Subnet

Una **subnet** es un rango de direcciones IP dentro de una VPC.

Regla esencial:

> Una subnet pertenece a **una sola Availability Zone**.

Ejemplo:

```text
VPC 10.0.0.0/16

AZ-a
├── 10.0.1.0/24  public-a
└── 10.0.2.0/24  app-a

AZ-b
├── 10.0.3.0/24  public-b
└── 10.0.4.0/24  app-b
```

### IPv4 reservadas

En una subnet IPv4 AWS reserva cinco direcciones. Para `10.0.1.0/24`:

```text
10.0.1.0    network address
10.0.1.1    VPC router
10.0.1.2    DNS
10.0.1.3    reservado
10.0.1.255  network broadcast address reservado
```

---

## 7. 🧱 Route Table

Una route table contiene reglas:

```text
Destination → Target
```

Ejemplo:

```text
10.0.0.0/16  → local
0.0.0.0/0    → igw-123
```

AWS selecciona normalmente la ruta con el prefijo más específico: **longest prefix match**.

### `local`

La ruta `local` permite comunicación dentro de la VPC entre rangos pertenecientes a ella, siempre sujeta a controles de seguridad.

### Main y custom route tables

- La VPC tiene una **main route table**.
- Una subnet sin asociación explícita utiliza la main.
- Es normal crear custom route tables separadas.

Ejemplo:

```text
Public RT:
10.0.0.0/16 → local
0.0.0.0/0   → IGW

Private RT:
10.0.0.0/16 → local
0.0.0.0/0   → NAT

DB RT:
10.0.0.0/16 → local
```

---

## 8. 🧱 Public, private e isolated subnet

### Public subnet

Operativamente, una subnet es pública cuando su route table tiene ruta hacia un **Internet Gateway**.

```text
0.0.0.0/0 → IGW
```

Pero para que una EC2 sea alcanzable por IPv4 desde Internet también necesita, entre otras cosas:

- public IPv4 o Elastic IP;
- Security Group compatible;
- NACL compatible;
- servicio escuchando.

### Private subnet

No tiene ruta directa a IGW. Puede salir a Internet mediante NAT.

### Isolated subnet

No tiene ruta por defecto ni a IGW ni a NAT. Es frecuente para capas de datos que no necesitan egress público.

---

## 9. 🧱 Internet Gateway — IGW

El **Internet Gateway** conecta una VPC con Internet.

```text
Internet
   │
   ▼
  IGW
   │
   ▼
  VPC
```

Se adjunta a la VPC, no “dentro” de una subnet. Las route tables determinan qué subnets lo utilizan.

---

## 10. 🧱 Public IPv4, private IPv4 y Elastic IP

### Private IPv4

Dirección utilizada dentro de VPC/redes conectadas.

### Public IPv4

Dirección pública que puede mapearse a una private IPv4 mediante el IGW.

### Elastic IP — EIP

Public IPv4 estática asignable a recursos compatibles.

Regla:

```text
Public IPv4 normal → pública, ciclo de vida asociado al recurso
Elastic IP         → pública y estable hasta liberarla
```

---

## 11. 🧱 ENI — Elastic Network Interface

Una **ENI** es una tarjeta de red virtual.

Puede incluir:

- primary/secondary private IPs;
- IPv6;
- MAC address;
- Security Groups;
- otros atributos de red.

Modelo:

```text
EC2
└── ENI
    ├── private IP
    ├── public mapping
    └── Security Groups
```

---

## 12. 🧱 NAT Gateway

Problema:

```text
Private EC2 → necesita descargar paquetes o llamar API externa
```

Solución típica IPv4:

```text
Private subnet
    │
    ▼
NAT Gateway
    │
    ▼
Internet Gateway
    │
    ▼
Internet
```

El workload privado inicia conexiones hacia fuera, pero Internet no inicia una conexión directa de retorno como si el workload fuera público.

> 💰 **Costo.** El NAT Gateway cuesta $0.045/h más $0.045 por GB procesado, y cobra
> exista o no tráfico. Es la trampa de costo número uno de una cuenta de práctica: el
> catálogo completo está en [`A02` §3](a02-costos-trampas-y-recursos-huerfanos.md#3--lo-que-cobra-por-hora)
> y la razón por la que el laboratorio lo evita en vez de enseñarlo, en
> [`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones).

### NAT Gateway zonal

El modelo tradicional se crea en una AZ. Para resiliencia multi-AZ se suele desplegar un NAT por AZ y enrutar cada subnet privada al NAT de su AZ.

### Regional NAT Gateway

AWS documenta actualmente una modalidad **Regional NAT Gateway**, diseñada para expandirse automáticamente entre AZ y simplificar la alta disponibilidad. En entrevistas conviene distinguirla del modelo zonal clásico porque muchas preguntas y arquitecturas históricas asumen NAT zonal.

---

## 13. 🧱 Security Group — SG

Un **Security Group** es un firewall virtual **stateful** asociado a interfaces/recursos.

Características:

```text
ALLOW rules        ✅
explicit DENY      ❌
stateful            ✅
```

### Ejemplo

SG del ALB:

```text
Inbound:
TCP 443 ← 0.0.0.0/0
```

SG de aplicación:

```text
Inbound:
TCP 8080 ← SG-ALB
```

SG de DB:

```text
Inbound:
TCP 5432 ← SG-APP
```

Mejor que abrir PostgreSQL a una red enorme o a Internet.

### Stateful

Si una conexión permitida entra:

```text
Client → EC2:443
```

el tráfico de respuesta de esa conexión se permite sin tener que crear la regla inversa equivalente.

### Múltiples SG

Si un recurso tiene varios Security Groups, las reglas permitidas se agregan.

---

## 14. 🧱 Network ACL — NACL

Una **NACL** controla tráfico a nivel de subnet.

Características:

```text
ALLOW           ✅
DENY            ✅
stateful        ❌
stateless       ✅
```

Las reglas se evalúan por número de menor a mayor y la primera coincidencia determina el resultado.

Ejemplo:

```text
100 DENY  203.0.113.4/32
200 ALLOW 0.0.0.0/0
```

Como es stateless debes considerar tráfico inbound y outbound, incluidos puertos efímeros cuando corresponda.

---

## 15. ⚖ SG vs NACL

| Característica | Security Group | NACL |
|---|---|---|
| Nivel | ENI/recurso | Subnet |
| Stateful | Sí | No |
| Allow | Sí | Sí |
| Deny explícito | No | Sí |
| Orden de reglas | No funciona por “primera regla” | Sí |
| Uso normal | control fino workload | guardrail de red |

Mnemotecnia:

```text
SG   → workload/server
NACL → subnet/network
```

La tabla se memoriza en un minuto; lo que se pregunta en entrevista es la consecuencia
de esas diferencias. Como el Security Group es stateful, describes la intención —"la
app habla con la base"— y AWS se encarga del tráfico de vuelta; como la NACL es
stateless, cada regla que escribas cubre un solo sentido, y si olvidas el rango de
puertos efímeros en el sentido contrario la conexión se corta a mitad sin que ninguna
regla diga "deny". Ese es el error que más tiempo cuesta diagnosticar de los dos.

Y como el SG no tiene deny explícito, no puedes usarlo para bloquear a alguien: solo
para no invitarlo. Esa es exactamente la razón de que la NACL siga existiendo. Cuando
necesitas prohibir —una IP que está atacando, un rango que por política no puede
entrar a la subnet de datos— el SG no tiene con qué expresarlo, y ahí es donde entra el
guardrail de subnet.

> 🧠 **Modelo mental.** El Security Group es la puerta de tu casa: decides a quién le
> abres. La NACL es el control de acceso del edificio: puede tener una lista de
> vetados, y se aplica a todos los pisos por igual.

En la práctica, el 95 % del control de acceso de una arquitectura vive en Security
Groups encadenados por referencia (`SG-ALB` → `SG-App` → `SG-DB`, como en §13), y la
NACL se deja en su configuración por defecto salvo que exista un requisito concreto de
bloqueo. Responder "uso NACLs para segurizar mis workloads" es la señal de que alguien
invirtió las dos capas.

---

## 16. 🧱 VPC Endpoints

Una app en subnet privada necesita escribir en S3. Sin nada más, ese tráfico sale por
el NAT Gateway, viaja hasta el endpoint público de S3 y vuelve — y pagas $0.045 por
cada GB que atraviesa el NAT, además de su hora encendida, para hablar con un servicio
que está dentro de la misma Region que tú. Los **VPC Endpoints** existen para quitar
ese rodeo: alcanzar el servicio por la red de AWS, sin pasar por Internet ni por el NAT.

Hay dos tipos, y la diferencia entre ellos es de mecanismo y de precio.

### Gateway Endpoint

Solo existe para dos servicios, **S3 y DynamoDB**, y no se cobra.

```text
Private App → Gateway Endpoint → S3
```

No es un recurso que viva en una subnet: se integra añadiendo una ruta a la route
table, con el servicio como destino. Por eso no tiene ENI, no tiene IP y no cuesta
nada — y por eso, cuando el destino es S3 o DynamoDB, no hay ninguna razón para no
usarlo.

### Interface Endpoint

Para todo lo demás. Utiliza AWS PrivateLink y crea ENIs privadas en las subnets que
elijas, con una IP privada por AZ que resuelve al servicio.

```text
Private App
    │
    ▼
Interface Endpoint ENI
    │
    ▼
AWS service/private service
```

> 💰 **Costo.** A diferencia del Gateway, el Interface endpoint cobra por hora **y por
> AZ** (~$0.01/h cada uno) más el tráfico procesado. Tres endpoints desplegados en dos
> AZ son del orden de $44 al mes, así que la comparación real no es "endpoint contra
> NAT" sino cuántos endpoints necesitas: con uno o dos suele ganar el endpoint, con
> diez puede ganar el NAT. El desglose está en
> [`A02` §3](a02-costos-trampas-y-recursos-huerfanos.md#3--lo-que-cobra-por-hora).

Hay además un argumento que no es económico y que en una entrevista de seguridad pesa
más: con endpoints puedes quitar la ruta a Internet por completo y restringir el acceso
al bucket a ese endpoint concreto mediante política. El tráfico no es que esté cifrado
al salir a Internet, es que no sale.

---

## 17. 🧱 VPC Peering

Conecta dos VPC mediante direccionamiento privado.

```text
VPC-A ←→ VPC-B
```

Reglas importantes:

- puede ser same-account o cross-account;
- puede ser inter-Region;
- requiere routing;
- no admite CIDR superpuestos;
- **no es transitivo**.

Las dos últimas son las que deciden diseños. Que **no admita CIDR superpuestos** es la
razón por la que el reparto de rangos se planifica antes de crear la primera VPC: dos
equipos que eligieron `10.0.0.0/16` por defecto, cada uno en su cuenta, no van a poder
conectar sus VPC nunca, y arreglarlo significa volver a direccionar una red viva.

Que **no sea transitivo** significa que el peering no propaga rutas de terceros:

```text
B ←→ A ←→ C
```

no implica:

```text
B ←→ C
```

Aunque A esté conectada con las dos, B y C no se ven, y no hay ruta que puedas escribir
para arreglarlo — la restricción es del servicio, no del routing. La consecuencia
práctica es aritmética: conectar todas las VPC entre sí exige una conexión por cada
par, o sea `n(n-1)/2`. Con cuatro VPC son seis conexiones y se lleva; con diez son
cuarenta y cinco, cada una con sus entradas de route table en ambos extremos, y ahí es
donde el modelo se rompe.

---

## 18. 🧱 Transit Gateway — TGW

Ese es exactamente el problema que resuelve el **Transit Gateway**: un hub administrado
al que cada VPC se conecta una sola vez, y que sí enruta entre sus adjuntos.

```text
       VPC-A
         │
VPC-B ─ TGW ─ VPC-C
         │
      on-prem
```

Las cuarenta y cinco conexiones del ejemplo anterior se convierten en diez, y añadir la
VPC número once cuesta un adjunto en vez de otras diez conexiones. Además admite en el
mismo hub lo que el peering no puede: VPN site-to-site y Direct Connect, que es como se
integra la red on-premises sin montarle un peering a cada VPC.

Regla mental:

```text
Peering → conexión directa uno-a-uno
TGW     → hub-and-spoke a escala
```

> 💰 **Costo.** El TGW no es gratis como el peering: cobra por hora y por cada adjunto,
> más el tráfico procesado. Con dos o tres VPC el peering sigue siendo la respuesta
> correcta y más barata; el TGW se justifica cuando el número de conexiones —o la
> necesidad de meter on-premises en la misma topología— empieza a crecer.

---

## 19. 🧱 IPv6 y Egress-Only Internet Gateway

IPv6 no utiliza NAT44 como IPv4.

Para workloads IPv6 que deben iniciar conexiones salientes pero no aceptar conexiones iniciadas desde Internet se puede utilizar un **Egress-Only Internet Gateway**.

```text
IPv4 private egress → NAT
IPv6 outbound-only  → Egress-only IGW
```

---

## 20. 🩺 Troubleshooting de red

Orden mental:

```text
1. DNS correcto
2. IP correcta
3. Route table correcta
4. gateway/peering/TGW/endpoint correcto
5. NACL permite
6. Security Group permite
7. listener/target/puerto correcto
8. proceso realmente escucha
```

Herramientas, ambas desarrolladas en [`08`](08-observabilidad-auditoria-gobierno.md):

- **VPC Flow Logs**: registros de tráfico IP de interfaces.
- **Reachability Analyzer**: análisis estático del path de red y bloqueos de configuración.

---

## 🧠 Preguntas rápidas

1. ¿VPC es regional o zonal?
2. ¿Subnet puede abarcar dos AZ?
3. ¿Qué hace realmente pública a una subnet?
4. ¿Public subnet garantiza que una EC2 sea alcanzable desde Internet?
5. ¿SG tiene reglas DENY?
6. ¿Por qué SG es stateful y NACL stateless?
7. ¿VPC Peering es transitivo?
8. ¿Qué problema resuelve Transit Gateway?
9. ¿Cuándo usarías VPC Endpoint en lugar de NAT?
10. ¿Cómo depurarías una conexión EC2 → RDS que falla?

---

## 📚 Referencias oficiales

- Regions/AZ: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-regions-availability-zones.html
- VPC: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
- Subnets: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-subnet-basics.html
- Route tables: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html
- Internet Gateway: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
- NAT Gateway: https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-basics.html
- Security Groups: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html
- NACL: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html
- VPC Endpoints/PrivateLink: https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html
- VPC Peering: https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html
- Reachability Analyzer: https://docs.aws.amazon.com/vpc/latest/reachability/what-is-reachability-analyzer.html
- Dimensionar subnets y CIDR: https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html
- Elastic IP: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
- ENI — Elastic Network Interface: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html
- Transit Gateway: https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html
- Egress-Only Internet Gateway: https://docs.aws.amazon.com/vpc/latest/userguide/egress-only-internet-gateway.html
- Gateway endpoints (S3 y DynamoDB): https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html
- AZ ID frente a nombre de AZ: https://docs.aws.amazon.com/ram/latest/userguide/working-with-az-ids.html
- VPC Flow Logs: https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html
