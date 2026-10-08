# 12 — Identidad de aplicaciones: OAuth 2.0 con Entra ID

> **Objetivo:** proteger una API Spring Boot con Entra ID de punta a punta: registrarla, decidir entre
> scopes delegados y app roles, elegir el flujo de cada cliente —humano, máquina y managed identity— y
> validar el token en el resource server sin caer en las trampas de audiencia, issuer y versión.
> **Se asume leído:** [`09`](09-identidad-entra-id-y-managed-identities.md), sobre todo app
> registration frente a service principal (§3) y los tokens (§7).
> **Se toca más con:** [`05`](05-balanceo-entrega-global-y-api-management.md), donde API Management
> valida el JWT en el borde, y [`11`](11-secretos-cifrado-y-key-vault.md), que explica por qué el
> cliente máquina no debería tener un client secret.
> **Se practica en:** [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) (la API registrada, un cliente humano, la managed identity como cliente
> máquina y los tres errores de validación provocados). Ver
> [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [El escenario](#1--el-escenario-una-api-y-tres-clientes) ·
[Registrar la API](#2--registrar-la-api) · [⚖ Scopes frente a app roles](#3--scopes-delegados-frente-a-app-roles) ·
[Consentimiento](#4--consentimiento) · [Flujos](#5--los-flujos) ·
[Managed identity como cliente](#6--una-managed-identity-como-cliente-de-tu-api) ·
[Validar en Spring Boot](#7--validar-el-token-en-spring-boot) · [Trampas](#8--las-trampas-de-la-validación) ·
[⚖ API frente a APIM](#9--validar-en-la-api-o-en-api-management) · [Clientes externos](#10--identidades-de-clientes-external-id-y-b2c) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El escenario: una API y tres clientes

`inv-api` expone el inventario del banco. Tiene tres tipos de llamante, y cada uno necesita algo
distinto:

```text
Persona (analista) ──► app inv-cli ──┐  "leer el inventario EN NOMBRE del analista"
                                     │
Proceso nocturno   ──────────────────┼──►  inv-api  (resource server Spring Boot)
                                     │  "registrar movimientos COMO SÍ MISMO"
inv-projector (Container Apps, MI) ──┘
```

- el **cliente humano** actúa **en nombre de un usuario**: la API debe saber quién es el usuario y qué
  le permitió hacer a la aplicación;
- el **cliente máquina** actúa **como sí mismo**, sin usuario: la API debe saber qué aplicación llama y
  qué permisos tiene asignados;
- si el cliente máquina corre en Azure, **no debería tener credencial propia**: usa su managed
  identity.

Todo el capítulo sale de esta distinción: permisos **delegados** (usuario + aplicación) frente a
permisos **de aplicación** (solo la aplicación).

---

## 2. 🧱 Registrar la API

La API necesita su propia app registration, que define **para quién** se emiten los tokens que
recibirá:

```bash
az ad app create \
  --display-name inv-api \
  --sign-in-audience AzureADMyOrg \
  --requested-access-token-version 2
```

- `az ad app create` crea la **app registration** (el application object del [`09` §3](09-identidad-entra-id-y-managed-identities.md#3--app-registration-y-service-principal)) en el
  tenant. No crea todavía el service principal; se crea con `az ad sp create --id <appId>`, y sin él
  nadie puede obtener tokens para la API en este tenant.
- `--sign-in-audience AzureADMyOrg` la hace **single-tenant**: solo aceptará identidades del propio
  tenant. `AzureADMultipleOrgs` la haría multi-tenant, con las complicaciones de §8.
- `--requested-access-token-version 2` pide que los access tokens emitidos **para esta API** sean v2.
  Sin él, el valor es `null`, que equivale a v1 ([`09` §7](09-identidad-entra-id-y-managed-identities.md#7--tokens)).

Después se le da un **Application ID URI**, el identificador con el que los clientes piden tokens:

```bash
az ad app update \
  --id "$API_APP_ID" \
  --identifier-uris "api://$API_APP_ID"
```

- `$API_APP_ID` es el `appId` (client ID) que devolvió el comando anterior.
- `--identifier-uris "api://$API_APP_ID"` fija el Application ID URI con la forma por defecto,
  `api://<client-id>`. Es el **prefijo de los scopes**: el scope `Inventory.Read` se pide como
  `api://<client-id>/Inventory.Read`. Tiene que ser único; la forma por defecto lo garantiza porque
  lleva el client ID.

---

## 3. ⚖ Scopes delegados frente a app roles

La API expone dos tipos de permiso, y el error clásico es usar uno para lo que hace el otro:

| | Scope delegado | App role |
|---|---|---|
| Quién llama | Una aplicación **en nombre de un usuario** | Una aplicación **como sí misma** (o un usuario con el rol asignado) |
| Claim en el token | `scp` (cadena separada por espacios) | `roles` (array) |
| Se pide como | `api://<id>/Inventory.Read` | `api://<id>/.default` (client credentials) |
| Consentimiento | Usuario o administrador, según el scope | **Siempre administrador**, como asignación |
| Permiso efectivo | La **intersección** de lo que el usuario puede y lo que delegó | Lo asignado a la aplicación |
| En el curso | `Inventory.Read` para `inv-cli` | `Inventory.Write` para `inv-projector-id` |

Dos matices que se preguntan:

- un **scope no da permisos al usuario**: dice qué puede hacer la aplicación en su nombre. Si el
  analista no puede ver un almacén, que `inv-cli` tenga `Inventory.Read` no se lo muestra. La API sigue
  aplicando su propia autorización sobre el usuario (`oid`);
- los **app roles** también se pueden asignar a **usuarios y grupos**, y aparecen en `roles` de sus
  tokens: es la forma de hacer RBAC de aplicación ("este usuario es aprobador") sin mantener tablas
  propias.

> Nunca respondas: "los app roles son como los roles de Azure RBAC". Mejor: "los app roles los define
> mi aplicación y los interpreta mi código a partir del claim `roles`; Azure RBAC autoriza operaciones
> sobre recursos de Azure a través de ARM. Comparten la palabra rol y nada más".

---

## 4. 🧱 Consentimiento

Para que un cliente obtenga un token con un permiso, alguien tiene que **consentir** que ese cliente lo
tenga:

- **consentimiento de usuario**: el usuario acepta, en la primera autenticación, que `inv-cli` lea el
  inventario en su nombre. Solo vale para scopes que no exigen administrador y si la política del
  tenant lo permite (muchos tenants corporativos lo restringen);
- **consentimiento de administrador**: un administrador lo concede para todo el tenant. Es obligatorio
  para los scopes marcados como *admin-only* y para **todos los permisos de aplicación** (app roles
  asignados a aplicaciones).

En un banco lo normal es que el consentimiento de usuario esté deshabilitado para aplicaciones de
terceros y que las aplicaciones propias se **preautoricen** o reciban consentimiento del administrador
en el despliegue.

---

## 5. 🧱 Los flujos

| Flujo | Quién lo usa | Qué obtiene |
|---|---|---|
| **Authorization code + PKCE** | Aplicaciones con usuario: SPA, móvil, web, CLI con navegador | Token delegado (`scp`) en nombre del usuario |
| **Client credentials** | Servicio sin usuario (demonio, job) | Token de aplicación (`roles`), pidiendo `/.default` |
| **On-behalf-of (OBO)** | Una API que llama a otra API conservando al usuario | Token delegado nuevo para la API de abajo |
| **Device code** | Dispositivos sin navegador; CLIs en entornos sin UI | Token delegado; el usuario se autentica en otro dispositivo |

- **Authorization code + PKCE**: la aplicación redirige al usuario a Entra ID, recibe un código y lo
  cambia por el token. **PKCE** (*Proof Key for Code Exchange*) liga el código a un secreto efímero que
  genera el cliente, de modo que un código interceptado no sirve. Es obligatorio para clientes públicos
  y recomendado para todos. El flujo *implicit* está desaconsejado.
- **Client credentials**: el servicio se autentica con **su propia credencial** —certificado, federated
  credential o, en Azure, managed identity— y pide `api://<id>/.default`, que significa "todos los
  permisos de aplicación que me asignaron para esta API". No hay usuario ni consentimiento en el
  momento.
- **On-behalf-of**: `inv-api` recibe el token del analista y necesita llamar a otra API como el
  analista. Presenta el token recibido (con su propia credencial) y Entra ID le emite uno nuevo para la
  API de abajo, con el mismo usuario. **No se reenvía el token recibido**: su `aud` es `inv-api`, y la
  API de abajo debe rechazarlo.

> ⚠️ **Reenviar el token del usuario a otra API es el error del *confused deputy*.** Si la API de abajo
> lo acepta, está aceptando tokens emitidos para otra audiencia. La respuesta correcta es OBO, o que la
> API de abajo confíe en la de arriba con un token de aplicación.

---

## 6. 🧱 Una managed identity como cliente de tu API

`inv-projector` corre en Container Apps con `inv-projector-id` y tiene que registrar movimientos en
`inv-api`. Es client credentials **sin credencial**: la managed identity pide el token al endpoint de
identidad del host.

El paso que falta es **asignar el app role `Inventory.Write` al service principal de la managed
identity**. No hay comando `az` dedicado ni pantalla en el portal para esto: se hace con Microsoft
Graph.

```bash
az rest \
  --method POST \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$MI_PRINCIPAL_ID/appRoleAssignments" \
  --body "{\"principalId\": \"$MI_PRINCIPAL_ID\", \"resourceId\": \"$API_SP_ID\", \"appRoleId\": \"$WRITE_ROLE_ID\"}"
```

- `az rest` hace una petición autenticada con la sesión de la CLI a cualquier API de Azure o de
  Microsoft Graph; se usa cuando la operación no tiene comando propio.
- `--uri .../servicePrincipals/$MI_PRINCIPAL_ID/appRoleAssignments` crea una asignación de app role
  **cuyo beneficiario** es la managed identity. `$MI_PRINCIPAL_ID` es el `principalId` de
  `inv-projector-id` ([`09` §5](09-identidad-entra-id-y-managed-identities.md#5--managed-identities)).
- `resourceId` es el **object ID del service principal de `inv-api`** (no su `appId`): el recurso que
  expone el rol.
- `appRoleId` es el `id` (GUID) del app role `Inventory.Write` en la app registration de la API.
- Quien ejecuta el comando necesita un rol de Entra ID que permita asignar app roles, como
  *Application Administrator* o *Cloud Application Administrator*. Un Owner de la suscripción, por sí
  solo, no puede: es un permiso del directorio, no de Azure RBAC ([`09` §9](09-identidad-entra-id-y-managed-identities.md#9--roles-de-entra-id-frente-a-roles-de-azure-rbac)).

En el código de `inv-projector`, el token se pide con la audiencia de la API:

```java
// Pide un token para inv-api con la user-assigned identity; el SDK lo cachea y lo renueva
TokenCredential credential = new ManagedIdentityCredentialBuilder()
        .clientId(System.getenv("AZURE_CLIENT_ID"))
        .build();

AccessToken token = credential
        .getTokenSync(new TokenRequestContext().addScopes("api://" + apiAppId + "/.default"));
```

- `ManagedIdentityCredentialBuilder().clientId(...)` elige la user-assigned identity, sin recorrer la
  cadena de `DefaultAzureCredential`: si falla, falla aquí y con un mensaje claro.
- `addScopes("api://<id>/.default")` pide un token de aplicación para `inv-api` con **todos** los app
  roles asignados a la identidad. Pedir un scope concreto (`/Inventory.Write`) no funciona en client
  credentials.
- El token resultante trae `roles: ["Inventory.Write"]`, `oid` = `principalId` de la identidad y, en
  v2, `aud` = client ID de `inv-api`.

> ⚠️ **La asignación no se nota al instante.** Los servicios cachean el token de la managed identity y
> un app role recién asignado puede tardar horas en aparecer en `roles` ([`10` §7](10-autorizacion-rbac-policy-y-gobierno.md#7--propagación-caché-y-límites)). [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) lo
> deja escrito para que no se confunda con un error de configuración.

---

## 7. 🧱 Validar el token en Spring Boot

La API es un **OAuth 2.0 resource server**: recibe el `Authorization: Bearer`, valida el JWT y
convierte sus claims en authorities. Con Spring Boot 4.0 y el starter
`spring-boot-starter-security-oauth2-resource-server` (el antiguo `spring-boot-starter-oauth2-resource-server`
sigue publicado, pero está deprecado en su favor desde la 4.0):

```properties
# application.properties de inv-api
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee/v2.0
spring.security.oauth2.resourceserver.jwt.audiences=${INV_API_CLIENT_ID}
```

- `issuer-uri` apunta al emisor **v2.0 del tenant**. Al arrancar, Spring descarga
  `<issuer-uri>/.well-known/openid-configuration`, obtiene de ahí las claves públicas (`jwks_uri`) y
  valida que el `iss` de cada token sea **exactamente** este valor. Si la API recibiera tokens v1, cuyo
  `iss` es `https://sts.windows.net/<tenant>/`, los rechazaría: por eso §2 fija la versión 2.
- `audiences` exige que el `aud` del token sea el **client ID** de `inv-api`. En tokens v2, `aud` es
  siempre el client ID de la API, no el Application ID URI.
- La firma, la expiración (`exp`) y el `nbf` los valida Spring sin configuración adicional.

Por defecto, Spring convierte el claim `scp` en authorities `SCOPE_*`, pero **ignora `roles`**. Un
resource server que solo mira `scp` rechaza a todos los clientes máquina. El convertidor que une los
dos:

```java
@Configuration
@EnableMethodSecurity
class SecurityConfig {

    @Bean
    SecurityFilterChain api(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, "/items/**").hasAuthority("SCOPE_Inventory.Read")
                        .requestMatchers(HttpMethod.POST, "/movements").hasAuthority("APPROLE_Inventory.Write")
                        .anyRequest().authenticated())
                .oauth2ResourceServer(oauth -> oauth.jwt(jwt -> jwt.jwtAuthenticationConverter(entraIdConverter())));
        return http.build();
    }

    // scp → SCOPE_*, roles → APPROLE_*: un token de usuario y uno de aplicación caben en las mismas reglas
    private static JwtAuthenticationConverter entraIdConverter() {
        JwtGrantedAuthoritiesConverter scopes = new JwtGrantedAuthoritiesConverter();
        JwtGrantedAuthoritiesConverter roles = new JwtGrantedAuthoritiesConverter();
        roles.setAuthoritiesClaimName("roles");
        roles.setAuthorityPrefix("APPROLE_");

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(token -> {
            List<GrantedAuthority> authorities = new ArrayList<>(scopes.convert(token));
            authorities.addAll(roles.convert(token));
            return authorities;
        });
        return converter;
    }
}
```

- `hasAuthority("SCOPE_Inventory.Read")` protege la lectura con el scope delegado que trae el token
  del analista.
- `hasAuthority("APPROLE_Inventory.Write")` protege la escritura con el app role que trae el token de
  `inv-projector-id`.
- El primer `JwtGrantedAuthoritiesConverter`, sin configurar, lee `scp` (o `scope`) y antepone
  `SCOPE_`. El segundo lee `roles` y antepone `APPROLE_`, un prefijo propio para no confundirlos con
  los `ROLE_` de Spring.
- `@EnableMethodSecurity` permite además `@PreAuthorize` en los métodos, para reglas que dependen del
  usuario concreto (`oid`), que es donde vive la autorización de negocio.

**Spring Cloud Azure** ofrece la alternativa `spring-cloud-azure-starter-active-directory`, que
configura el resource server a partir de propiedades `spring.cloud.azure.active-directory.*` y mapea
`roles` por su cuenta. La versión se fija con el BOM `spring-cloud-azure-dependencies` **7.4.0 para
Spring Boot 4.0.x**, la combinación que documenta Learn a la fecha de vigencia. El curso usa Spring
Security a secas porque es portable y porque en una entrevista se espera saber qué valida y por qué.

---

## 8. 🧱 Las trampas de la validación

Los tres `401` que [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) provoca a propósito, y los dos que aparecen en producción:

| Síntoma | Causa | Arreglo |
|---|---|---|
| `401`, `invalid_token`, "The aud claim is not valid" | El cliente pidió el token para otro recurso (ARM, Graph) o la API espera el Application ID URI y el token v2 trae el client ID | Pedir `api://<id>/...`; validar el client ID como audiencia |
| `401`, "The iss claim is not valid" | La API espera `…/v2.0` y recibe un token v1 (`sts.windows.net`) | Fijar `requestedAccessTokenVersion` a `2` en la API |
| `403` con token válido | El token no trae el scope o el rol que exige la regla, o el convertidor ignora `roles` | Revisar el token decodificado y el mapeo de authorities |
| Rechazos solo de ciertos tenants | API multi-tenant validando un issuer fijo | Validar el patrón `https://login.microsoftonline.com/{tid}/v2.0` contra el `tid` del token, y una lista de tenants permitidos |
| Faltan los grupos del usuario | **Overage**: con más de 200 grupos, el JWT no trae `groups` sino una referencia para consultarlos en Graph | Usar app roles asignados a grupos en vez de leer `groups` |

> 🩺 **Diagnóstico.** Un `401` de un resource server se diagnostica **decodificando el token** y
> comparando tres claims con la configuración: `aud` contra `audiences`, `iss` contra `issuer-uri` y
> `ver`. Nueve de cada diez veces es uno de esos tres. Un `403` con token válido es autorización, no
> autenticación: mirar `scp` y `roles`.

> Nunca respondas: "si el token es válido, el cliente está autorizado". Mejor: "un token válido prueba
> quién llama y para quién se emitió; la autorización es comprobar que trae el scope o el rol que exige
> esa operación y, para datos de negocio, que ese usuario concreto puede verlos".

---

## 9. ⚖ Validar en la API o en API Management

API Management puede validar el JWT **antes** de que la petición llegue al backend, con la policy
`validate-jwt` (o `validate-azure-ad-token`), [`05` §8](05-balanceo-entrega-global-y-api-management.md#8--políticas-de-api-management).

| Criterio | En la API (Spring Security) | En APIM (`validate-jwt`) |
|---|---|---|
| Qué valida bien | Todo, incluida la autorización fina por usuario y por dato | Firma, `aud`, `iss`, expiración, claims requeridos |
| Rechaza el tráfico basura | Después de que llegue a la app | En el borde, sin consumir la app |
| Si alguien salta APIM | Sigue protegida | Sin protección, si la API no valida |

```text
Regla de arquitectura:
APIM valida en el borde para rechazar pronto; la API valida siempre.
Nunca "la API confía en que APIM ya validó".
```

---

## 10. 🧱 Identidades de clientes: External ID y B2C

Todo lo anterior es identidad **de la plantilla** (*workforce*): empleados y aplicaciones del banco.
Para los **clientes** del banco —millones de personas que se registran solas, con login social o
local— existe **Microsoft Entra External ID**, con un tenant *external* propio, flujos de registro,
personalización de marca y proveedores de identidad sociales. Los conceptos (app registrations,
scopes, flujos, validación) son los mismos; cambia el tenant emisor.

| | Entra ID (workforce) | Entra External ID (customers) |
|---|---|---|
| Usuarios | Empleados, invitados B2B | Clientes finales |
| Registro | Lo crea el administrador | Autorregistro, social, local |
| Escala típica | Miles | Millones |

> 📝 **Contexto.** **Azure AD B2C**, el producto anterior para clientes, **dejó de venderse a clientes
> nuevos el 1 de mayo de 2025**. Quien ya lo tenía puede seguir usándolo y Microsoft promete soporte
> **al menos hasta mayo de 2030**; su tier P2 se discontinuó el 15 de marzo de 2026. Un diseño nuevo
> usa External ID.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "El ID token sirve para llamar a la API" | Se llama con un access token cuyo `aud` es la API |
| "Si el token es válido, el cliente está autorizado" | Hay que comprobar scope o rol, y la autorización de negocio sobre el usuario |
| "Los app roles son lo mismo que los roles de Azure RBAC" | Los define y los interpreta tu aplicación, vía el claim `roles` |
| "El scope le da el permiso al usuario" | Limita lo que la aplicación hace en su nombre; el permiso efectivo es la intersección |
| "En client credentials pido el scope `/Inventory.Write`" | Se pide `/.default` y llegan todos los app roles asignados |
| "Reenvío el token del usuario a la siguiente API" | Confused deputy; se usa on-behalf-of |
| "En un token v2 el `aud` es `api://…`" | En v2 es el client ID de la API |
| "Valido en APIM, así que la API no necesita validar" | La API valida siempre; APIM solo adelanta el rechazo |
| "Para clientes finales, Azure AD B2C" | Sin venta a clientes nuevos desde mayo de 2025; se usa External ID |

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia hay entre un permiso delegado y un permiso de aplicación, y qué claim trae cada uno en el token?
2. ¿Para qué sirve el Application ID URI de una API y qué forma tiene por defecto?
3. ¿Por qué un scope delegado no le da permisos al usuario?
4. ¿Qué consentimiento necesita un app role asignado a una aplicación y por qué?
5. ¿Qué problema resuelve PKCE en el flujo authorization code?
6. ¿Qué scope pide un cliente en client credentials y qué recibe?
7. `inv-api` necesita llamar a otra API como el analista que la llamó. ¿Qué flujo usas y por qué no reenvías el token?
8. ¿Cómo haces que la managed identity de `inv-projector` pueda escribir en `inv-api` sin ningún secreto?
9. Asignaste el app role a la managed identity y sus tokens siguen sin traer `roles`. ¿Qué pasa?
10. ¿Qué validan `issuer-uri` y `audiences` en un resource server Spring Boot, y qué valor lleva `audiences` con tokens v2?
11. Tu resource server acepta a los usuarios pero rechaza con `403` a todos los clientes máquina. ¿Qué está mal?
12. La API rechaza tokens con "The iss claim is not valid" aunque el tenant es el correcto. ¿Cuál es la causa más probable?
13. ¿Por qué no conviene autorizar con el claim `groups`?
14. ¿Validas el JWT en API Management, en la API o en ambos? Justifica.
15. ¿Qué usarías hoy para la identidad de los clientes finales de un banco y qué pasa con Azure AD B2C?

---

## 📚 Referencias oficiales

- Escenario de API web protegida (registro y configuración): https://learn.microsoft.com/en-us/entra/identity-platform/scenario-protected-web-api-app-configuration
- Registrar una aplicación: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app
- Exponer una API (scopes): https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-expose-web-apis
- Permisos y consentimiento: https://learn.microsoft.com/en-us/entra/identity-platform/permissions-consent-overview
- App roles: https://learn.microsoft.com/en-us/entra/identity-platform/howto-add-app-roles-in-apps
- Authorization code con PKCE: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow
- Client credentials: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow
- On-behalf-of: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-on-behalf-of-flow
- Device code: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-device-code
- Access tokens: versiones y validación: https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens
- Referencia de claims del access token (overage de grupos): https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference
- Manifiesto de la aplicación (`requestedAccessTokenVersion`): https://learn.microsoft.com/en-us/entra/identity-platform/reference-app-manifest
- Asignar un app role a una managed identity: https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/assign-app-role-managed-identity-azure-cli
- Spring Cloud Azure con Microsoft Entra ID: https://learn.microsoft.com/en-us/azure/developer/java/spring-framework/spring-security-support
- Guía de Spring Cloud Azure (BOM y versiones): https://learn.microsoft.com/en-us/azure/developer/java/spring-framework/developer-guide-overview
- Policy `validate-jwt` de API Management: https://learn.microsoft.com/en-us/azure/api-management/validate-jwt-policy
- ¿Qué es Microsoft Entra External ID?: https://learn.microsoft.com/en-us/entra/external-id/external-identities-overview
- Preguntas frecuentes de Azure AD B2C (fin de venta): https://learn.microsoft.com/en-us/azure/active-directory-b2c/faq
- `az ad app`: https://learn.microsoft.com/en-us/cli/azure/ad/app
- `az rest`: https://learn.microsoft.com/en-us/cli/azure/reference-index#az-rest

### Terceros (opcional)

- Resource server JWT de Spring Security: https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html
