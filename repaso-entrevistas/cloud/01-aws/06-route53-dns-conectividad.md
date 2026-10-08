# 06 — Route 53, DNS y conectividad híbrida

> **Objetivo:** explicar cómo llega una petición desde el navegador hasta tu backend,
> con qué política de routing y con qué certificado, y cuándo conviene conectividad privada.
> **Se asume leído:** [`01`](01-infraestructura-global-y-redes.md) y
> [`02`](02-computo-contenedores-y-balanceo.md) (ALB y NLB como targets de un Alias).
> **Se conecta con:** [`11`](11-resiliencia-y-well-architected.md) (failover y DR multi-Region).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Qué hace Route 53](#1--qué-hace-route-53) · [DNS mínimo para entrevista](#2--dns-mínimo-para-entrevista) · [Hosted Zone](#3--hosted-zone) · [Registros esenciales](#4--registros-esenciales) · [Alias Record](#5--alias-record) · [CNAME vs Alias](#6--cname-vs-alias) · [TTL](#7--ttl) · [Simple](#8--simple) · [Weighted](#9--weighted) · [Latency-based](#10--latency-based) · [Failover](#11--failover) · [Geolocation](#12--geolocation) · [Geoproximity](#13--geoproximity) · [IP-based routing](#14--ip-based-routing) · [Multivalue Answer](#15--multivalue-answer) · [Resumen de policies](#16--resumen-de-policies) · [Health Checks](#17--health-checks) · [CloudFront — CDN](#18--cloudfront--cdn) · [ACM — AWS Certificate Manager](#19--acm--aws-certificate-manager) · [Site-to-Site VPN](#20--site-to-site-vpn) · [Direct Connect](#21--direct-connect) · [PrivateLink](#22--privatelink) · [Route 53 + ALB — patrón típico](#23--route-53--alb--patrón-típico) · [Multi-Region conceptual](#24--multi-region-conceptual) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

# Parte I — DNS

## 1. 🧭 Qué hace Route 53

Amazon Route 53 cubre tres áreas principales:

```text
Domain registration
DNS
Health checking
```

En una arquitectura típica:

```text
api.example.com
      │
      ▼
   Route 53
      │
      ▼
      ALB
```

---

## 2. 🧱 DNS mínimo para entrevista

Cuando un cliente solicita:

```text
api.example.com
```

DNS resuelve el nombre hacia un destino apropiado mediante registros.

Conceptos:

- domain;
- hosted zone;
- record;
- TTL;
- recursive resolver;
- authoritative DNS.

Route 53 actúa como authoritative DNS para hosted zones configuradas en él.

---

## 3. 🧱 Hosted Zone

Contenedor de registros DNS para un dominio.

### Public Hosted Zone

Responde DNS público de Internet.

```text
example.com
www.example.com
api.example.com
```

### Private Hosted Zone

DNS privado para VPC asociadas.

Ejemplo:

```text
db.internal.example.com
```

resoluble solo desde las redes/VPC configuradas, según arquitectura.

---

## 4. 🧱 Registros esenciales

### A

Nombre → IPv4.

```text
api.example.com → 203.0.113.10
```

### AAAA

Nombre → IPv6.

### CNAME

Nombre → otro nombre DNS.

```text
www.example.com → app.example.net
```

### MX

Mail exchange.

### TXT

Texto arbitrario, común en verificación de dominio, SPF/DKIM-related configurations, etc.

### NS

Name servers autoritativos de una zone.

### SOA

Metadata administrativa/autoritativa de la zone.

---

## 5. 🧱 Alias Record

Route 53 ofrece **Alias records**, extensión propia de Route 53.

Permiten apuntar a ciertos recursos AWS, por ejemplo según soporte:

- ELB load balancers;
- CloudFront;
- S3 website endpoints;
- otros records Route 53;
- otros recursos compatibles.

Ventaja clásica:

> Un Alias puede existir en el **zone apex** (`example.com`), donde un CNAME estándar no puede utilizarse.

Ejemplo:

```text
example.com
   │ Alias
   ▼
ALB
```

---

## 6. ⚖ CNAME vs Alias

| | CNAME | Route 53 Alias |
|---|---|---|
| Estándar DNS | Sí | extensión Route 53 |
| Apunta a hostname | Sí | a recursos/records compatibles |
| Zone apex | No | Sí en casos soportados |
| Integración AWS | genérica | fuerte |

Para un ALB en Route 53 normalmente pensar primero en **Alias record**, y conviene poder
decir por qué en vez de citarlo como costumbre. Son tres razones concretas.

La primera es el **zone apex**: el estándar DNS no permite un CNAME en la raíz del
dominio, así que `example.com` no puede apuntar por CNAME a nada. Un Alias sí, porque
Route 53 lo resuelve internamente y devuelve directamente la dirección del recurso. La
segunda es que el Alias **sigue al recurso**: si el ALB cambia sus direcciones —y lo hace,
sin avisar— el Alias apunta a lo correcto sin que nadie toque un registro. La tercera es
que las consultas a un Alias hacia un recurso de AWS **no se facturan**, mientras que las
de un CNAME sí.

Hay una cuarta, más sutil pero muy útil, y es que solo un Alias puede usar
`Evaluate Target Health` (§17) para heredar la salud del recurso al que apunta. Un CNAME
no tiene forma de saber si lo que hay al otro lado está vivo.

El CNAME sigue teniendo su lugar: apuntar a un hostname que no es un recurso de AWS —un
SaaS de terceros, un CDN ajeno— en cualquier nombre que no sea el apex.

---

## 7. 🧱 TTL

**Time To Live** determina cuánto puede cachearse una respuesta DNS.

```text
TTL alto
→ menos consultas DNS
→ cambios tardan más en propagarse por caches

TTL bajo
→ más consultas
→ cambios potencialmente visibles antes
```

TTL no es una garantía de que “todo Internet cambia exactamente en N segundos”; existen
caches y resolvers intermedios, y algunos ignoran alegremente lo que les pides. La regla
mental correcta es que el TTL es un **máximo que sugieres**, no un contrato: tu ventana
real de propagación es el TTL más lo que tarde en vaciarse el resolver más terco de la
cadena, y ahí entran también los caches del sistema operativo y de la propia JVM.

La consecuencia operativa es que el TTL se baja **antes**, no durante. Si vas a migrar un
endpoint el jueves, el lunes bajas el TTL a 60 segundos y esperas a que expire el valor
viejo que la gente tiene cacheado; el jueves cambias el registro y la propagación es de
un minuto. Si lo bajas el mismo jueves, los resolvers que cachearon con el TTL de un día
seguirán mandando tráfico al sitio viejo durante un día entero — y esa es la razón por la
que un cutover "que iba a ser inmediato" se convierte en un incidente de veinticuatro
horas. Cuando termine la migración, se vuelve a subir: un TTL de 60 segundos permanente
es consultas de más y una dependencia innecesaria de que Route 53 responda.

---

# Parte II — Routing Policies

## 8. 🧱 Simple

Para un recurso o respuesta sencilla.

```text
api.example.com → ALB
```

---

## 9. 🧱 Weighted

Distribuye respuestas según pesos relativos.

```text
Version A → weight 90
Version B → weight 10
```

Casos:

- canary;
- migración;
- A/B controlado a nivel DNS.

No implica que exactamente cada grupo de 100 requests tenga una distribución 90/10; DNS y caching afectan el comportamiento observado.

---

## 10. 🧱 Latency-based

Route 53 selecciona el endpoint/Region que ofrece menor latencia estimada para el origen de la consulta según su modelo de latencia.

```text
User EU → eu-west-1
User US → us-east-1
```

No es lo mismo que geolocation.

---

## 11. 🧱 Failover

Active/passive.

```text
Primary
   │ health
   ├── healthy → responde Primary
   └── failed  → responde Secondary
```

Asociado con health checks/evaluate target health según tipo de record.

---

## 12. 🧱 Geolocation

Routing basado en la ubicación geográfica del usuario/consulta según categorías soportadas.

Caso:

- requisitos de contenido regional;
- localización;
- políticas específicas por país/continente.

No confundir con “menor latencia”.

---

## 13. 🧱 Geoproximity

Considera ubicación de recursos y usuarios y permite aplicar **bias** para ampliar/reducir el área de tráfico dirigida a un recurso.

Es más avanzado que geolocation.

---

## 14. 🧱 IP-based routing

Permite definir routing en función de CIDR blocks de origen configurados.

Útil cuando controlas/identificas rangos de clientes y quieres respuestas específicas por origen.

---

## 15. 🧱 Multivalue Answer

Puede devolver múltiples valores saludables para un nombre. No es un sustituto completo de un load balancer Layer 7; es routing DNS con múltiples respuestas y health checking.

---

## 16. ⚖ Resumen de policies

| Policy | Pregunta que responde |
|---|---|
| Simple | ¿A qué recurso normal envío? |
| Weighted | ¿Qué porcentaje relativo va a cada destino? |
| Latency | ¿Qué destino tiene menor latencia estimada? |
| Failover | ¿Primary está sano? Si no, ¿Secondary? |
| Geolocation | ¿Dónde está geográficamente el usuario? |
| Geoproximity | ¿Qué recurso cercano y con qué bias? |
| IP-based | ¿De qué CIDR/origen viene? |
| Multivalue | ¿Qué conjunto de respuestas saludables retorno? |

---

## 17. 🧪 Health Checks

Route 53 puede monitorizar endpoints y utilizar salud para DNS failover/routing.

Puede monitorizar:

- endpoint por IP/domain;
- estado de otros health checks;
- CloudWatch alarm según configuración.

Para Alias hacia ciertos recursos AWS existe **Evaluate Target Health**, que permite utilizar la salud del recurso target en lugar de mantener un health check duplicado en algunos casos.

Importante:

> Route 53 no ejecuta el health check “cuando llega cada DNS query”. Los checks se hacen
> periódicamente y Route 53 usa su estado actual.

De esa frase sale la cuenta que hay que saber hacer, porque es la que define el RTO real
de un failover por DNS. El tiempo hasta que un cliente deja de ir al endpoint caído es la
suma de tres cosas: lo que tarda el health check en declarar el fallo (intervalo por
número de comprobaciones fallidas consecutivas), más el TTL del registro, más lo que
tarde en expirar el caché del cliente. Con un TTL de 300 segundos, el failover más
diligente del mundo sigue dejando usuarios en el sitio muerto durante cinco minutos.

Por eso los registros que participan en un failover llevan TTL corto por diseño, y por
eso el DNS es un mecanismo de conmutación **de minutos**, no de segundos: si el requisito
es más agresivo, la respuesta ya no es Route 53 sino un balanceador delante de los dos
destinos.

> 💡 **Truco.** `Evaluate Target Health` sobre un Alias evita mantener —y pagar— un health
> check duplicado, y además hereda la salud que el propio ALB ya calcula sobre sus
> targets. Cuando el destino es un recurso AWS, suele ser la opción correcta.

---

# Parte III — Edge y TLS

## 18. 🧱 CloudFront — CDN

Amazon CloudFront es la CDN de AWS. Distribuye contenido a través de una red global de edge locations y puede cachear respuestas cerca del usuario.

Modelo:

```text
User
 │
 ▼
CloudFront edge
 │ cache miss
 ▼
Origin
 ├── S3
 ├── ALB
 └── otro HTTP origin compatible
```

Conceptos:

- **distribution**: configuración CloudFront;
- **origin**: backend desde donde obtiene contenido;
- **cache behavior**: reglas por path/patrón;
- **TTL/cache key**: qué se cachea y por cuánto tiempo;
- **invalidation**: forzar expiración de objetos cacheados cuando sea necesario.

Route 53 puede usar Alias para dirigir un nombre a una distribución CloudFront compatible.

### CloudFront vs Route 53 vs ALB

```text
Route 53  → DNS: ¿a qué endpoint va el nombre?
CloudFront→ CDN/edge/cache: ¿puedo responder cerca del usuario?
ALB       → L7 origin balancing: ¿a qué target backend envío la request?
```

---

## 19. 🧱 ACM — AWS Certificate Manager

ACM administra certificados TLS para integraciones AWS soportadas, por ejemplo ALB y CloudFront.

Patrón:

```text
api.example.com
   │ DNS Route 53
   ▼
ALB :443
   │ certificate from ACM
   ▼
backend
```

Conceptos de entrevista:

- TLS certificate;
- domain validation, frecuentemente DNS validation;
- renovación administrada para certificados públicos elegibles cuando las condiciones se mantienen;
- el certificado debe estar en la Region que exige el servicio que lo consume. Para un ALB, la misma Region del balanceador; para **CloudFront, obligatoriamente `us-east-1`**, sin importar dónde estén los orígenes. Es la causa número uno de "pedí el certificado y CloudFront no me lo deja seleccionar".

ACM no sustituye KMS: uno gestiona certificados TLS; KMS gestiona claves criptográficas/operaciones de cifrado.

---

# Parte IV — Conectividad híbrida y privada

## 20. 🧱 Site-to-Site VPN

Conecta una red externa con AWS mediante túneles IPsec.

```text
On-prem
   │
Internet
   │
IPsec VPN
   │
   ▼
AWS VPC/TGW
```

Una conexión Site-to-Site VPN AWS normalmente proporciona dos túneles para redundancia.

---

## 21. 🧱 Direct Connect

Conexión dedicada hacia AWS mediante conectividad física/partner correspondiente.

Mentalidad:

```text
VPN            → encrypted tunnels over network/Internet path
Direct Connect → dedicated private connectivity path
```

Direct Connect no significa automáticamente “cifrado IPsec”; si necesitas cifrado debes diseñarlo explícitamente según la solución.

---

## 22. 🧱 PrivateLink

Permite consumir servicios/recursos a través de conectividad privada y endpoints sin exposición pública directa.

Modelo:

```text
Consumer VPC
   │
Interface Endpoint
   │
AWS PrivateLink
   │
Provider service
```

Útil para:

- private APIs/services;
- SaaS privado;
- cross-account service exposure;
- acceso privado a muchos AWS services.

---

## 23. 🧭 Route 53 + ALB — patrón típico

```text
api.example.com
      │
      ▼
Route 53 Alias
      │
      ▼
     ALB
      │
      ▼
Target Group
      │
      ▼
ECS/EC2
```

DNS decide **qué endpoint** devolver; el ALB hace balanceo **request-by-request** Layer 7 hacia targets saludables.

No confundir ambos niveles.

---

## 24. 🧭 Multi-Region conceptual

```text
             Route 53
           /          \
          /            \
   us-east-1         eu-west-1
      ALB               ALB
       │                 │
      App               App
```

Puedes combinar routing policies con health checking para latency/failover según arquitectura.

El reto real suele estar en:

- replicación de datos;
- consistencia;
- sesiones;
- failover state;
- DNS caching;
- RTO/RPO;
- costo.

Route 53 no resuelve por sí solo la replicación de datos multi-Region.

---

## 🧠 Preguntas rápidas

1. ¿Public vs Private Hosted Zone?
2. ¿A vs AAAA?
3. ¿CNAME vs Alias?
4. ¿Por qué Alias es útil en zone apex?
5. ¿Weighted garantiza exactamente 90/10 por requests?
6. ¿Latency vs Geolocation?
7. ¿Qué patrón implementa la routing policy Failover?
8. ¿Qué hace Evaluate Target Health?
9. ¿Route 53 reemplaza un ALB?
10. ¿CloudFront vs ALB?
11. ¿ACM vs KMS?
12. ¿VPN vs Direct Connect?
13. ¿Qué problema resuelve PrivateLink?
14. ¿Route 53 replica tu DB multi-Region?

---

## 📚 Referencias oficiales

- Route 53: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html
- Routing resources: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-routing-traffic-to-resources.html
- Routing policies: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html
- Alias vs non-alias: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html
- Route 53 concepts/health: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-concepts.html
- Site-to-Site VPN: https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html
- Direct Connect: https://docs.aws.amazon.com/directconnect/latest/UserGuide/Welcome.html
- PrivateLink: https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html
- CloudFront: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Introduction.html
- ACM: https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html
- Trabajar con hosted zones: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-working-with.html
- Tipos de registro DNS soportados: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/ResourceRecordTypes.html
- Failover con Route 53: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html
- Valores de un health check: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-values.html
- Distribuciones de CloudFront: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-working-with.html
- Servicios integrados con ACM (y por qué CloudFront exige `us-east-1`): https://docs.aws.amazon.com/acm/latest/userguide/acm-services.html
