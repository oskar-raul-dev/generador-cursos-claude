# 06 — Cloud DNS, CDN, API management y conectividad híbrida

> **Objetivo:** cerrar el borde de la arquitectura: DNS, CDN, certificados, gestión de APIs y las
> dos formas de conectar una red propia con GCP.
> **Se asume leído:** [`01` — infraestructura global y redes](01-infraestructura-global-y-redes.md).
> **Se toca sobre todo con:** [`01`](01-infraestructura-global-y-redes.md) y
> [`02` — cómputo, contenedores y balanceo](02-computo-contenedores-y-balanceo.md).
> **Dónde se practica:** parcialmente. El laboratorio evita el Application Load Balancer global
> porque un forwarding rule cuesta del orden de $0.025/h —ver
> [`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones)—, así que queda como
> drill opcional; Private Service Connect y Private Google Access se practican en
> [`L04`](l04-red-vpc-firewall-y-diagnostico.md).
> **Vigencia:** 6 de septiembre de 2026.

## 1. 🧭 Fundamentos de DNS

- **DNS**: sistema que traduce nombres legibles (`api.example.com`) a
  direcciones IP.
- **Domain**: el nombre registrado (`example.com`).
- **Hostname**: un nombre específico dentro de un domain
  (`api.example.com`).
- **Resolver**: el componente que consulta la cadena de servidores DNS
  hasta obtener una respuesta.
- **Authoritative DNS**: el servidor que tiene la respuesta definitiva
  para una zona, no una copia cacheada.
- **TTL**: cuánto tiempo puede un resolver cachear una respuesta antes de
  volver a consultarla.

---

# Parte I — Cloud DNS

## 2. 🧱 Managed zones

Una **managed zone** es el contenedor de registros DNS para un dominio
dentro de Cloud DNS.

### Public zones

Responden consultas DNS desde Internet.

### Private zones

Resuelven nombres **solo dentro de las VPC asociadas** — útil para
nombres internos (ej. `db.internal`) que no deben ser resolubles desde
fuera de la organización.

```text
Public zone vs Private zone
```

| | Public zone | Private zone |
|---|---|---|
| Visible desde Internet | ✅ | No |
| Visible solo dentro de VPCs asociadas | No | ✅ |
| Uso típico | Dominio público de la aplicación | Nombres internos, service discovery interno |

## 3. 🧱 Registros

| Tipo | Propósito |
|---|---|
| A | Nombre → dirección IPv4 |
| AAAA | Nombre → dirección IPv6 |
| CNAME | Nombre → otro nombre |
| MX | Servidores de correo del dominio |
| TXT | Datos arbitrarios (verificación de dominio, SPF/DKIM, etc.) |

```text
A vs AAAA
```

## 4. 🧱 Routing policies

| Policy | Comportamiento |
|---|---|
| Simple | Responde siempre el mismo registro (o rota entre varios sin lógica adicional) |
| Weighted round robin | Distribuye respuestas entre varios endpoints según un peso relativo |
| Geolocation | Responde según la ubicación geográfica del origen de la consulta |
| Failover | Responde con el endpoint primario mientras esté sano; conmuta al secundario si falla |

```text
Weighted vs Failover routing policy
Simple vs Geolocation routing policy
```

## 5. 🩺 Health checks en routing policies

> A diferencia de otros proveedores DNS, donde el health check puede ser
> una feature nativa del propio servicio DNS, en Cloud DNS las routing
> policies que necesitan verificar salud (por ejemplo failover) dependen
> de los **health checks de Cloud Load Balancing** asociados a los
> backends, no de un mecanismo de chequeo DNS independiente. Es un matiz
> técnico a tener presente al diseñar failover DNS en GCP, no una
> sobregeneralización que corregir con una advertencia fuerte — es
> simplemente cómo está construido el servicio.

## 6. 🧱 Integración

```text
Cloud DNS
    │
    ├── Cloud Load Balancing
    ├── Cloud CDN
    └── API Gateway
```

---

# Parte II — Cloud CDN y certificados

## 7. 🧱 Cloud CDN

**Cloud CDN** cachea contenido en el edge de Google, integrado con Cloud
Load Balancing.

- **Origin**: el backend service que sirve el contenido original.
- **Cache modes**: controlan qué se cachea (ej. según cache-control del
  origin, o forzando cacheo de contenido estático).
- **TTL**: cuánto tiempo se sirve una respuesta cacheada antes de
  revalidar contra el origin.

```text
Cliente
   │
Edge de Google (Cloud CDN, respuesta cacheada si aplica)
   │  (cache miss)
   ▼
Backend service (origin)
```

## 8. 🧱 Certificados

- **Google-managed SSL certificates**: Google aprovisiona y renueva
  automáticamente certificados TLS para los dominios configurados en
  Cloud Load Balancing.
- **Certificate Manager**: servicio más amplio para administrar
  certificados (managed y self-managed) a mayor escala, con más control
  que la integración básica de certificados administrados de un
  balanceador individual.

```text
Cloud DNS vs Cloud CDN
Cloud Load Balancing vs Cloud CDN
Certificate Manager vs Cloud KMS
```

Cloud DNS resuelve nombres; Cloud CDN cachea contenido en el edge. Cloud
Load Balancing distribuye/balancea tráfico hacia backends; Cloud CDN
cachea las respuestas cacheables de esos mismos backends. Certificate
Manager administra certificados TLS; Cloud KMS administra claves y
operaciones criptográficas de propósito general — no son intercambiables.

---

# Parte III — API Gateway y Apigee

## 9. 🧱 API Gateway

**API Gateway** es serverless, orientado a exponer backends serverless
(Cloud Run, Cloud Functions) como una API administrada.

Capacidades a nivel general:

- integración directa con Cloud Run/Cloud Functions;
- authentication/authorization (API keys, IAM, validación de JWT);
- throttling.

## 10. 🧱 Apigee

**Apigee** es la gestión de APIs a nivel **enterprise**: monetización,
developer portal, analítica avanzada — un escalón superior a API Gateway
en alcance y complejidad, orientado a organizaciones que exponen APIs
como producto hacia terceros.

```text
API Gateway vs Cloud Load Balancing
API Gateway vs Apigee
```

| | API Gateway | Apigee |
|---|---|---|
| Enfoque | API management ligero, serverless | API management enterprise |
| Monetización/developer portal | No | ✅ |
| Uso típico | Exponer un backend serverless como API con auth/throttling básicos | Programa de APIs como producto, con partners externos |

API Gateway no es un sustituto de Cloud Load Balancing: Cloud Load
Balancing distribuye tráfico HTTP(S)/TCP de forma general hacia cualquier
tipo de backend; API Gateway agrega capacidades específicas de gestión de
API (auth, throttling, contratos) sobre backends serverless.

---

# Parte IV — Conectividad híbrida

## 11. 🧱 Cloud VPN

Ver también documento [`01`](01-infraestructura-global-y-redes.md). Como recordatorio en el contexto de
conectividad externa: **Cloud VPN** conecta la VPC con una red externa
mediante túneles IPsec sobre Internet, con la modalidad **HA VPN**
ofreciendo alta disponibilidad mediante múltiples túneles y Cloud Router
con BGP.

## 12. 🧱 Cloud Interconnect

**Cloud Interconnect** (Dedicated o Partner) ofrece conectividad privada
dedicada entre on-premises y la red de Google, sin atravesar Internet
público — mayor throughput y consistencia de latencia que una VPN, a
costa de un aprovisionamiento más lento y, típicamente, mayor
compromiso/costo fijo.

```text
Cloud VPN vs Cloud Interconnect
```

## 13. 🧱 Private Service Connect y DNS privado

Cuando se publica un servicio mediante Private Service Connect (ver
documento [`01`](01-infraestructura-global-y-redes.md)), el endpoint resultante suele resolverse mediante un
registro en una **private zone** de Cloud DNS, de forma que los
consumidores dentro de la VPC lo alcancen por un nombre estable en lugar
de una IP interna memorizada.

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia una public zone de una private zone?
2. ¿Qué diferencia a un registro A de uno AAAA?
3. ¿Weighted routing policy garantiza una distribución exacta por request?
4. ¿De qué depende el health check de una routing policy de failover en Cloud DNS?
5. ¿Qué es el origin en el contexto de Cloud CDN?
6. ¿Cloud CDN reemplaza a Cloud Load Balancing?
7. ¿Qué diferencia a Certificate Manager de Cloud KMS?
8. ¿Qué diferencia a API Gateway de Apigee?
9. ¿API Gateway reemplaza a Cloud Load Balancing?
10. ¿Qué diferencia a Cloud VPN de Cloud Interconnect en cuanto a la ruta que toma el tráfico?
11. ¿Por qué un endpoint de Private Service Connect suele resolverse mediante una private zone?

---

## 📚 Referencias oficiales

- Cloud DNS overview: https://cloud.google.com/dns/docs/overview
- Managed zones: https://cloud.google.com/dns/docs/zones
- Supported record types: https://cloud.google.com/dns/docs/records
- DNS routing policies: https://cloud.google.com/dns/docs/routing-policies
- Cloud CDN overview: https://cloud.google.com/cdn/docs/overview
- Google-managed SSL certificates: https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs
- Certificate Manager overview: https://cloud.google.com/certificate-manager/docs/overview
- API Gateway overview: https://cloud.google.com/api-gateway/docs/about-api-gateway
- Apigee overview: https://cloud.google.com/apigee/docs/api-platform/get-started/what-apigee
- Cloud VPN overview: https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview
- Cloud Interconnect overview: https://cloud.google.com/network-connectivity/docs/interconnect/concepts/overview
- Private Service Connect overview: https://cloud.google.com/vpc/docs/private-service-connect
