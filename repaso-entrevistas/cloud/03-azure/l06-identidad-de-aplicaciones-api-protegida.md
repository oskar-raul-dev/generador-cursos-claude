# L06 — Identidad de aplicaciones: una API protegida con Entra ID

> **Objetivo:** convertir `inv-api` en un resource server que valida tokens de Entra ID, con dos
> clientes de naturaleza distinta: un humano que obtiene un token delegado con el scope
> `Inventory.Read` por el flujo device code, hecho a mano con `curl`, y una managed identity que
> obtiene un token de aplicación con el app role `Inventory.Write`. Por el camino se provocan los tres
> errores clásicos: la audiencia equivocada, el issuer de un token v1 y el `403` de un convertidor que
> ignora `roles`.
> **Se asume leído:** [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md) (app registrations,
> scopes, app roles, flujos y validación en Spring Boot) y [`09` §7](09-identidad-entra-id-y-managed-identities.md#7--tokens)
> (tokens).
> **Costo:** **$0.00**. Las app registrations no cobran, y las ejecuciones del job de prueba y las
> peticiones a `inv-api` caben de sobra en el free grant de Container Apps. El registry sigue cobrando
> su día, como desde [`L05`](l05-container-apps-revisiones-trafico-y-escala.md).
> **Duración:** 2–3 horas.
> **Prerrequisitos:** [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) terminado (`inv-api`
> en modo multiple, el registry y el environment), y un rol de Entra ID que permita registrar apps,
> dar consentimiento de administrador y asignar app roles: en un tenant propio creado con la cuenta
> gratuita, tu usuario es Global Administrator.
> **Qué queda encendido al terminar:** `inv-api` en la revisión `v5`, que exige tokens; las app
> registrations `inv-api` e `inv-cli` con sus service principals **en el tenant**, y la asignación del
> app role `Inventory.Write` a `inv-projector-id`. Nada cobra.
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026. Spring Boot **4.0.8**.

**Salto rápido:** [Qué se practica](#1--qué-se-practica-y-dónde-vive) · [Arranque](#2--arranque) ·
[Registrar la API](#3--registrar-la-api-a-propósito-sin-versión-de-token) ·
[Scope y app role](#4--el-scope-delegado-y-el-app-role) · [El cliente humano](#5--el-cliente-humano-inv-cli) ·
[La API valida](#6--la-api-empieza-a-validar) · [Audiencia](#7--error-1-la-audiencia-equivocada) ·
[Device code a mano](#8--un-token-de-usuario-con-device-code-a-mano) ·
[Issuer v1](#9--error-2-el-issuer-de-un-token-v1) ·
[El cliente máquina](#10--el-cliente-máquina-una-managed-identity) ·
[Roles ignorados](#11--error-3-el-403-de-un-convertidor-que-ignora-roles) ·
[Teardown](#12--teardown-y-lo-que-vive-en-el-tenant) · [Checklist](#-checklist-de-salida) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Qué se practica, y dónde vive

[`L02`](l02-entra-id-rbac-y-managed-identities.md) enseñó un plano: **tu código** obtiene un token para llamar a Azure. Este lab enseña el otro:
**tu API** valida los tokens que le llegan. Los dos se preguntan en toda entrevista de backend en Azure y
fallan de maneras distintas, por eso son dos labs ([`L00` §7.1](l00-idea-lab-practico.md#71-por-qué-nueve-labs)).

```text
                      Entra ID (tenant)
             ┌─────────────────────────────────────────┐
             │ inv-api (app registration + SP)          │
             │   scope Inventory.Read   app role        │
             │                          Inventory.Write │
             │ inv-cli (cliente público) ──consent──►   │
             └─────────────────────────────────────────┘
   analista ──device code──► token (scp)  ──GET  /items──────►  inv-api
   inv-projector-id ──MI──► token (roles) ──POST /movements──►  (valida aud, iss, firma)
```

Una advertencia de ubicación que importa para el teardown: **las app registrations no son recursos de
Azure**. Viven en el tenant de Entra ID, no en ninguna suscripción ni resource group, y `az group
delete` no las toca ([`L00` §7.3](l00-idea-lab-practico.md#73-el-resource-group-es-la-unidad-de-destrucción-con-letra-pequeña)).
Se crean y se borran con `az ad`, que habla con **Microsoft Graph**.

La doctrina de reparto lo justifica sin más: Keycloak en local enseña OIDC como concepto, pero no los
app roles de Entra, ni los tokens v2, ni una managed identity como cliente
([`L00` §8](l00-idea-lab-practico.md#8--emuladores-locales-qué-sirve-y-qué-miente)).

---

## 2. 🧱 Arranque

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
TENANT=$(az account show --query tenantId --output tsv)
FQDN=$(az containerapp show --name inv-api --resource-group inv-lab-rg \
  --query properties.configuration.ingress.fqdn --output tsv)
PROJ_ID=$(az identity show --name inv-projector-id --resource-group inv-lab-rg --query id --output tsv)
PROJ_PID=$(az identity show --name inv-projector-id --resource-group inv-lab-rg --query principalId --output tsv)
PROJ_CLIENT_ID=$(az identity show --name inv-projector-id --resource-group inv-lab-rg --query clientId --output tsv)
```

- `TENANT` es el tenant de Entra ID en el que confía tu suscripción: el emisor de todos los tokens del
  lab.
- Las tres variables `PROJ_*` son los identificadores de `inv-projector-id`, que en este lab hace de
  cliente máquina antes de que exista la app `inv-projector` de [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md).

---

## 3. 🧱 Registrar la API, a propósito sin versión de token

El registro sigue [`12` §2](12-identidad-de-aplicaciones-oauth-con-entra-id.md#2--registrar-la-api),
con **una omisión deliberada**: no se fija la versión de los access tokens. La sección 9 cobra esa
omisión.

```bash
API_APP_ID=$(az ad app create --display-name inv-api --sign-in-audience AzureADMyOrg \
  --query appId --output tsv)
API_OBJ_ID=$(az ad app show --id "$API_APP_ID" --query id --output tsv)
az ad app update --id "$API_APP_ID" --identifier-uris "api://$API_APP_ID"
API_SP_ID=$(az ad sp create --id "$API_APP_ID" --query id --output tsv)
echo "appId=$API_APP_ID objectId=$API_OBJ_ID spObjectId=$API_SP_ID"
```

- `az ad app create` crea la **app registration** (el application object). `--sign-in-audience
  AzureADMyOrg` la hace single-tenant. Sin `--requested-access-token-version`, la API recibirá tokens
  **v1**, porque el valor por defecto, `null`, equivale a v1.
- La app tiene **tres identificadores**, y cada uno se usa en un sitio: el `appId` (client ID), que es
  el `aud` de los tokens v2 y el sufijo del Application ID URI; el **object ID de la app
  registration**, que usa Graph para modificarla; y el **object ID del service principal**, que es el
  `resourceId` de las asignaciones de app roles.
- `--identifier-uris "api://$API_APP_ID"` fija el Application ID URI, prefijo de los scopes.
- `az ad sp create --id` crea el **service principal** de la API en el tenant. Sin él, Entra ID no
  emite tokens para esta API.

```text
[PENDIENTE DE CORRIDA] Tres GUIDs distintos: appId, objectId de la app registration y objectId del
service principal.
```

---

## 4. 🧱 El scope delegado y el app role

El **scope** `Inventory.Read` es para una aplicación que actúa en nombre de un usuario; el **app
role** `Inventory.Write`, para una aplicación que actúa como sí misma ([`12` §3](12-identidad-de-aplicaciones-oauth-con-entra-id.md#3--scopes-delegados-frente-a-app-roles)).
Los dos llevan un GUID que eliges tú:

```bash
READ_SCOPE_ID=$(uuidgen | tr 'A-F' 'a-f')
WRITE_ROLE_ID=$(uuidgen | tr 'A-F' 'a-f')

az rest --method patch \
  --url "https://graph.microsoft.com/v1.0/applications/$API_OBJ_ID" \
  --body "{
    \"api\": {
      \"requestedAccessTokenVersion\": null,
      \"oauth2PermissionScopes\": [{
        \"id\": \"$READ_SCOPE_ID\", \"value\": \"Inventory.Read\", \"type\": \"User\", \"isEnabled\": true,
        \"adminConsentDisplayName\": \"Leer el inventario\",
        \"adminConsentDescription\": \"Permite a la aplicación leer el inventario en nombre del usuario.\",
        \"userConsentDisplayName\": \"Leer tu inventario\",
        \"userConsentDescription\": \"Permite a la aplicación leer el inventario en tu nombre.\"
      }]
    },
    \"appRoles\": [{
      \"id\": \"$WRITE_ROLE_ID\", \"value\": \"Inventory.Write\", \"isEnabled\": true,
      \"allowedMemberTypes\": [\"Application\"],
      \"displayName\": \"Registrar movimientos\",
      \"description\": \"Permite a una aplicación registrar movimientos de inventario.\"
    }]
  }"
```

- La petición va a **Microsoft Graph**, `graph.microsoft.com`, no a ARM: la app registration es un
  objeto del directorio. `az rest` deduce la audiencia del token a partir de la URL
  ([`A01` §11](a01-az-de-supervivencia.md#11--az-rest-la-api-sin-intermediarios)).
- `--method patch` sobre `/applications/{objectId}` usa el **object ID de la app registration**, no el
  `appId`.
- **El objeto `api` se envía entero**, con `requestedAccessTokenVersion` incluido: al hacer `PATCH` de
  una propiedad compleja, lo que envías la sustituye. Mandar solo los scopes y confiar en que la
  versión se conserve es cómo se pierde configuración sin darse cuenta.
- `"type": "User"` hace que el scope admita consentimiento de usuario; `"Admin"` lo reservaría al
  administrador.
- `"allowedMemberTypes": ["Application"]` hace que el app role se pueda asignar a **aplicaciones**
  (service principals y managed identities), no a usuarios.
- `uuidgen | tr 'A-F' 'a-f'` genera un GUID en minúsculas, la forma en que Graph los devuelve.

```text
[PENDIENTE DE CORRIDA] Sin salida: un PATCH correcto a Graph devuelve 204 No Content.
```

Compruébalo leyendo lo que quedó:

```bash
az ad app show --id "$API_APP_ID" \
  --query "{uri:identifierUris[0], ver:api.requestedAccessTokenVersion, scopes:api.oauth2PermissionScopes[].value, roles:appRoles[].value}"
```

```text
[PENDIENTE DE CORRIDA] uri api://<appId>, ver null, scopes ["Inventory.Read"] y roles
["Inventory.Write"].
```

---

## 5. 🧱 El cliente humano, `inv-cli`

`inv-cli` representa la herramienta de línea de comandos de un analista. Es un **cliente público**: no
puede guardar un secreto, así que obtiene tokens con un flujo interactivo del usuario, aquí device code
([`12` §5](12-identidad-de-aplicaciones-oauth-con-entra-id.md#5--los-flujos)).

```bash
CLI_APP_ID=$(az ad app create --display-name inv-cli --sign-in-audience AzureADMyOrg \
  --is-fallback-public-client true --query appId --output tsv)
az ad sp create --id "$CLI_APP_ID" --output none

az ad app permission add --id "$CLI_APP_ID" --api "$API_APP_ID" \
  --api-permissions "$READ_SCOPE_ID=Scope"
az ad app permission admin-consent --id "$CLI_APP_ID"
```

- `--is-fallback-public-client true` marca la app como cliente público: habilita los flujos sin secreto,
  como device code. Sin él, el endpoint de token exigiría una credencial de cliente.
- `az ad app permission add --api-permissions "<id>=Scope"` declara que `inv-cli` **pide** el scope
  `Inventory.Read` de `inv-api`. `=Scope` significa permiso delegado; `=Role` sería un permiso de
  aplicación.
- `az ad app permission admin-consent` concede ese permiso **para todo el tenant**, como administrador:
  ningún usuario tendrá que aceptar una pantalla de consentimiento. Es lo que hace un banco con sus
  aplicaciones propias ([`12` §4](12-identidad-de-aplicaciones-oauth-con-entra-id.md#4--consentimiento)).

```text
[PENDIENTE DE CORRIDA] El permission add avisa de que hace falta conceder el consentimiento; el
admin-consent no imprime nada si funciona.
```

---

## 6. 🧱 La API empieza a validar

Ahora `inv-api` se convierte en resource server. Añade al `pom.xml` de `~/inv-lab/inv-api` el starter y
sube la versión a `0.3.0`:

```xml
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security-oauth2-resource-server</artifactId>
    </dependency>
```

- `spring-boot-starter-security-oauth2-resource-server` es el starter de Spring Boot 4 para un resource
  server: Spring Security más la validación de JWT. El nombre antiguo sin `security-` sigue publicado,
  pero está deprecado.

La configuración, con el emisor **v2** y la audiencia del client ID, como en
[`12` §7](12-identidad-de-aplicaciones-oauth-con-entra-id.md#7--validar-el-token-en-spring-boot):

```properties
# añadir a application.properties
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0
spring.security.oauth2.resourceserver.jwt.audiences=${INV_API_CLIENT_ID}
```

- Los dos valores llegan por variables de entorno: el mismo JAR sirve en cualquier tenant.

La seguridad, **todavía con el convertidor por defecto**, que solo mira `scp`. Es la omisión que cobra
la sección 11:

```java
// SecurityConfig.java — versión 0.3.0: el convertidor por defecto solo conoce scp
package dev.invlab.api;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
class SecurityConfig {

    @Bean
    SecurityFilterChain api(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/info", "/actuator/health/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/items/**").hasAuthority("SCOPE_Inventory.Read")
                        .requestMatchers(HttpMethod.POST, "/movements").hasAuthority("APPROLE_Inventory.Write")
                        .anyRequest().authenticated())
                .oauth2ResourceServer(oauth -> oauth.jwt(Customizer.withDefaults()));
        return http.build();
    }
}
```

Y los dos endpoints protegidos, en la clase de la aplicación:

```java
    // añadir a InventoryApiApplication (imports: java.util.List, ResponseEntity, Jwt,
    // @AuthenticationPrincipal, @PostMapping)
    @GetMapping("/items")
    public List<Map<String, Object>> items() {
        return List.of(Map.of("sku", "A-100", "store", "S-01", "quantity", 12));
    }

    @PostMapping("/movements")
    public ResponseEntity<Map<String, Object>> movement(@AuthenticationPrincipal Jwt jwt) {
        // quién llama: el oid del token, sea un usuario o una aplicación
        return ResponseEntity.accepted().body(Map.of("caller", jwt.getClaimAsString("oid")));
    }
```

- `/api/info` y las probes de Actuator quedan públicas; el resto exige un token válido.
- `GET /items` exige el scope delegado; `POST /movements`, el app role.

Construye, sube y despliega la revisión `v4` con las dos variables nuevas, y dale **todo el tráfico**
(la app está en modo multiple desde [`L05`](l05-container-apps-revisiones-trafico-y-escala.md)):

```bash
cd ~/inv-lab/inv-api
mvn -q package -DskipTests
docker build --platform linux/amd64 -t invlabacr472913.azurecr.io/inv-api:0.3.0 .
docker push invlabacr472913.azurecr.io/inv-api:0.3.0

az containerapp update --name inv-api --resource-group inv-lab-rg \
  --image invlabacr472913.azurecr.io/inv-api:0.3.0 --revision-suffix v4 \
  --set-env-vars AZURE_TENANT_ID="$TENANT" INV_API_CLIENT_ID="$API_APP_ID" --output none
az containerapp ingress traffic set --name inv-api --resource-group inv-lab-rg \
  --revision-weight inv-api--v3=0 inv-api--v4=100 --output none

curl -s -o /dev/null -w '%{http_code}\n' "https://$FQDN/items"
```

- `--set-env-vars` añade las variables a las que ya tenía la revisión (`AZURE_CLIENT_ID`,
  `PARTNER_API_KEY`); no las sustituye.
- La última línea llama sin token.

```text
[PENDIENTE DE CORRIDA] 401: sin Authorization, el resource server responde 401 con la cabecera
WWW-Authenticate: Bearer.
```

---

## 7. 🩺 Error 1: la audiencia equivocada

El primer impulso es usar el token que ya tienes, el de `az`:

```bash
ARM_TOKEN=$(az account get-access-token --query accessToken --output tsv)
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $ARM_TOKEN" "https://$FQDN/items"
curl -s -D - -o /dev/null -H "Authorization: Bearer $ARM_TOKEN" "https://$FQDN/items" | grep -i www-authenticate
```

- `-D -` imprime las cabeceras de la respuesta; el `grep` se queda con `WWW-Authenticate`, donde Spring
  Security explica por qué rechazó el token.

```text
[PENDIENTE DE CORRIDA] 401, y una cabecera WWW-Authenticate con error="invalid_token" y una
descripción que menciona el claim aud.
```

Es un token **válido**, firmado por tu tenant, para **otra audiencia**: ARM. La API lo rechaza porque
`audiences` exige su client ID. Si no lo hiciera, cualquier token del tenant —para Graph, para Storage,
para otra API con más permisos— serviría aquí ([`09` §7](09-identidad-entra-id-y-managed-identities.md#7--tokens)).

---

## 8. 🧱 Un token de usuario, con device code a mano

La forma cómoda sería MSAL o `az account get-access-token --scope`. El lab lo hace con `curl`, porque
así se ven las dos peticiones del [flujo device code](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-device-code)
que cualquier SDK esconde:

```bash
DC=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT/oauth2/v2.0/devicecode" \
  -d "client_id=$CLI_APP_ID" \
  --data-urlencode "scope=api://$API_APP_ID/Inventory.Read")
echo "$DC" | jq -r .message
DEVICE_CODE=$(echo "$DC" | jq -r .device_code)
```

- **Primera petición**, a `/devicecode`: el cliente (`client_id` de `inv-cli`) pide un código para el
  scope `api://<appId>/Inventory.Read`. No lleva secreto: es un cliente público.
- La respuesta trae `device_code` (para el cliente), `user_code` y `verification_uri` (para el usuario),
  `expires_in` —15 minutos por defecto— e `interval`, los segundos entre sondeos.
- `jq -r .message` imprime la instrucción para el usuario: abrir la URL e introducir el código.

```text
[PENDIENTE DE CORRIDA] "To sign in, use a web browser to open the page
https://microsoft.com/devicelogin and enter the code XXXXXXXXX to authenticate."
```

Abre la URL en el navegador, introduce el código e inicia sesión con tu usuario. Después, la **segunda
petición**, que se repite hasta que el usuario termina:

```bash
until TOKEN_RESPONSE=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT/oauth2/v2.0/token" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
  -d "client_id=$CLI_APP_ID" -d "device_code=$DEVICE_CODE") \
  && [ "$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')" != "authorization_pending" ]; do
  sleep 5
done
USER_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r .access_token)
```

- `grant_type=urn:ietf:params:oauth:grant-type:device_code` es el tipo de concesión del flujo.
- Mientras el usuario no ha terminado, `/token` responde el error `authorization_pending`, y el cliente
  vuelve a preguntar tras `interval` segundos. El bucle hace eso.

Decodifica el token con la función `jwt()` de [`L02` §8](l02-entra-id-rbac-y-managed-identities.md#8--un-token-decodificado),
ampliada con `ver`:

```bash
echo "$USER_TOKEN" | cut -d. -f2 | python3 -c "import sys,base64,json; p=sys.stdin.read().strip(); p+='='*(-len(p)%4); d=json.loads(base64.urlsafe_b64decode(p)); print(json.dumps({k:d.get(k) for k in ('ver','iss','aud','scp','oid')}, indent=2))"
```

```text
[PENDIENTE DE CORRIDA] "ver": "1.0", "iss": "https://sts.windows.net/<tenant>/", "aud":
"api://<appId>", "scp": "Inventory.Read" y tu oid.
```

Mira `ver`. El token es **v1**: es la omisión de la sección 3.

---

## 9. 🩺 Error 2: el issuer de un token v1

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $USER_TOKEN" "https://$FQDN/items"
curl -s -D - -o /dev/null -H "Authorization: Bearer $USER_TOKEN" "https://$FQDN/items" | grep -i www-authenticate
```

```text
[PENDIENTE DE CORRIDA] 401, con error="invalid_token" y una descripción sobre el claim iss (o
sobre aud: en v1, el aud es el Application ID URI y no el client ID).
```

La API valida contra el emisor `https://login.microsoftonline.com/<tenant>/v2.0`, y un token v1 lo emite
`https://sts.windows.net/<tenant>/`. El tenant es el correcto; la versión, no. Y **no la decide el
cliente**: la decide la API receptora con `requestedAccessTokenVersion` en **su** app registration
([`09`](09-identidad-entra-id-y-managed-identities.md), pregunta 11). La corrección, con el objeto `api`
entero otra vez:

```bash
az rest --method patch \
  --url "https://graph.microsoft.com/v1.0/applications/$API_OBJ_ID" \
  --body "$(az ad app show --id "$API_APP_ID" --query api --output json \
            | jq '{api: (. + {requestedAccessTokenVersion: 2})}')"
az ad app show --id "$API_APP_ID" --query api.requestedAccessTokenVersion
```

- `az ad app show --query api` lee el objeto `api` actual, con sus scopes; `jq` le cambia solo la
  versión y lo envuelve en el cuerpo del `PATCH`. Así el scope no se pierde.

```text
[PENDIENTE DE CORRIDA] 2
```

Repite la sección 8 para obtener un token **nuevo** —el anterior sigue siendo v1 hasta que caduque— y
decodifícalo:

```text
[PENDIENTE DE CORRIDA] "ver": "2.0", "iss": "https://login.microsoftonline.com/<tenant>/v2.0",
"aud": "<appId>" (el client ID, no el URI) y "scp": "Inventory.Read".
```

Y las dos operaciones:

```bash
curl -s -w '\n%{http_code}\n' -H "Authorization: Bearer $USER_TOKEN" "https://$FQDN/items"
curl -s -o /dev/null -w '%{http_code}\n' -X POST -H "Authorization: Bearer $USER_TOKEN" "https://$FQDN/movements"
```

```text
[PENDIENTE DE CORRIDA] La lista con el item A-100 y 200; después, 403.
```

El `403` es el comportamiento correcto: el token del analista es válido y trae `scp`, pero registrar
movimientos exige el app role. **`401` es "no sé quién eres"; `403` es "sé quién eres y no puedes"**.

---

## 10. 🧱 El cliente máquina: una managed identity

`inv-projector-id` tiene que poder registrar movimientos. Es client credentials **sin credencial**: la
managed identity pide el token al endpoint de identidad del host. El paso que falta es **asignarle el
app role**, que se hace con Graph porque no hay comando `az` para ello ([`12` §6](12-identidad-de-aplicaciones-oauth-con-entra-id.md#6--una-managed-identity-como-cliente-de-tu-api)):

```bash
az rest --method post \
  --url "https://graph.microsoft.com/v1.0/servicePrincipals/$PROJ_PID/appRoleAssignments" \
  --body "{\"principalId\": \"$PROJ_PID\", \"resourceId\": \"$API_SP_ID\", \"appRoleId\": \"$WRITE_ROLE_ID\"}" \
  --query "{principal:principalDisplayName, resource:resourceDisplayName, role:appRoleId}"
```

- La URL cuelga del service principal **beneficiario**, la managed identity (`principalId` de
  `inv-projector-id`).
- `resourceId` es el **object ID del service principal de `inv-api`**, no su `appId`: el recurso que
  expone el rol. Confundirlos es el error más frecuente de este paso.
- `appRoleId` es el GUID que elegiste para `Inventory.Write`.
- Asignar app roles es un permiso **del directorio** (Application Administrator, Cloud Application
  Administrator o Global Administrator), no de Azure RBAC: el Owner de la suscripción, por sí solo, no
  puede.

```text
[PENDIENTE DE CORRIDA] principal inv-projector-id, resource inv-api y el GUID del rol.
```

Para ejercer esa identidad hace falta un host de Azure. `inv-projector` no existe hasta [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md), así que el
lab usa un **Container Apps job** efímero con la imagen oficial de la CLI, que inicia sesión con la
managed identity y llama a la API:

```bash
read -r -d '' PROBE <<'EOF'
az login --identity --client-id "$CLIENT_ID" --allow-no-subscriptions --output none &&
az account get-access-token --scope "api://$API_APP_ID/.default" --query accessToken --output tsv |
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | {ver, aud, roles}' &&
az rest --method post --url "$API_URL/movements" --resource "api://$API_APP_ID" --body '{}'
EOF

az containerapp job create \
  --name inv-token-probe \
  --resource-group inv-lab-rg \
  --environment inv-lab-env \
  --trigger-type Manual \
  --replica-timeout 300 --replica-retry-limit 0 --parallelism 1 --replica-completion-count 1 \
  --image mcr.microsoft.com/azure-cli:2.90.0 \
  --mi-user-assigned "$PROJ_ID" \
  --cpu 0.25 --memory 0.5Gi \
  --env-vars CLIENT_ID="$PROJ_CLIENT_ID" API_APP_ID="$API_APP_ID" API_URL="https://$FQDN" \
  --command "/bin/bash" --args "-c" "$PROBE" \
  --tags project=inv-lab env=lab --output none
```

- El script va en un heredoc con `'EOF'` entre comillas simples: las variables **no** se expanden en tu
  terminal, sino dentro del contenedor, con los valores de `--env-vars`.
- `az login --identity --client-id` inicia sesión con **esa** user-assigned identity.
  `--allow-no-subscriptions` hace falta porque `inv-projector-id` no tiene ningún rol de Azure RBAC en
  la suscripción; sin él, el login falla al no encontrar suscripciones.
- `get-access-token --scope "api://<appId>/.default"` es client credentials: `/.default` pide **todos**
  los app roles asignados para esa API; pedir `/Inventory.Write` no funciona en este flujo.
- El `jq` decodifica el payload con el relleno de base64url y muestra `ver`, `aud` y `roles`.
- `az rest --resource "api://<appId>"` llama a una URL que no es de Azure, así que hay que decirle para
  qué audiencia pedir el token ([`A01` §11](a01-az-de-supervivencia.md#11--az-rest-la-api-sin-intermediarios)).
- `--trigger-type Manual` crea un job que solo corre cuando lo arrancas; `--replica-timeout 300` lo
  corta a los cinco minutos; `--replica-retry-limit 0`, sin reintentos.
- `--mi-user-assigned` es el nombre del flag de identidad en `az containerapp job create` (en `az
  containerapp create` es `--user-assigned`).
- `mcr.microsoft.com/azure-cli:2.90.0` es la imagen de [`A01` §2](a01-az-de-supervivencia.md#2--instalación-y-versión-fija),
  con versión fija. Es pública y no necesita `AcrPull`.

> ⚠️ **Un app role recién asignado puede tardar en aparecer en `roles`.** Los servicios cachean el token
> de una managed identity hasta unas 24 horas ([`10` §7](10-autorizacion-rbac-policy-y-gobierno.md#7--propagación-caché-y-límites)).
> Si la primera ejecución trae `roles: null`, no es la configuración: es la caché. Aquí la asignación se
> hizo antes del primer token de esa identidad para esta API, que es lo que lo evita.

---

## 11. 🩺 Error 3: el `403` de un convertidor que ignora `roles`

Arranca el job y lee su salida:

```bash
EXEC=$(az containerapp job start --name inv-token-probe --resource-group inv-lab-rg --query name --output tsv)
sleep 60
az containerapp job logs show --name inv-token-probe --resource-group inv-lab-rg \
  --execution "$EXEC" --container inv-token-probe --format text
```

- `job start` crea una **ejecución** y devuelve su nombre.
- `job logs show --execution` muestra la salida de consola de esa ejecución. El contenedor de un job
  creado con `--image` se llama como el job.

```text
[PENDIENTE DE CORRIDA] El JSON decodificado con "ver": "2.0", "aud": "<appId>" y "roles":
["Inventory.Write"], y después el error de az rest: Forbidden (403).
```

El token trae `roles: ["Inventory.Write"]` y la API responde `403`. Es la pregunta 11 de
[`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md), vista de verdad: **el convertidor por
defecto de Spring solo mapea `scp` a `SCOPE_*` e ignora `roles`**. El token de aplicación llega sin
authorities y no cumple `hasAuthority("APPROLE_Inventory.Write")`. Los usuarios funcionaban porque su
token trae `scp`.

La corrección es el convertidor de [`12` §7](12-identidad-de-aplicaciones-oauth-con-entra-id.md#7--validar-el-token-en-spring-boot):
en `SecurityConfig`, cambia `oauth.jwt(Customizer.withDefaults())` por
`oauth.jwt(jwt -> jwt.jwtAuthenticationConverter(entraIdConverter()))` y añade el método
`entraIdConverter()` tal cual lo muestra `12`, que suma `roles` con el prefijo `APPROLE_`. Sube la versión
a `0.3.1` y despliega:

```bash
mvn -q package -DskipTests
docker build --platform linux/amd64 -t invlabacr472913.azurecr.io/inv-api:0.3.1 .
docker push invlabacr472913.azurecr.io/inv-api:0.3.1
az containerapp update --name inv-api --resource-group inv-lab-rg \
  --image invlabacr472913.azurecr.io/inv-api:0.3.1 --revision-suffix v5 --output none
az containerapp ingress traffic set --name inv-api --resource-group inv-lab-rg \
  --revision-weight inv-api--v4=0 inv-api--v5=100 --output none

EXEC=$(az containerapp job start --name inv-token-probe --resource-group inv-lab-rg --query name --output tsv)
sleep 60
az containerapp job logs show --name inv-token-probe --resource-group inv-lab-rg \
  --execution "$EXEC" --container inv-token-probe --format text
```

```text
[PENDIENTE DE CORRIDA] El mismo token decodificado, y esta vez la respuesta 202 de la API:
{"caller": "<principalId de inv-projector-id>"}.
```

El `caller` es el `oid` del token: el **object ID del service principal de la managed identity**. Es con
lo que la API sabe qué aplicación registró el movimiento.

Repite con el analista: `GET /items` sigue en `200` y `POST /movements`, en `403`. El convertidor suma
authorities; no cambia quién puede qué.

> 🩺 **Diagnóstico.** Ante un `401` o un `403` de un resource server, decodifica el token y compara
> tres claims con la configuración: `aud` con `audiences`, `iss` con `issuer-uri`, `ver` con lo que
> espera la API. Si los tres cuadran y es `403`, mira `scp` y `roles` contra la regla, y el convertidor
> que los traduce.

---

## 12. 🧪 Teardown, y lo que vive en el tenant

Borra el job, que ya cumplió:

```bash
az containerapp job delete --name inv-token-probe --resource-group inv-lab-rg --yes
az containerapp revision deactivate --name inv-api --resource-group inv-lab-rg --revision inv-api--v4
az containerapp revision deactivate --name inv-api --resource-group inv-lab-rg --revision inv-api--v3
```

| Objeto | Dónde vive | ¿Cobra? | Quién lo destruye |
|---|---|---|---|
| `inv-api` (revisión `v5`) | `inv-lab-rg` | Dentro del free grant | [`L09`](l09-costos-y-destruccion-verificada.md) |
| App registration y SP `inv-api` | **Tenant** | No | [`L09`](l09-costos-y-destruccion-verificada.md), con `az ad app delete` |
| App registration y SP `inv-cli` | **Tenant** | No | [`L09`](l09-costos-y-destruccion-verificada.md), con `az ad app delete` |
| Consentimiento de `inv-cli` | **Tenant** | No | Con la app |
| Asignación de `Inventory.Write` a `inv-projector-id` | **Tenant** | No | Con la identidad o con la app |
| Job `inv-token-probe` | `inv-lab-rg` | No | Borrado |

> ⚠️ **Una app registration borrada no desaparece.** Queda **30 días en estado suspendido** en los
> objetos eliminados de Entra ID, recuperable, antes del borrado permanente
> ([`L00` §7.3](l00-idea-lab-practico.md#73-el-resource-group-es-la-unidad-de-destrucción-con-letra-pequeña)).
> No cobra, pero ocupa su nombre en listados y puede confundir una recreación. [`L09`](l09-costos-y-destruccion-verificada.md) la borra y la
> elimina de forma permanente.

Guarda los identificadores en tus notas: [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) los necesita.

```bash
echo "API_APP_ID=$API_APP_ID API_SP_ID=$API_SP_ID CLI_APP_ID=$CLI_APP_ID WRITE_ROLE_ID=$WRITE_ROLE_ID"
```

---

## 📋 Checklist de salida

- [ ] `az ad app show --id "$API_APP_ID"` devuelve `requestedAccessTokenVersion: 2`, el scope `Inventory.Read` y el app role `Inventory.Write`.
- [ ] Viste el `401` por audiencia con el token de ARM.
- [ ] Hiciste el flujo device code con dos `curl` y viste `authorization_pending` mientras iniciabas sesión.
- [ ] Viste el token v1 rechazado por issuer, y el v2 con `aud` igual al client ID.
- [ ] El analista obtiene `200` en `GET /items` y `403` en `POST /movements`.
- [ ] Viste el `403` del cliente máquina con `roles` en el token, y el `202` tras añadir el convertidor.
- [ ] El job `inv-token-probe` ya no existe y solo `inv-api--v5` recibe tráfico.
- [ ] Anotaste `API_APP_ID`, `API_SP_ID`, `CLI_APP_ID` y `WRITE_ROLE_ID`.

## 🏁 La señal de que quedó bien

`curl https://$FQDN/items` sin token devuelve `401`; con el token v2 del analista, `200`; y un token de
`inv-projector-id` con `roles: ["Inventory.Write"]` registra un movimiento con `202`. Puedes explicar, para
cada uno de los tres errores provocados, qué claim lo delató.

---

## 🧠 Preguntas rápidas

1. ¿Por qué las app registrations sobreviven a `az group delete` y con qué herramienta se gestionan?
2. ¿Para qué sirven el `appId`, el object ID de la app registration y el object ID de su service principal?
3. ¿Por qué el `PATCH` a Graph envía el objeto `api` entero y no solo los scopes?
4. ¿Qué hace `--is-fallback-public-client true` y por qué lo necesita `inv-cli`?
5. ¿Qué diferencia hay entre `az ad app permission add` y `az ad app permission admin-consent`?
6. ¿Por qué un token de ARM válido recibe `401` en `inv-api`?
7. ¿Cuáles son las dos peticiones del flujo device code y qué significa `authorization_pending`?
8. Tu token trae `ver: 1.0` y la API lo rechaza por issuer. ¿Quién decide la versión y cómo se arregla?
9. ¿Por qué el analista recibe `403` en `POST /movements` y por qué es correcto?
10. ¿Por qué la asignación del app role a la managed identity se hace con Graph, qué es `resourceId` y quién puede hacerla?
11. ¿Por qué el job necesita `--allow-no-subscriptions` y qué pide `/.default`?
12. El token de la managed identity trae `roles: ["Inventory.Write"]` y la API responde `403`. ¿Qué pasa?
13. La primera ejecución del job trae `roles: null`. ¿Qué sospechas antes que un error de configuración?
14. ¿Qué pasa con una app registration borrada y por qué importa en el teardown?

---

## 📚 Referencias oficiales

- Registrar una aplicación en Entra ID: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app
- Exponer una API (scopes): https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-expose-web-apis
- App roles: https://learn.microsoft.com/en-us/entra/identity-platform/howto-add-app-roles-in-apps
- Referencia de `az ad app`: https://learn.microsoft.com/en-us/cli/azure/ad/app
- Referencia de `az ad app permission`: https://learn.microsoft.com/en-us/cli/azure/ad/app/permission
- Recurso `application` de Microsoft Graph: https://learn.microsoft.com/en-us/graph/api/resources/application
- Actualizar una aplicación con Graph: https://learn.microsoft.com/en-us/graph/api/application-update
- Asignar un app role a un service principal con Graph: https://learn.microsoft.com/en-us/graph/api/serviceprincipal-post-approleassignments
- Flujo device code: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-device-code
- Flujo client credentials: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow
- Access tokens (versiones, claims y validación): https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens
- Asignar un app role a una managed identity: https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/assign-app-role-managed-identity-azure-cli
- Jobs de Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/jobs
- Referencia de `az containerapp job`: https://learn.microsoft.com/en-us/cli/azure/containerapp/job
- Iniciar sesión con una managed identity en la CLI: https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-managed-identity
- Restaurar o eliminar una app registration borrada: https://learn.microsoft.com/en-us/entra/identity-platform/howto-restore-app

### Terceros (opcional)

- Spring Security, resource server con JWT: https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html
