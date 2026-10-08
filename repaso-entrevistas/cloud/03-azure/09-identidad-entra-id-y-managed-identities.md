# 09 — Identidad: Entra ID y managed identities

> **Objetivo:** entender quién es quién en Azure: el tenant de Microsoft Entra ID, las aplicaciones,
> los service principals, las managed identities y los tokens que se emiten para ellos, y por qué una
> aplicación bien diseñada no guarda ni una credencial.
> **Se asume leído:** [`01`](01-infraestructura-global-y-resource-manager.md), sobre todo la jerarquía
> de scopes (§6).
> **Se toca más con:** el [`10`](10-autorizacion-rbac-policy-y-gobierno.md) (autorización), que decide qué puede hacer cada identidad de
> este capítulo, y el [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md) (identidad de aplicaciones), que usa estos objetos para proteger una API.
> **Se practica en:** [`L02`](l02-entra-id-rbac-y-managed-identities.md) (managed identities, un token decodificado y el Owner que no puede leer
> un blob). Ver [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [Dos árboles](#1--dos-árboles-distintos) · [El tenant](#2--el-tenant-de-microsoft-entra-id) ·
[App registration y service principal](#3--app-registration-y-service-principal) ·
[Credenciales](#4--credenciales-de-una-aplicación) · [Managed identities](#5--managed-identities) ·
[Workload identity federation](#6--workload-identity-federation) · [Tokens](#7--tokens) ·
[DefaultAzureCredential](#8--defaultazurecredential-en-java) ·
[Roles de Entra frente a roles de Azure](#9--roles-de-entra-id-frente-a-roles-de-azure-rbac) ·
[Conditional Access](#10--conditional-access-y-mfa) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Dos árboles distintos

La confusión de fondo de casi todas las preguntas de identidad en Azure es creer que hay un solo
sistema. Hay dos, y la pregunta que responde cada uno es distinta:

```text
Microsoft Entra ID (el tenant)          Azure Resource Manager (la jerarquía de scopes)
"¿quién eres?"                          "¿sobre qué actúas?"
├── usuarios                            Root management group
├── grupos                              └── management groups
├── aplicaciones (app registrations)        └── suscripciones
├── service principals                          └── resource groups
└── managed identities                              └── recursos
          │                                               ▲
          └──────── un role assignment une ───────────────┘
                    una identidad con un scope (capítulo 10)
```

Este capítulo trata el árbol de la izquierda. El siguiente, cómo se conecta con el de la derecha.

> 📝 **Contexto.** **Azure Active Directory pasó a llamarse Microsoft Entra ID**; el cambio se
> anunció el 11 de julio de 2023 y se desplegó en los productos a partir del 15 de agosto de ese año.
> No cambió la funcionalidad ni los endpoints. El curso dice siempre "Entra ID"; si en una entrevista
> alguien dice "Azure AD", es lo mismo.

---

## 2. 🧱 El tenant de Microsoft Entra ID

Un **tenant** es una instancia dedicada de Entra ID que representa a una organización: su directorio
de usuarios, grupos y aplicaciones, identificado por un GUID (el *tenant ID*) y por dominios
(`banco.onmicrosoft.com`, `banco.com`).

- **cada suscripción confía en un único tenant** ([`01` §7](01-infraestructura-global-y-resource-manager.md#7--la-suscripción)) y toma de él sus identidades;
- un tenant puede tener muchas suscripciones;
- los **usuarios invitados** (B2B) son identidades de otro tenant que se representan en el tuyo para
  darles acceso;
- el tenant es también el emisor de los tokens: `https://login.microsoftonline.com/<tenant-id>`.

La consecuencia práctica: **lo que vive en el tenant no vive en ninguna suscripción**. Una app
registration no está en un resource group, no aparece en `az resource list` y no se borra con `az
group delete` ([`L00` §7.3](l00-idea-lab-practico.md#73-el-resource-group-es-la-unidad-de-destrucción-con-letra-pequeña)).

---

## 3. 🧱 App registration y service principal

**El problema:** tu API Spring Boot necesita una identidad para llamar a otra API, o tiene que
aceptar tokens emitidos para ella. En Entra ID, eso empieza con un registro, pero el registro no es
la identidad que recibe permisos.

- **Application object (app registration)**: la **definición global** de la aplicación, una sola,
  en su tenant de origen. Describe cómo se emiten tokens para ella, qué APIs expone (scopes y app
  roles, [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md)), qué credenciales tiene y a qué recursos quiere acceder. Tiene un **client
  ID** (o *application ID*) único en todo Microsoft.
- **Service principal (enterprise application)**: la **instancia local** de esa aplicación en un
  tenant concreto. Es el objeto que **inicia sesión y recibe permisos**: a él se le asignan roles de
  Azure RBAC y app roles. Hay uno en cada tenant donde se usa la aplicación.

```text
App registration (1, en el tenant de origen)  ──plantilla──►  Service principal (1 por tenant)
   client ID, credenciales, scopes y roles                       objeto que recibe permisos
   "la clase"                                                    "la instancia"
```

Tres tipos de service principal que conviene distinguir:

- **de aplicación**: la instancia de una app registration;
- **de managed identity**: representa una managed identity (§5); no tiene app registration asociada y
  no se modifica directamente;
- **legacy**: aplicaciones anteriores a las app registrations.

En una aplicación **multi-tenant**, un solo application object en el tenant del fabricante genera un
service principal en cada tenant cliente que consiente usarla.

> Nunca respondas: "una managed identity no es un service principal". Mejor: "una managed identity
> **es** un service principal de un tipo especial, cuya credencial administra Azure y que no tiene app
> registration detrás".

---

## 4. 🧱 Credenciales de una aplicación

Una app registration puede probar su identidad de tres formas, de peor a mejor:

- **client secret**: una contraseña con fecha de caducidad. Hay que guardarla, rotarla y evitar que
  acabe en un repositorio. Es la causa clásica de incidentes y de caídas por caducidad;
- **certificado**: la aplicación firma una aserción con su clave privada. Más seguro que un secreto,
  pero sigue siendo un material que custodiar y renovar;
- **federated credential** (§6): la aplicación **no guarda nada**; presenta un token emitido por otro
  proveedor de confianza (GitHub, Kubernetes, otra nube) y Entra ID lo cambia por uno suyo.

Y por encima de las tres, cuando la carga corre en Azure, la **managed identity**, que ni siquiera
necesita una app registration.

```text
Regla de arquitectura, de mejor a peor:
managed identity  >  federated credential  >  certificado  >  client secret
```

---

## 5. 🧱 Managed identities

**El problema:** `inv-api` corre en Container Apps y tiene que escribir en Cosmos DB, enviar a
Service Bus y leer un secreto de Key Vault. Cada credencial que guardes es una credencial que se
puede filtrar, caducar o quedarse sin rotar.

Una **managed identity** es una identidad de Entra ID que Azure asigna a un recurso de cómputo y
cuya credencial **administra Azure y nunca ves**. El código pide un token al entorno en el que corre y
lo recibe sin haber guardado nada. Dos tipos:

| Propiedad | System-assigned | User-assigned |
|---|---|---|
| Creación | Se habilita en el recurso | Es un recurso propio de Azure |
| Ciclo de vida | Muere con el recurso | Independiente; se borra explícitamente |
| Compartir | No: una por recurso | Sí: varios recursos la pueden usar |
| Cuándo | Una carga en un solo recurso | Varios recursos con los mismos permisos, recursos que se recrean, permisos preasignados antes de desplegar |

Microsoft recomienda la **user-assigned** para servicios propios, y el curso la usa por una razón
concreta: el role assignment se hace **antes** de desplegar la app, y sobrevive a que Container Apps
recree el recurso. Con una system-assigned, cada recreación es una identidad nueva sin permisos.

El laboratorio crea una por servicio:

```bash
az identity create \
  --name inv-api-id \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --tags project=inv-lab env=lab
```

- `az identity create` crea una **user-assigned managed identity** como recurso de ARM, y con ella su
  service principal en el tenant. La salida trae tres identificadores que no hay que confundir: el
  `id` (resource ID de ARM), el `clientId` (el que usa el código para elegir esta identidad) y el
  `principalId` (el object ID del service principal, el que recibe role assignments).
- `--location` fija dónde vive el recurso de la identidad; la identidad puede usarse desde recursos
  de otras regiones.
- `--tags` etiqueta el recurso ARM. El service principal en el tenant no lleva esos tags.

Una identidad **sin role assignments no puede hacer nada**: crearla es la mitad del trabajo. El
[`10`](10-autorizacion-rbac-policy-y-gobierno.md) hace la otra mitad.

> ⚠️ **Una managed identity solo sirve dentro de Azure.** El token se obtiene de un endpoint que solo
> existe en el host de Azure donde corre el recurso. Para una carga fuera de Azure —un pipeline de
> GitHub, un cluster en otra nube— la respuesta es workload identity federation (§6), no una managed
> identity con su secreto exportado, porque no hay secreto que exportar.

---

## 6. 🧱 Workload identity federation

**El problema:** tu pipeline de GitHub Actions tiene que desplegar en Azure. La forma antigua era crear
un service principal con un client secret y guardarlo como secreto del repositorio: una credencial
de larga duración, con permisos de despliegue, en un sistema ajeno.

**Workload identity federation** configura una **relación de confianza**: una app registration o una
user-assigned managed identity acepta tokens emitidos por un proveedor externo de OpenID Connect.
La *federated credential* dice exactamente cuáles:

- `issuer`: quién emite el token externo (`https://token.actions.githubusercontent.com`);
- `subject`: qué carga exacta (`repo:banco/inv-api:environment:production`);
- `audience`: para quién se emitió (`api://AzureADTokenExchange`).

Los tres valores tienen que coincidir **exactamente, distinguiendo mayúsculas**, con los del token
externo. El flujo: el pipeline pide un token a GitHub, se lo presenta a Entra ID, Entra ID comprueba
la confianza y le entrega un token de Azure de corta duración. **No hay ningún secreto guardado en
ningún sitio.**

Funciona para GitHub Actions, Azure Pipelines, cualquier Kubernetes (el **workload identity de AKS**
es este mecanismo), Google Cloud, AWS y cualquier proveedor OIDC. El [`16`](16-orquestacion-y-cicd.md) lo usa para el
despliegue continuo.

> Nunca respondas: "guardamos el client secret del service principal en los secretos de GitHub".
> Mejor: "federamos una managed identity o una app registration con GitHub por OIDC, acotada al
> repositorio y al environment; no existe secreto que filtrar ni que rotar".

---

## 7. 🧱 Tokens

Todo lo anterior termina en un **token**: un JWT firmado por Entra ID que el cliente presenta en la
cabecera `Authorization: Bearer`. Hay dos tipos, y confundirlos es un error de seguridad:

- **ID token**: dice **quién es el usuario**, para la aplicación cliente que inició sesión. No sirve
  para llamar a una API;
- **access token**: dice **qué puede hacer el portador contra un recurso concreto**. Es el que se
  envía a una API, y **está emitido para esa API**.

Los claims que hay que saber leer en un access token:

| Claim | Qué es | Para qué sirve al validar |
|---|---|---|
| `aud` | Audiencia: la API para la que se emitió | **Hay que comprobarlo siempre**; rechazar si no es tu API |
| `iss` | Emisor, con el tenant; en v2 termina en `/v2.0` | Restringir qué tenants aceptas |
| `tid` | Tenant del que viene el principal | Junto con `iss`, en APIs multi-tenant |
| `oid` | Object ID del usuario o service principal | Identificador estable del llamante |
| `azp` (v2) / `appid` (v1) | Client ID de la aplicación que pidió el token | Qué cliente llama |
| `scp` | Scopes delegados concedidos (tokens de usuario) | Autorizar lo que el usuario delegó |
| `roles` | App roles asignados (tokens de aplicación o de usuario) | Autorizar lo que el llamante tiene asignado |
| `ver` | Versión del token: `1.0` o `2.0` | Saber qué formato validar |

Dos matices que aparecen en toda depuración:

- **la versión del token la decide la API receptora**, no el cliente, con la propiedad
  `requestedAccessTokenVersion` de su app registration (`null` o `1` dan v1; `2` da v2; material
  anterior la llama `accessTokenAcceptedVersion`). Una API que espera tokens v2 y recibe v1 falla
  al validar el issuer ([`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md));
- `scp` aparece en tokens **de usuario** (permisos delegados) y `roles` en tokens **de aplicación**
  (y en tokens de usuario con app roles asignados). Una API que solo mira `scp` rechaza a todos los
  clientes máquina.

Ver un token de verdad es la forma más rápida de entender todo esto:

```bash
az account get-access-token \
  --resource https://storage.azure.com/ \
  --query accessToken \
  --output tsv
```

- `az account get-access-token` pide a Entra ID un access token **para la identidad con la que está
  iniciada la CLI**. Es la misma operación que hace `DefaultAzureCredential` cuando corre en tu
  portátil (§8).
- `--resource https://storage.azure.com/` indica el **recurso** para el que se pide el token, que
  acaba en su claim `aud`. Sin este flag, el token es para Azure Resource Manager
  (`https://management.azure.com/`), y un token para ARM **no sirve** contra el data plane de Storage:
  la audiencia no coincide.
- `--query accessToken --output tsv` extrae solo el JWT, sin comillas, listo para pegarlo en un
  decodificador o en una cabecera. **Es una credencial**: quien lo tenga puede usarlo hasta que caduque.

[`L02`](l02-entra-id-rbac-y-managed-identities.md) decodifica ese token y lee sus claims; es el primer paso de cualquier diagnóstico de `401`.

---

## 8. 🧱 `DefaultAzureCredential` en Java

La librería `azure-identity` (`com.azure:azure-identity`) ofrece `DefaultAzureCredential`, una
**cadena de credenciales** que prueba en orden las fuentes típicas y usa la primera que funciona:

```text
1. Variables de entorno (service principal con secreto o certificado)
2. Workload identity (Kubernetes federado)
3. Managed identity (el host de Azure donde corre)
4. Herramientas de desarrollo: IntelliJ, Azure CLI, Azure PowerShell, Azure Developer CLI…
```

Por eso **el mismo código funciona en tu portátil y en Container Apps sin cambiar una línea**: en
local encuentra tu sesión de `az`; desplegado, encuentra la managed identity.

```java
// en Container Apps con una user-assigned identity, hay que decirle cuál usar
TokenCredential credential = new DefaultAzureCredentialBuilder()
        .managedIdentityClientId(System.getenv("AZURE_CLIENT_ID"))
        .build();

SecretClient secrets = new SecretClientBuilder()
        .vaultUrl("https://inv-lab-kv-472913.vault.azure.net")
        .credential(credential)
        .buildClient();
```

- `DefaultAzureCredentialBuilder().build()` construye la cadena. Es thread-safe: una instancia sirve
  para todos los clientes del SDK de la aplicación.
- `managedIdentityClientId(...)` elige **qué** user-assigned identity usar cuando el recurso tiene
  varias (o cuando no tiene system-assigned). Sin él, la managed identity pediría la system-assigned y
  fallaría. Se lee de `AZURE_CLIENT_ID`, que es además la variable que la librería consulta por su
  cuenta: fijarla en la configuración del contenedor equivale a esta línea.
- `SecretClientBuilder().credential(credential)` es el patrón de todo el SDK: cada cliente acepta un
  `TokenCredential` y pide sus tokens, con la audiencia correcta, cuando los necesita.

Una advertencia de producción: la cadena es cómoda pero **opaca y más lenta** cuando falla, porque
recorre todas las fuentes. En producción es habitual usar directamente `ManagedIdentityCredential`, o
una cadena propia con `ChainedTokenCredential`, para que un error de configuración falle rápido y con
un mensaje claro.

---

## 9. 🧱 Roles de Entra ID frente a roles de Azure RBAC

Aquí está la pregunta favorita de las entrevistas de Azure, y la respuesta sale del §1:

| | Roles de Microsoft Entra ID | Roles de Azure RBAC |
|---|---|---|
| Qué gestionan | El directorio: usuarios, grupos, aplicaciones, dominios | Los recursos de Azure: VMs, storage, bases |
| Ejemplos | Global Administrator, User Administrator, Application Administrator | Owner, Contributor, Reader, Storage Blob Data Reader |
| Scope | Tenant, unidad administrativa u objeto concreto | Management group, suscripción, resource group, recurso |
| Dónde se asignan | Entra admin center, Microsoft Graph | Portal, `az role assignment`, ARM |

Las dos consecuencias que se preguntan:

- **el Global Administrator no ve ni un recurso de Azure por defecto.** Puede **elevar su acceso**, lo
  que le da el rol **User Access Administrator** en el root management group, y desde ahí asignarse lo
  que necesite. Es el mecanismo para recuperar el control de una suscripción huérfana, y debe usarse y
  retirarse;
- **el Owner de una suscripción no puede crear un usuario** en el tenant: eso es un rol de Entra ID.

> Nunca respondas: "el Global Administrator puede hacer todo en Azure". Mejor: "el Global
> Administrator administra el directorio; para tocar recursos de Azure tiene que elevar su acceso, que
> le da User Access Administrator en la raíz, y esa elevación queda auditada".

> 📝 **Contexto.** Los roles de administrador clásicos de suscripción (Account Administrator, Service
> Administrator, Co-Administrator) están **retirados**: desde agosto de 2024 no se admiten, y en 2026
> quedaron completamente sustituidos por Azure RBAC. Material viejo todavía los menciona.

---

## 10. 🧱 Conditional Access y MFA

Basta con el nivel conceptual para una entrevista de backend:

- **MFA**: un segundo factor al iniciar sesión. Es la medida con más retorno contra el robo de
  credenciales de usuarios;
- **Conditional Access**: políticas del tipo "si **quién** (usuario, grupo, rol) accede a **qué**
  (aplicación) desde **dónde** (ubicación, dispositivo, riesgo), entonces **exige** MFA, un
  dispositivo administrado o bloquea". Es el motor de Zero Trust de Entra ID y requiere licencia
  Entra ID P1 o superior;
- **Privileged Identity Management** (PIM) aplica el mismo principio a los permisos: roles
  *elegibles* que se activan solo cuando hacen falta ([`10`](10-autorizacion-rbac-policy-y-gobierno.md)).

Las managed identities y las federated credentials no pasan por MFA ni por Conditional Access de
usuario: no son personas. Por eso su protección es no tener secretos y tener solo los roles justos.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Una managed identity no es un service principal" | Es un service principal de tipo especial, sin app registration |
| "La app registration es la que recibe los permisos" | Los recibe el service principal de cada tenant |
| "El Global Administrator ve todos los recursos" | No sin elevar su acceso a User Access Administrator en la raíz |
| "Un client secret en Key Vault es tan bueno como una managed identity" | Sigue siendo un secreto que rotar y que puede filtrarse; la managed identity no tiene |
| "Uso una managed identity desde GitHub Actions" | Fuera de Azure no existe el endpoint; se usa workload identity federation |
| "El ID token sirve para llamar a la API" | Se llama con un access token emitido para esa API |
| "Un token de ARM sirve para leer un blob" | La audiencia no coincide; hace falta un token para `https://storage.azure.com/` |
| "La versión del token la elige el cliente" | La fija la API con `requestedAccessTokenVersion` |

---

## 🧠 Preguntas rápidas

1. ¿Qué pregunta responde Entra ID y cuál responde la jerarquía de scopes de Azure Resource Manager?
2. ¿Qué diferencia hay entre una app registration y un service principal, y cuál recibe los permisos?
3. En una aplicación multi-tenant usada por tres clientes, ¿cuántos application objects y cuántos service principals hay?
4. ¿Es una managed identity un service principal?
5. ¿Cuándo elegirías una user-assigned managed identity en lugar de una system-assigned?
6. `az identity create` devuelve un `id`, un `clientId` y un `principalId`. ¿Para qué sirve cada uno?
7. ¿Por qué no puedes usar una managed identity desde un pipeline de GitHub Actions, y qué usas en su lugar?
8. ¿Qué tres campos definen una federated credential y cómo tienen que coincidir con el token externo?
9. ¿Qué diferencia hay entre un ID token y un access token?
10. ¿Qué claim de un access token debe comprobar siempre una API y por qué?
11. ¿Quién decide si un access token es v1 o v2?
12. ¿Por qué el mismo código con `DefaultAzureCredential` funciona en tu portátil y en Container Apps, y qué tienes que añadir si la app usa una user-assigned identity?
13. ¿Puede el Global Administrator de un tenant borrar una VM de una suscripción de ese tenant sin hacer nada más?
14. Obtuviste un token con `az account get-access-token` sin `--resource` y el data plane de Storage lo rechaza. ¿Por qué?

---

## 📚 Referencias oficiales

- ¿Qué es Microsoft Entra ID?: https://learn.microsoft.com/en-us/entra/fundamentals/what-is-entra
- El nuevo nombre de Azure Active Directory: https://learn.microsoft.com/en-us/entra/fundamentals/new-name
- Aplicaciones y service principals: https://learn.microsoft.com/en-us/entra/identity-platform/app-objects-and-service-principals
- Aplicaciones single-tenant y multi-tenant: https://learn.microsoft.com/en-us/entra/identity-platform/single-and-multi-tenant-apps
- Credenciales de aplicación (secretos, certificados, federadas): https://learn.microsoft.com/en-us/entra/identity-platform/how-to-add-credentials
- Managed identities para recursos de Azure: https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview
- Buenas prácticas con managed identities: https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/managed-identity-best-practice-recommendations
- Workload identity federation: https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation
- Confiar en un proveedor externo desde una managed identity: https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust-user-assigned-managed-identity
- Workload identity en AKS: https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview
- Tokens de acceso: https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens
- Referencia de claims del access token: https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference
- ID tokens: https://learn.microsoft.com/en-us/entra/identity-platform/id-tokens
- Azure Identity para Java (`DefaultAzureCredential`): https://learn.microsoft.com/en-us/java/api/overview/azure/identity-readme
- Cadenas de credenciales en el SDK de Java: https://learn.microsoft.com/en-us/azure/developer/java/sdk/authentication/credential-chains
- Roles de Azure, roles de Entra ID y roles clásicos: https://learn.microsoft.com/en-us/azure/role-based-access-control/rbac-and-directory-admin-roles
- Elevar el acceso del Global Administrator: https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin
- ¿Qué es Conditional Access?: https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview
- `az identity`: https://learn.microsoft.com/en-us/cli/azure/identity
- `az account get-access-token`: https://learn.microsoft.com/en-us/cli/azure/account#az-account-get-access-token
