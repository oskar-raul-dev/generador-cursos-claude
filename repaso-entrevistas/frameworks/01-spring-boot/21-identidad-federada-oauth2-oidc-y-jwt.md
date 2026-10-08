# 21 — Identidad federada: OAuth2, OIDC y JWT

> **Objetivo:** saber de dónde sale la identidad cuando no la emites tú, y poder decir
> **qué valida exactamente `inv-api` en cada petición**, en qué orden y con qué clave.
> **Asume:** [`20`](20-spring-security-el-mecanismo.md) entero —la cadena de filtros, el
> `SecurityContextHolder` y el 401/403 no se repiten aquí— y [`08`](08-modelo-de-ejecucion-web.md).
> **Vigencia:** 19 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 ·
> Spring Security 6.5.11 (la versión que arrastra el BOM de Boot 3.5.16) · Java 21.

---

## 1. 🧭 El problema: la credencial que no puede viajar

`inv-api` no tiene usuarios: están en el directorio corporativo, y otros seis servicios
necesitan saber quién llama. Que cada servicio tenga su tabla y su `UserDetailsService`
produce seis copias de la contraseña, seis políticas de expiración y ningún sitio donde
revocar a alguien que se fue el viernes. OAuth2 resuelve **otro** problema, y esa es la
primera precisión de entrevista: no existe para autenticar usuarios, existe para que un
software acceda a un recurso **en nombre** de alguien sin recibir su contraseña.

```text
resource owner        el humano dueño del dato          analyst@invlab.example
client                el software que quiere el dato    el portal web, otro servicio
authorization server  el que emite tokens               Keycloak, Entra ID, Cognito
resource server       el que guarda y protege el dato   inv-api  ← tú estás aquí
```

- **El curso vive casi entero en la última fila.** En banca tú escribes el resource server: el
  authorization server lo opera el equipo de identidad y el client es el portal de otro equipo.
- **`inv-api` nunca ve la contraseña.** Ve un token que otro emitió: si no la ves, todo se
  reduce a decidir si te fías del papel.

> Nunca respondas: ~~"OAuth2 sirve para autenticar usuarios"~~. Mejor: "OAuth2 es un
> framework de **autorización delegada**; la autenticación de usuarios la añade OIDC encima,
> y es una capa distinta con su propio token."

El diseño de la federación —a quién se confía emitir, zero-trust, dónde se dibuja el perímetro—
es del corpus de arquitectura —[`04-seguridad` §04 — propagación de identidad](../../arquitectura/01-bases/04-seguridad/04-propagacion-de-identidad.md)—; aquí está el mecanismo de Spring.

---

## 2. 🧱 OIDC encima de OAuth2, y los dos tokens que no se confunden

Si OAuth2 no autentica, ¿de dónde sale el "quién eres"? De **OpenID Connect**, una capa
sobre OAuth2 —no un competidor— que añade el scope `openid`, un token nuevo llamado
`id_token` y un documento de descubrimiento estándar.

| | Access token | ID token |
|---|---|---|
| Lo define | OAuth2 | OIDC |
| Para quién es | el **resource server** | el **client** |
| Qué dice | qué puede hacer el portador | quién se autenticó y cuándo |
| Formato | opaco o JWT, decide el emisor | JWT siempre |

- **El único que `inv-api` debe aceptar es el access token.** Quien valida un `id_token` acepta
  un documento dirigido a otro: su `aud` es el client, no tú. Pasa cada vez que el portal
  "manda el token que tenía a mano".
- **El descubrimiento ahorra media configuración.** El emisor publica un JSON en
  `.../.well-known/openid-configuration` con sus endpoints —entre ellos `jwks_uri`, del que sale
  §5— y Boot lo lee desde `issuer-uri`.
- **Los flujos vivos son dos**: *authorization code con PKCE* para un humano con navegador, y
  *client credentials* para servicio a servicio (§8). *Implicit* devolvía el token en la URL y
  *password grant* obliga al client a manejar la contraseña: nombrarlos como opción cuesta caro.

---

## 3. 🧱 El JWT por dentro: tres partes, y solo una está protegida

Un JWT son tres bloques —`header.payload.firma`— separados por puntos y codificados en
**Base64URL**, que no es cifrado: es un alfabeto seguro para URLs. Cualquiera con el token
lee el contenido, sin clave y sin permiso. Decodificado, es JSON legible:

```json
// header
{ "alg": "RS256", "kid": "inv-202609", "typ": "JWT" }
// payload (claims)
{ "iss": "https://idp.invlab.example/realms/inv", "aud": ["inv-api"], "sub": "8f2c1e40-...",
  "exp": 1790000900, "nbf": 1790000000, "iat": 1790000000,
  "scope": "inventory.read inventory.write",
  "realm_access": { "roles": ["analyst"] } }
```

- **`alg`** dice con qué algoritmo se firmó y **`kid`** con cuál de las claves del emisor: es
  lo que permite rotar claves sin reiniciar nada (§5).
- **`iss`** es quién lo emitió y **`aud`** para quién: los dos claims que deciden si este papel
  es tuyo. **`sub`** es el identificador estable del sujeto —no el email, que cambia—.
- **`exp` y `nbf`** delimitan la ventana de validez en segundos desde epoch: `nbf` es *not
  before*, para tokens emitidos con antelación; `iat` es informativo. **La firma cubre
  `header.payload` enteros**: cambiar un claim invalida el token, pero no lo oculta.

> **⚠️ La sobregeneralización número uno.** ~~"El JWT va cifrado"~~ es falso: va **firmado**,
> que garantiza integridad y origen, no confidencialidad. Existe JWE para cifrarlo, casi nadie
> lo usa, y la protección real del contenido es TLS más no meter dentro lo que no debe
> estar (§9).

---

## 4. 🧱 Qué valida un resource server, y en qué orden

Aquí está la segunda sobregeneralización: *"validar el token es comprobar la firma"*. La
firma es el primer paso de cinco, y es el único que la mayoría recuerda.

```text
1. formato        ¿tres partes, header parseable, alg soportado?   → si no: invalid_token
2. firma          ¿coincide con la clave pública del kid?          → si no: invalid_token
3. iss            ¿el emisor es el que configuraste?               → JwtIssuerValidator
4. exp / nbf      ¿estamos dentro de la ventana, con clock skew?   → JwtTimestampValidator
5. aud            ¿este token era para mí?                         → ❌ no, por defecto
```

- **Los pasos 3 y 4 son el validador por defecto** de `JwtValidators.createDefaultWithIssuer(...)`:
  la reference lo dice con todas las letras —valida `exp`, `nbf` e `iss`—.
- **El paso 5 no está incluido**, y es la trampa que se cobra en producción: sin `aud`, un token
  emitido por el mismo IdP para el servicio de nóminas entra en `inv-api` con la firma perfecta.
  Lo arregla una propiedad de Boot (§6) o un `JwtClaimValidator<List<String>>(AUD, ...)`.
- **El clock skew por defecto es de 60 segundos** (`new JwtTimestampValidator(Duration.ofSeconds(60))`),
  porque el reloj del emisor y el tuyo no son el mismo. Ampliarlo a cinco minutos "por si
  acaso" alarga cinco minutos la vida de todo token caducado.
- **Falla siempre igual**, y conviene reconocer la cabecera literal:

```text
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer error_code="invalid_token", error_description="Unsupported algorithm of none", error_uri="https://datatracker.ietf.org/doc/html/rfc6750#section-3.1"
```

Nada de esto valida **autorización**: un token válido de alguien sin permisos sigue terminando
en el 403 de [`20` §9](20-spring-security-el-mecanismo.md#9--401-frente-a-403-quién-los-escribe).

---

## 5. ⚖ Firma simétrica, asimétrica y el JWK Set endpoint

¿Por qué un servicio que nunca habló con el IdP puede comprobar su firma? Depende del
algoritmo, y la elección no es un detalle criptográfico: es de operación.

| | HS256 (simétrica) | RS256 / ES256 (asimétrica) |
|---|---|---|
| Clave | un secreto compartido | privada firma, pública verifica |
| Quién puede emitir | todo el que pueda verificar | solo el IdP |
| Repartir la clave | a cada resource server, en secreto | pública, por HTTP |

Con HS256 y seis servicios tienes el mismo secreto en seis sitios, y **cualquiera de ellos
puede fabricar tokens que los otros cinco aceptan**. Por eso la federación usa asimétrica y por
eso existe el **JWK Set**: un endpoint público del emisor con sus claves de verificación en
JSON, cada una con su `kid`.

```text
inv-api arranca / primera petición
   └─ GET .../.well-known/openid-configuration → lee jwks_uri
        └─ GET .../protocol/openid-connect/certs → cachea el JWK Set en memoria
              └─ llega un JWT con kid=inv-202609 → ¿está en caché?
                    sí → verifica     no → recarga el JWK Set y reintenta
```

- **La rotación funciona sola gracias al `kid`.** El IdP publica la clave nueva **antes** de
  firmar con ella y, ante un `kid` desconocido, el decoder recarga el set. Sin la caché habría
  una llamada HTTP al IdP por petición.
- **Cuándo se resuelve el emisor importa**: con `issuer-uri`, Boot llama al descubrimiento en el
  arranque, y si el IdP no está arriba la aplicación no arranca. Con `jwk-set-uri` fija esa
  llamada se aplaza, a cambio de escribir la URL a mano y de que Boot ya no valide el `iss`.

> **⏱️ Costo en runtime.** Verificar RS256 son microsegundos de CPU y cero E/S mientras la clave
> esté en caché, contra la consulta y la conexión del pool por petición del `loadUserByUsername`
> de [`20` §4](20-spring-security-el-mecanismo.md#4--autenticación-quién-compara-la-credencial).

---

## 6. 🧱 `inv-api` como resource server: dos propiedades y un matcher

Con `spring-boot-starter-oauth2-resource-server` en el `pom.xml`, dos propiedades y una cadena,
`inv-api` valida tokens: la de
[`20` §2](20-spring-security-el-mecanismo.md#2--security-es-un-solo-filtro-y-por-dentro-son-veinte)
estrena el `BearerTokenAuthenticationFilter`.

```properties
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://idp.invlab.example/realms/inv
spring.security.oauth2.resourceserver.jwt.audiences=inv-api
```

```java
@Bean
@Order(1)
SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
    http
        .securityMatcher("/api/**")
        .authorizeHttpRequests(auth -> auth
            .requestMatchers(HttpMethod.GET, "/api/inventory/**").hasAuthority("SCOPE_inventory.read")
            .anyRequest().authenticated())
        .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
        .csrf(csrf -> csrf.disable())                                    // justificado en 19 §11
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
    return http.build();
}
```

- **El starter `-resource-server` valida tokens; `-client` los pide.** Confundirlos produce un
  arranque que exige un `client-id` que no tienes. Un servicio puede necesitar los dos: resource
  server para lo que recibe, client para lo que llama (§8).
- **`issuer-uri`** dispara el descubrimiento OIDC y **además** configura el
  `JwtIssuerValidator`. **`audiences`** es la propiedad de Boot que añade el quinto paso de §4
  sin escribir un validador a mano; sin ella el `aud` no se mira.
- **`.oauth2ResourceServer(...jwt(...))`** registra el `BearerTokenAuthenticationFilter` —que
  lee `Authorization: Bearer ...`— y un `JwtAuthenticationProvider` con su `NimbusJwtDecoder`.
  Sin esta línea las propiedades no hacen nada: la cadena la declaras tú.
- **`csrf.disable()` y `STATELESS`** valen aquí por el argumento de
  [`20` §11](20-spring-security-el-mecanismo.md#11--csrf-cors-y-sesión-las-tres-que-rompen-una-api),
  y **`hasAuthority("SCOPE_inventory.read")` lleva prefijo** porque así llegan los scopes: ese
  prefijo es todo el §7.

> **🩺 Diagnóstico.** Un 401 con `WWW-Authenticate: Bearer` incluso con un token bueno: mira el
> reloj del contenedor, si `issuer-uri` lleva una barra sobrante —el `iss` se compara como
> string— y sube `logging.level.org.springframework.security.oauth2=DEBUG`.

---

## 7. 🧱 De claims a authorities: el converter que casi todos terminan escribiendo

Por defecto, `JwtGrantedAuthoritiesConverter` (existe desde Security 5.2) lee el claim `scope`
o `scp`, lo parte por espacios y prefija cada valor con `SCOPE_`. Con scopes planos eso alcanza;
con Keycloak no, porque los roles llegan **anidados** en
`"realm_access": { "roles": ["analyst", "ops"] }`, y ahí no llega ninguna propiedad:
`...jwt.authorities-claim-name` sólo lee un claim de primer nivel. De ahí el converter:

```java
@Bean
JwtAuthenticationConverter jwtAuthenticationConverter() {
    JwtGrantedAuthoritiesConverter scopes = new JwtGrantedAuthoritiesConverter();  // SCOPE_*
    JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
    converter.setPrincipalClaimName("preferred_username");   // en vez de sub
    converter.setJwtGrantedAuthoritiesConverter(jwt -> {
        Collection<GrantedAuthority> authorities = new ArrayList<>(scopes.convert(jwt));
        Map<String, Object> realmAccess = jwt.getClaimAsMap("realm_access");
        if (realmAccess != null && realmAccess.get("roles") instanceof Collection<?> roles) {
            // los roles de Keycloak llegan en minúscula y sin prefijo; hasRole() espera ROLE_MAYÚSCULA
            roles.forEach(r -> authorities.add(
                    new SimpleGrantedAuthority("ROLE_" + r.toString().toUpperCase(Locale.ROOT))));
        }
        return authorities;
    });
    return converter;
}
```

- **Declararlo como `@Bean` basta:** Boot lo recoge y se lo pasa al `JwtAuthenticationProvider`.
- **`setPrincipalClaimName`** cambia qué devuelve `Authentication#getName()`: `sub` por defecto,
  un UUID ilegible; `preferred_username` se lee mejor pero **no es estable**, porque un usuario
  puede renombrarse. Para correlacionar, `sub`; para leer, el otro.
- **Sumar, no reemplazar:** si devuelves solo los roles, pierdes los `SCOPE_` y toda regla escrita contra ellos empieza a dar 403 sin aviso.
- **El prefijo `ROLE_` a mano** es obligatorio si quieres `hasRole("ANALYST")`, por lo de
  [`20` §7](20-spring-security-el-mecanismo.md#7--autorización-http-y-el-prefijo-role_): la
  regla dice `hasRole`, el token trae `analyst`, nadie prefijó, y sale un 403 silencioso.
- **Y las mayúsculas cuentan tanto como el prefijo:** `ROLE_analyst` no satisface
  `hasRole("ANALYST")` y el 403 es idéntico al de no prefijar. De ahí el `toUpperCase(Locale.ROOT)`,
  con locale explícito porque el turco convierte la `i` en `ı`. La alternativa es escribir la regla
  como llega el token, `hasAuthority("ROLE_analyst")`; lo que no vale es mezclar las dos.
- **`instanceof Collection<?> roles`** es un pattern match de Java 21: un cast ciego revienta
  con `ClassCastException` si el IdP cambia el formato del claim.

Todo esto se monta contra un Keycloak real en el lab [`L08` §2](l08-security-y-batch.md#2--keycloak-en-compose-el-realm-el-token-y-cómo-se-baja), que además reproduce el 401 frente
al 403 con el mismo usuario.

---

## 8. 🧱 Propagar la identidad al llamar a otro servicio

`inv-api` recibe una petición con token y necesita llamar a `inv-supplier`. Si no manda nada, el
otro devuelve 401, y hay tres respuestas: pasar el mismo token, intercambiarlo en el IdP por uno
dirigido al destino (*token exchange*, un salto de red más) o pedir uno propio de servicio.

- **Pasar el token tal cual** funciona si el `aud` incluye a los dos, y es lo que hace medio
  mundo; el costo es que cualquier servicio de la cadena puede reusarlo contra cualquier otro.
- **`client_credentials` es servicio a servicio sin usuario**: un job nocturno, una
  reconciliación de Batch. El client se autentica con su `client-id` y su `client-secret` y
  recibe un access token **suyo**, sin `sub` de humano; si necesitas saber quién pidió el
  ajuste, no es este flujo.
- **En banca suele ganar el modelo de dos capas**: el token del usuario muere en el borde y
  hacia dentro viaja un token de servicio más el usuario propagado en la traza
  ([`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)). Cuál de
  los tres es decisión de arquitectura.

```java
@Bean
RestClient supplierClient(RestClient.Builder builder, OAuth2AuthorizedClientManager manager) {
    // el interceptor existe desde Security 6.4; antes había que escribirlo a mano
    var interceptor = new OAuth2ClientHttpRequestInterceptor(manager);
    interceptor.setClientRegistrationIdResolver(request -> "inv-supplier");
    return builder.baseUrl("https://inv-supplier.invlab.example").requestInterceptor(interceptor).build();
}
```

- **`OAuth2AuthorizedClientManager`** pide el token, lo guarda y lo renueva cuando caduca; el
  interceptor solo lo pone en `Authorization`. Es el interceptor de
  [`13` §5](13-clientes-http.md#5--interceptores-logging-y-cabeceras-que-viajan).
- **El `registrationId`** apunta a un bloque `spring.security.oauth2.client.registration.inv-supplier`
  con su `authorization-grant-type: client_credentials`, su `client-id` y su `client-secret`, y
  **ese secreto no va en `application.yml`** sino donde diga
  [`07` §8](07-configuracion-externalizada.md#8--importar-configuración-y-guardar-secretos): en
  el repositorio es un token de servicio regalado.

**mTLS** vive un piso más abajo y no sustituye nada de esto: autentica el **canal** —cada
extremo presenta su certificado— y contesta "¿de qué servicio viene la conexión?", no "¿qué
usuario pidió esto?". Se configura con un SSL bundle de Boot y, si quieres el certificado como
`Authentication`, con la autenticación X.509 de Security. En banca se tiene **además** del
token, y muchas veces ni lo maneja la aplicación.

---

## 9. ⚠️ El token no es una sesión: revocar, caducar y qué no meter dentro

La tercera sobregeneralización: *"con JWT ya no hay estado"*. Lo que desaparece es el estado
**del servidor**, no el del sistema: se movió al token, que es una foto del momento de emisión.

```text
sesión  → el servidor decide en cada petición   → revocar = borrar una fila
JWT     → el servidor cree lo que dice el papel → revocar = esperar a que caduque
```

- **Un JWT no se puede revocar de verdad.** Despides a alguien a las 10:00 y su token vale hasta
  su `exp`; con un rol retirado pasa igual.
- **La mitigación estándar son tokens cortos y un refresh token**: access de cinco a quince
  minutos, refresh largo y revocable que vive **solo en el client** y se canjea contra el IdP.
  Ahí sí hay estado y botón de revocar: la ventana de daño pasa de ocho horas a quince minutos.
- **La otra opción es el token opaco con introspección**: el IdP emite una cadena sin contenido
  y `inv-api` la consulta con `...resourceserver.opaquetoken.introspection-uri`, pagando una
  llamada de red por petición —cacheable, pero ahí vuelve el estado— a cambio de revocar ya.
- **Qué no va nunca en el payload:** un número de cuenta, un saldo, nada que no quieras leer en
  un log de acceso. **El JWT lleva identificadores y permisos, no datos de negocio**, y un token
  completo no se escribe jamás en el log ([`23` §11](23-actuator-y-observabilidad.md#11--logging-correlación-json-y-lo-que-no-se-escribe-nunca)).
- **Un JWT gordo se paga en cada petición**, porque los claims viajan en una cabecera: un token
  de 8 KB choca con el límite de Tomcat y el síntoma no es un 401, sino un `400` sin cuerpo.

> **📝 Qué cambia en 4.x.** Boot 4 arrastra Spring Security 7, que retira las clases deprecadas de
> 6.x. Las propiedades `spring.security.oauth2.resourceserver.*` y el converter de §7 sobreviven;
> la migración completa vive en el apéndice `A04`.

---

## 🧠 Preguntas rápidas

1. "OAuth2 sirve para autenticar usuarios": corrige la afirmación y di qué pieza aporta de
   verdad la autenticación.
2. ¿Cuál de los cuatro roles de OAuth2 es `inv-api`, y qué implica que nunca vea la contraseña?
3. Un portal te manda su `id_token` en vez del access token. ¿Por qué debe fallar, y en qué
   claim se nota?
4. "El JWT va cifrado": ¿qué protege realmente la firma y qué no?
5. Enumera en orden lo que valida un resource server con `issuer-uri`, di cuál de los cinco
   pasos **no** está activado por defecto y con qué propiedad de Boot 3.5 se activa.
6. ¿Por qué existe el clock skew de 60 segundos y qué regalas al subirlo a cinco minutos?
7. Con HS256 y seis resource servers, ¿qué puede hacer cualquiera de los seis que no debería?
8. ¿Qué papel juega el claim `kid` en la rotación de claves, y quién recarga el JWK Set?
9. Tu regla dice `hasRole("ANALYST")`, el token de Keycloak trae `realm_access.roles: ["analyst"]`
   y recibes 403. ¿Qué dos cosas faltan, y por qué `authorities-claim-name` no basta?
10. "Con JWT ya no hay estado": ¿qué estado desapareció y cuál no? Explica qué pasa cuando
    despides a alguien a las 10:00.
11. ¿Cuándo prefieres token opaco con introspección sobre JWT, y qué pagas por ello?
12. `inv-api` llama a `inv-supplier` con `client_credentials`. ¿Qué identidad viaja y qué se
    pierde por el camino?
13. ¿Qué pregunta contesta mTLS que un JWT no contesta, y al revés?

---

## 📚 Referencias oficiales

- Spring Security 6.5 — Resource Server con JWT: validadores por defecto, `aud`, clock skew, `JwtAuthenticationConverter`: https://docs.spring.io/spring-security/reference/6.5/servlet/oauth2/resource-server/jwt.html
- Spring Security 6.5 — Bearer Tokens y la respuesta `WWW-Authenticate`: https://docs.spring.io/spring-security/reference/6.5/servlet/oauth2/resource-server/bearer-tokens.html
- Spring Security 6.5 — Token opaco e introspección: https://docs.spring.io/spring-security/reference/6.5/servlet/oauth2/resource-server/opaque-token.html
- Spring Security 6.5 — Authorization grants: authorization code con PKCE y client credentials: https://docs.spring.io/spring-security/reference/6.5/servlet/oauth2/client/authorization-grants.html
- Spring Security 6.5 — Authorized clients y `OAuth2ClientHttpRequestInterceptor` para `RestClient`: https://docs.spring.io/spring-security/reference/6.5/servlet/oauth2/client/authorized-clients.html
- Spring Security 6.5 — Autenticación X.509 (el certificado de cliente como `Authentication`): https://docs.spring.io/spring-security/reference/6.5/servlet/authentication/x509.html
- Spring Security 6.5 — Javadoc de `JwtGrantedAuthoritiesConverter` (prefijo `SCOPE_`, desde 5.2): https://docs.spring.io/spring-security/site/docs/6.5.x/api/org/springframework/security/oauth2/server/resource/authentication/JwtGrantedAuthoritiesConverter.html
- Spring Boot 3.5 — Autoconfiguración de OAuth2 client y resource server: https://docs.spring.io/spring-boot/3.5/reference/web/spring-security.html
- Spring Boot 3.5 — Propiedades `spring.security.oauth2.resourceserver.*`: https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html
- Spring Boot 3.5 — SSL bundles (base de mTLS en la aplicación): https://docs.spring.io/spring-boot/3.5/reference/features/ssl.html

### Especificaciones y documentación de terceros

- RFC 6749 — The OAuth 2.0 Authorization Framework: https://www.rfc-editor.org/rfc/rfc6749.html
- RFC 7519 — JSON Web Token (JWT): claims registrados `iss`, `aud`, `exp`, `nbf`, `sub`: https://www.rfc-editor.org/rfc/rfc7519.html
- OpenID Connect Core 1.0 — `id_token` y la capa de identidad sobre OAuth2: https://openid.net/specs/openid-connect-core-1_0.html
- Keycloak — asegurar aplicaciones con OpenID Connect (el IdP que monta `L08`): https://www.keycloak.org/securing-apps/oidc-layers
