# 05 — Balanceo, entrega global y API Management

> **Objetivo:** poner el tráfico correcto delante de una aplicación: Load Balancer, Application
> Gateway, Front Door y Traffic Manager, y API Management como capa de gestión de APIs.
> **Se asume leído:** [`02` — redes](02-redes-vnet-nsg-y-enrutamiento.md) y
> [`04` — cómputo](04-computo-y-contenedores.md).
> **Se toca más con:** [`04`](04-computo-y-contenedores.md), cuyas plataformas quedan detrás de estos
> productos, y el [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md) (identidad de aplicaciones), que valida tokens en la API y en el
> borde.
> **Se practica en:** ningún lab del tronco. El ingress de Container Apps cubre lo que necesita el
> sistema del laboratorio; los drills de Application Gateway y de API Management Consumption están en
> [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales).
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [Cuatro productos](#1--cuatro-productos-dos-preguntas) ·
[Load Balancer](#2--azure-load-balancer) · [Application Gateway](#3--application-gateway) ·
[Front Door](#4--front-door) · [Traffic Manager](#5--traffic-manager) ·
[⚖ Matriz](#6--la-matriz-de-decisión) · [API Management](#7--api-management) ·
[Políticas](#8--políticas-de-api-management) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Cuatro productos, dos preguntas

Azure tiene cuatro productos para repartir tráfico y la entrevista casi siempre pide elegir uno. La
elección sale de responder dos preguntas, en este orden:

1. **¿En qué capa decides?** En capa 4 (IP y puerto: no miras dentro del paquete) o en capa 7
   (HTTP: rutas, cabeceras, cookies, TLS).
2. **¿Con qué alcance?** Regional (dentro de una región) o global (entre regiones, desde el borde de
   la red de Microsoft más cercano al usuario).

```text
                    Regional                    Global
              ┌──────────────────────┬──────────────────────────┐
  Capa 4      │  Load Balancer       │  Load Balancer (tier     │
  (TCP/UDP)   │                      │  global, cross-region)   │
              ├──────────────────────┼──────────────────────────┤
  Capa 7      │  Application Gateway │  Front Door              │
  (HTTP/S)    │  (+ WAF)             │  (+ WAF, caché)          │
              └──────────────────────┴──────────────────────────┘
  Por DNS, fuera de la tabla: Traffic Manager (no toca los paquetes)
```

Traffic Manager queda fuera de la tabla a propósito: no es un proxy, es un servidor DNS, y esa
diferencia es la pregunta trampa más frecuente del capítulo (§5).

---

## 2. 🧱 Azure Load Balancer

Un balanceador de **capa 4**: reparte flujos TCP y UDP entre un backend de VMs o instancias de un
scale set, sin terminar TLS ni mirar HTTP. Es de muy baja latencia y pasa la IP de origen del cliente
al backend.

- **Público o interno**: con una IP pública de frontend, o con una IP privada de la VNet para tráfico
  entre capas de tu aplicación.
- **SKU Standard**: la única vigente. La SKU Basic se retiró el 30 de septiembre de 2025. Standard es
  **secure by default** —cerrado al tráfico entrante hasta que un NSG lo permita—, admite frontends
  **zone-redundant** o zonales y tiene SLA del 99,99 %.
- **Health probes** TCP, HTTP o HTTPS, que llegan desde `168.63.129.16` ([`03` §7](03-conectividad-privada-y-dns.md#7--1686312916-el-resolver-de-la-plataforma)), por eso
  la regla por defecto `AllowAzureLoadBalancerInBound` del NSG existe.
- **Outbound rules**: comparte las IPs públicas del frontend como salida del backend ([`02` §7](02-redes-vnet-nsg-y-enrutamiento.md#7--salida-a-internet)),
  con riesgo de agotar puertos SNAT.
- **Tier global** (cross-region): un frontend anycast delante de balanceadores regionales, para
  failover de capa 4 entre regiones.

Cuándo: tráfico no HTTP (bases de datos, protocolos propios), o como pieza interna de otra
arquitectura —los node pools de AKS y las NVAs en alta disponibilidad lo usan por debajo—.

---

## 3. 🧱 Application Gateway

Un balanceador de **capa 7 regional**: termina TLS, enruta por host y por path, reescribe cabeceras y
URLs, mantiene afinidad de sesión por cookie y, con su variante WAF, filtra ataques web con un
**Web Application Firewall** basado en conjuntos de reglas administrados.

```text
api.banco.com/api/users/*   → backend pool de user-service
api.banco.com/api/orders/*  → backend pool de order-service
admin.banco.com/*           → backend pool interno, solo desde la red corporativa
```

- **v2 es la única versión vigente**: Application Gateway v1 se retiró el 28 de abril de 2026. v2
  autoescala, admite zonas y se despliega en una subnet propia de la VNet.
- Puede ser el punto de entrada **privado** de una aplicación: con un frontend de IP privada, recibe
  tráfico solo de la red (on-premises incluido) y lo lleva a backends privados.
- **Application Gateway for Containers** es un producto aparte, pensado como ingress de AKS; basta con
  saber que existe.

> 💰 **Costo.** Standard v2 tiene un costo fijo de **$0.20/h** en `eastus2` más **$0.008/h** por
> capacity unit; la variante WAF v2, **$0.36/h** de fijo. Corre aunque no llegue un solo request.

---

## 4. 🧱 Front Door

Un balanceador y acelerador de **capa 7 global**. Tu usuario de Madrid entra por el punto de
presencia (PoP) de Microsoft más cercano a él —la IP es **anycast**—, allí se termina TLS, se aplica
el WAF, se sirve desde **caché** lo que se pueda, y el resto viaja por la red troncal de Microsoft
hasta el **origen** más sano y cercano, en la región que sea.

- **Tiers Standard y Premium.** Premium añade el conjunto de reglas WAF administrado por Microsoft, la
  protección contra bots y la **conexión por Private Link al origen**, que permite que el backend (un
  App Service, un Application Gateway, una storage account) **no tenga endpoint público** y aun así
  reciba tráfico de Front Door.
- **Orígenes y grupos de orígenes** con health probes y reglas de reparto por latencia, prioridad o
  peso: es la pieza del failover activo-pasivo o activo-activo entre regiones.
- **Rules engine**: redirecciones, reescrituras y cabeceras en el borde.

> 📝 **Contexto.** **Front Door (classic)** no acepta perfiles nuevos y **se retira el 31 de marzo de
> 2027**; **Azure CDN Standard from Microsoft (classic)** no acepta perfiles ni dominios nuevos desde
> el 15 de agosto de 2025 y **se retira el 30 de septiembre de 2027**. El destino de ambos es Front
> Door Standard o Premium. Si en una entrevista hablan de "Azure CDN" a secas, hoy la respuesta es Front
> Door.

> Nunca respondas: "Front Door es un CDN". Mejor: "Front Door es un balanceador global de capa 7 con
> WAF que además cachea; el contenido estático es solo uno de sus casos".

> 💰 **Costo.** Front Door Standard tiene un cargo base de **$35 al mes** por perfil, más tráfico y
> requests. Es el motivo por el que el laboratorio no lo pone delante de Container Apps.

---

## 5. 🧱 Traffic Manager

**Traffic Manager** reparte tráfico **por DNS**. Cuando un cliente resuelve `api.banco.com`, Traffic
Manager responde con el nombre o la IP del endpoint que elija según su método de enrutamiento y la
salud de los endpoints. Después, **el cliente se conecta directamente a ese endpoint**: Traffic
Manager nunca ve un paquete de datos.

Sus seis métodos:

| Método | Qué devuelve |
|---|---|
| Priority | El endpoint primario; los de respaldo solo si el primario cae |
| Weighted | Uno al azar, con probabilidad según su peso |
| Performance | El de menor latencia desde el resolver DNS del cliente |
| Geographic | El asignado a la región geográfica de la consulta |
| Multivalue | Todas las IPs sanas, para que el cliente reintente |
| Subnet | El asignado al rango de IP de origen de la consulta |

Tres consecuencias de ser DNS que se preguntan:

- **el failover tarda lo que tarde en caducar la caché DNS** de clientes y resolvers, según el TTL;
  no es instantáneo como el de un proxy;
- **decide con la IP del resolver DNS, no con la del cliente**: un usuario que usa un resolver de otro
  país puede acabar en el endpoint "equivocado";
- **no termina TLS, no aplica WAF, no cachea**: es lo único que hace, y lo hace barato y para
  cualquier protocolo, incluidos endpoints fuera de Azure.

> Nunca respondas: "Traffic Manager balancea la carga entre regiones". Mejor: "Traffic Manager
> devuelve el nombre del endpoint que conviene; el cliente se conecta directamente".

---

## 6. ⚖ La matriz de decisión

| Criterio | Load Balancer | Application Gateway | Front Door | Traffic Manager |
|---|---|---|---|---|
| Capa | 4 | 7 | 7 | DNS |
| Alcance | Regional (o global) | Regional | Global | Global |
| Termina TLS | ❌ | ✅ | ✅ | ❌ |
| WAF | ❌ | ✅ (WAF v2) | ✅ | ❌ |
| Caché | ❌ | ❌ | ✅ | ❌ |
| Protocolos | TCP/UDP | HTTP/S | HTTP/S | Cualquiera |
| Failover | Por health probe | Por health probe | Por health probe, en el borde | Por DNS, según TTL |

Las combinaciones son frecuentes y conviene saber justificarlas:

```text
Web pública multi-región:      Front Door → Application Gateway (por región) → backends privados
API interna regional:          Application Gateway con frontend privado → backends
Protocolo no HTTP multi-región: Traffic Manager → Load Balancer público por región
```

---

## 7. 🧱 API Management

**El problema:** tienes veinte APIs de microservicios y necesitas un único punto de entrada con
autenticación, cuotas por consumidor, versionado, transformación y un portal donde los socios
descubran y prueben las APIs. Un balanceador no hace nada de eso.

**Azure API Management** (APIM) tiene tres piezas:

- el **gateway**, que recibe cada llamada y aplica **políticas** antes y después de reenviarla al
  backend;
- el **plano de gestión**, donde defines APIs, operaciones, **productos** (paquetes de APIs con sus
  condiciones de uso) y **suscripciones**, cada una con su *subscription key*;
- el **developer portal**, que publica la documentación y las claves para los consumidores.

Los tiers se reparten en dos familias, y la elección es de red y de escala:

| Necesidad | Tier que la cubre |
|---|---|
| Pago por llamada, sin instancias | Consumption |
| Pruebas sin SLA | Developer |
| Private endpoint de entrada | Developer, Basic, Standard, Standard v2, Premium, Premium v2 |
| Inyectar el gateway en tu VNet | Developer, Premium, Premium v2 |
| Multi-región y self-hosted gateway | Premium |

El **self-hosted gateway** ejecuta el gateway de APIM como contenedor en tu propia infraestructura,
incluso on-premises, gestionado desde Azure. Es la respuesta a "las APIs viven en el datacenter y el
tráfico no debe salir".

> Nunca respondas: "APIM es un load balancer". Mejor: "APIM es la capa de gestión de APIs:
> autenticación, cuotas, transformación, versionado y portal; se pone detrás de un balanceador o de
> Front Door, no en su lugar".

> 💰 **Costo.** Consumption cobra por llamada, con el primer millón al mes sin cargo, y es el tier del
> drill de [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales). Los tiers con instancias
> cobran por hora de unidad: Developer cuesta **$0.0658/h** en `eastus2` y no tiene SLA.

---

## 8. 🧱 Políticas de API Management

Las políticas son XML declarativo que se ejecuta en cuatro secciones —`inbound`, `backend`,
`outbound` y `on-error`— y en varios ámbitos que se heredan: global, producto, API y operación. Las
dos que más se preguntan, juntas en una sección `inbound`:

```xml
<inbound>
    <!-- valida el token de Entra ID antes de tocar el backend -->
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
        <openid-config url="https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee/v2.0/.well-known/openid-configuration" />
        <audiences>
            <audience>api://inv-api</audience>
        </audiences>
        <required-claims>
            <claim name="roles" match="any">
                <value>Inventory.Write</value>
            </claim>
        </required-claims>
    </validate-jwt>
    <!-- como mucho 100 llamadas por minuto por suscripción -->
    <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Subscription.Id)" />
    <base />
</inbound>
```

- `validate-jwt` comprueba firma, caducidad, audiencia y claims del token **en el gateway**, antes de
  que la llamada llegue al backend. `header-name` indica de dónde leer el token y
  `failed-validation-httpcode` qué devolver si no es válido.
- `openid-config` apunta al documento de descubrimiento del tenant: de ahí APIM obtiene las claves
  públicas de firma y el issuer esperado, y las renueva cuando Entra ID las rota. El GUID es el tenant
  de ejemplo del curso.
- `audiences` exige que el token se haya emitido **para esta API** (`api://inv-api`). Sin esa
  comprobación, un token válido emitido para otra aplicación del mismo tenant pasaría.
- `required-claims` exige que el token traiga el app role `Inventory.Write` en el claim `roles`. La
  diferencia entre `roles` y `scp`, y por qué importa, es el corazón del [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md).
- `rate-limit-by-key` limita a 100 llamadas por ventana de 60 segundos, contando por la expresión de
  `counter-key` —aquí, el ID de la suscripción de APIM del consumidor—. Excedido el límite, APIM
  responde `429` sin molestar al backend.
- `<base />` hereda las políticas del ámbito superior en ese punto; quitarlo las desactiva para esta
  API, que rara vez es lo que se quiere.

> ⚠️ **Validar en el borde no exime de validar en la API.** Si el backend es alcanzable por otra vía
> —otra red, otro gateway, un error de configuración—, un backend que confía ciegamente en que "ya lo
> validó APIM" queda abierto. La defensa en profundidad valida en los dos sitios, o garantiza por red
> que el backend solo sea alcanzable desde el gateway.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Traffic Manager balancea tráfico" | Responde DNS; el cliente se conecta directo, y el failover depende del TTL |
| "Front Door es un CDN" | Es un balanceador global de capa 7 con WAF que además cachea |
| "Azure CDN es la opción para contenido estático" | CDN from Microsoft (classic) se retira el 30-09-2027; el destino es Front Door |
| "APIM es un load balancer" | Es gestión de APIs: autenticación, cuotas, transformación, portal |
| "Application Gateway sirve para multi-región" | Es regional; multi-región es Front Door o Traffic Manager delante |
| "Si APIM valida el token, la API no necesita hacerlo" | Solo si la red garantiza que el backend no es alcanzable por otra vía |
| "El Load Balancer mira la URL" | Es capa 4: IP, puerto y protocolo |

---

## 🧠 Preguntas rápidas

1. ¿Qué dos preguntas ordenan la elección entre Load Balancer, Application Gateway, Front Door y Traffic Manager?
2. ¿Por qué Traffic Manager no aparece en la tabla de capa 4 y capa 7, y qué hace exactamente cuando un cliente resuelve su nombre?
3. ¿Por qué un failover con Traffic Manager no es instantáneo?
4. Necesitas enrutar `/api/users/*` y `/api/orders/*` a backends distintos dentro de una región, con WAF. ¿Qué producto usas?
5. ¿Qué añade Front Door Premium sobre Standard, y cuál de esas diferencias permite que el origen no tenga endpoint público?
6. ¿Qué está pasando con Front Door (classic) y con Azure CDN Standard from Microsoft (classic)?
7. ¿Qué significa que un Load Balancer Standard sea "secure by default"?
8. Tu aplicación usa un protocolo TCP propio y debe estar en dos regiones con failover. ¿Qué combinación propones?
9. ¿Qué problema resuelve API Management que ningún balanceador resuelve?
10. ¿Qué tier de API Management elegirías si el gateway tiene que vivir dentro de tu VNet, y cuál si las APIs están on-premises y el tráfico no debe salir del datacenter?
11. En una política `validate-jwt`, ¿qué pasa si omites la comprobación de audiencia?
12. ¿Por qué validar el token en APIM no exime al backend de validarlo?

---

## 📚 Referencias oficiales

- Opciones de balanceo de carga en Azure: https://learn.microsoft.com/en-us/azure/architecture/guide/technology-choices/load-balancing-overview
- ¿Qué es Azure Load Balancer?: https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-overview
- SKUs de Load Balancer y retiro de la Basic: https://learn.microsoft.com/en-us/azure/load-balancer/skus
- Load Balancer entre regiones (tier global): https://learn.microsoft.com/en-us/azure/load-balancer/cross-region-overview
- ¿Qué es Application Gateway?: https://learn.microsoft.com/en-us/azure/application-gateway/overview
- Migrar Application Gateway v1 a v2: https://learn.microsoft.com/en-us/azure/application-gateway/migrate-v1-v2
- ¿Qué es Azure Front Door?: https://learn.microsoft.com/en-us/azure/frontdoor/front-door-overview
- Comparación de tiers de Front Door y CDN, y fechas de retiro: https://learn.microsoft.com/en-us/azure/frontdoor/front-door-cdn-comparison
- Preguntas frecuentes del retiro de Front Door (classic): https://learn.microsoft.com/en-us/azure/frontdoor/classic-retirement-faq
- Preguntas frecuentes del retiro de Azure CDN from Microsoft (classic): https://learn.microsoft.com/en-us/azure/cdn/classic-cdn-retirement-faq
- Métodos de enrutamiento de Traffic Manager: https://learn.microsoft.com/en-us/azure/traffic-manager/traffic-manager-routing-methods
- Cómo funciona Traffic Manager: https://learn.microsoft.com/en-us/azure/traffic-manager/traffic-manager-how-it-works
- Conceptos clave de API Management: https://learn.microsoft.com/en-us/azure/api-management/api-management-key-concepts
- Comparación de tiers de API Management: https://learn.microsoft.com/en-us/azure/api-management/api-management-features
- Self-hosted gateway de API Management: https://learn.microsoft.com/en-us/azure/api-management/self-hosted-gateway-overview
- Política `validate-jwt`: https://learn.microsoft.com/en-us/azure/api-management/validate-jwt-policy
- Política `rate-limit-by-key`: https://learn.microsoft.com/en-us/azure/api-management/rate-limit-by-key-policy
- Políticas en API Management: https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-policies
- Precios de Load Balancer: https://azure.microsoft.com/en-us/pricing/details/load-balancer/
- Precios de Application Gateway: https://azure.microsoft.com/en-us/pricing/details/application-gateway/
- Precios de Front Door: https://azure.microsoft.com/en-us/pricing/details/frontdoor/
- Precios de Traffic Manager: https://azure.microsoft.com/en-us/pricing/details/traffic-manager/
- Precios de API Management: https://azure.microsoft.com/en-us/pricing/details/api-management/
