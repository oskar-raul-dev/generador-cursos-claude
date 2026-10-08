# 03 — OAuth2, OIDC y JWT

> Las tres cosas que todo el mundo mezcla y que son distintas: un marco de **delegación de
> autorización**, una capa de **identidad** encima, y un **formato de token**. Con los flujos que
> siguen vigentes, los que ya no, y el problema de la revocación.
> Asume leído [`02` — Spring Security por dentro](02-spring-security-por-dentro.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

*"¿Usáis OAuth2?"* — *"Sí, con JWT."* Esa respuesta mezcla tres capas y no dice nada:

```text
OAuth2 → marco de DELEGACIÓN DE AUTORIZACIÓN. Cómo una app obtiene permiso
         para actuar en nombre de un usuario. NO dice quién es el usuario.
OIDC   → capa de IDENTIDAD sobre OAuth2. Añade el ID token, que sí dice quién eres.
JWT    → FORMATO de token. Un JSON firmado. Ni autentica ni autoriza: transporta.
```

Se pueden combinar de todas las formas: OAuth2 con tokens opacos y sin JWT, JWT sin OAuth2 en
absoluto, OIDC que usa JWT para el ID token y tokens opacos para el acceso.

> **Regla:** OAuth2 responde *"¿puede esta aplicación hacer esto en tu nombre?"*; OIDC responde
> *"¿quién eres?"*; JWT solo dice *"esto viene firmado por alguien"*. Separarlas en voz alta es
> media respuesta.

---

## 2. 🎭 OAuth2: los actores y qué resuelve

**Qué es.** Un marco para que una aplicación acceda a un recurso **en nombre de un usuario** sin
conocer su contraseña. Nació para "esta app quiere ver tus fotos" y se ha convertido en el estándar
de facto para todo.

Los cuatro actores, que hay que poder nombrar:

```text
Resource Owner        → el usuario. El dueño de los datos.
Client                → la aplicación que quiere acceder.
Authorization Server  → quien emite los tokens. El proveedor de identidad.
Resource Server       → la API que guarda los datos y valida el token.
```

**Los dos tokens y su asimetría**, que es donde está el diseño:

- **Access token**: corto —minutos—, se envía en cada petición, y si se filtra el daño está
  acotado por su caducidad.
- **Refresh token**: largo —días o meses—, se guarda y solo se usa contra el servidor de
  autorización para obtener accesos nuevos. Si se filtra, el daño es mucho mayor, y por eso se
  rota: cada uso emite uno nuevo e invalida el anterior.

**Los scopes.** Delimitan qué puede hacer el cliente: `pagos:leer`, `pagos:escribir`. Son permisos
**de la aplicación**, no del usuario.

> ⚠️ **Advertencia.** Confundir scope con permiso de usuario es un error de diseño frecuente. El
> scope dice *"esta app puede intentar leer pagos"*; que **este usuario** pueda ver **ese** pago
> concreto es autorización de dominio, y vive en tu servicio. Un token con
> `scope: pagos:leer` no autoriza a leer los pagos de otro.

> **Veredicto:** OAuth2 es delegación, no autenticación. Usarlo como si el access token dijera
> quién eres es el error que OIDC vino a corregir.

---

## 3. 🪪 OIDC: la capa de identidad

**Qué es.** OpenID Connect añade sobre OAuth2 lo que le faltaba: un **ID token**, siempre un JWT,
que afirma quién es el usuario y para qué cliente se emitió.

```text
Access token → para la API. Dice qué puede hacer el portador. Puede ser opaco.
ID token     → para el CLIENTE. Dice quién es el usuario. Siempre JWT. NUNCA se manda a la API.
```

- Los *claims* estándar: `sub` (identificador estable del usuario), `iss` (quién lo emitió), `aud`
  (para quién), `exp`, `iat`, `nonce`.
- **`sub` es el identificador, no el email**: el email cambia y se reutiliza; `sub` no.
- El `userinfo` endpoint permite pedir más datos del usuario sin inflar el token.
- **El descubrimiento** (`/.well-known/openid-configuration`) publica endpoints y claves, y es lo
  que permite que la rotación de claves del emisor sea transparente para tu servicio.

> ⚠️ **Advertencia.** Mandar el ID token a la API en vez del access token es un error frecuente y
> real: el ID token está dirigido al cliente (`aud` = el cliente), no a la API. Un servicio que lo
> acepta está validando un token que no era para él.

> **Veredicto:** si lo que necesitas es saber quién es el usuario, necesitas OIDC. OAuth2 solo no
> lo da, y montar autenticación sobre él a mano es cómo se producen los agujeros clásicos.

---

## 4. 🔁 Los flujos: cuáles y por qué

**Vigentes:**

**Authorization Code + PKCE.** El único flujo recomendado hoy para aplicaciones con usuario, sean
web, SPA o móvil.

```text
1. El cliente genera un secreto aleatorio (verifier) y envía su hash (challenge)
2. El usuario se autentica en el servidor de autorización
3. El servidor devuelve un CÓDIGO al cliente (no un token)
4. El cliente canjea el código + el verifier original por los tokens
```

- **PKCE existe para que un código interceptado no sirva de nada**: quien lo robe no tiene el
  verifier. Nació para móviles y hoy se exige también en web, con o sin secreto de cliente.
- El código viaja por el navegador; los tokens no. Esa es toda la gracia.

**Client Credentials.** Para máquina a máquina, sin usuario: un trabajo por lotes que llama a una
API. El cliente se autentica con su propia credencial.

**Device Code.** Para dispositivos sin teclado o navegador: televisores, terminales.

**Obsoletos, y hay que saber decir por qué:**

```text
Implicit          → devolvía el token en la URL: queda en el historial, en los logs del
                    proxy y en el Referer. Sustituido por Code + PKCE.
Password (ROPC)   → la app pide la contraseña del usuario: rompe el propósito de OAuth2
                    y es incompatible con doble factor. Retirado de la especificación.
```

> 💡 **Truco.** Que te pregunten por los flujos obsoletos es habitual, y la buena respuesta no es
> "no se usan": es **por qué**. "Implicit dejaba el token en la URL" y "ROPC obliga a la app a
> manejar la contraseña, lo que impide 2FA y federación" son las dos frases que cierran.

**Cuándo sí cada uno.** Code + PKCE siempre que haya un usuario. Client Credentials entre
servicios sin usuario. Device Code solo si el dispositivo lo exige.

**Cuándo no.** Implicit y ROPC, nunca. Y si un sistema heredado los usa, migrarlos es prioridad.

> **Veredicto:** hoy la respuesta correcta a "¿qué flujo?" es Authorization Code con PKCE, y todo
> lo demás necesita justificación. El estándar actual (RFC 9700) lo declara explícitamente.

---

## 5. 📜 JWT: qué es y qué se valida

**Qué es.** Tres partes en Base64 separadas por puntos: cabecera, cuerpo y firma.

```text
eyJhbGciOiJSUzI1NiIsImtpZCI6ImFiYyJ9 . eyJzdWIiOiIxMjMiLCJleHAiOjE3...} . <firma>
   ↑ header: alg, kid              ↑ payload: claims          ↑ signature
```

- **Está firmado, no cifrado.** Cualquiera puede leer el contenido. Meter datos personales o
  secretos en un JWT es publicarlos.
- `kid` identifica la clave con la que se firmó, y es lo que permite rotar claves sin romper los
  tokens en vuelo.

**Lo que hay que validar, y omitir cualquiera es un agujero:**

```text
1. La FIRMA, con la clave pública del emisor (obtenida del JWKS, cacheada, con rotación)
2. exp → no caducado                  3. nbf → ya válido
4. iss → lo emitió quien esperas      5. aud → estaba dirigido a TI
6. alg → el algoritmo esperado, comparado contra una lista blanca
```

- **El punto 6 es un ataque clásico**: `alg: none` o cambiar RS256 por HS256 usando la clave
  pública como secreto. Las librerías modernas lo bloquean, pero hay que saber por qué existe la
  comprobación.
- **El punto 5 es el que más se olvida.** Un servicio que no valida `aud` acepta tokens emitidos
  para otra API del mismo emisor. Es el vector de escalada entre servicios de
  [`04`](04-propagacion-de-identidad.md).

**Simétrico contra asimétrico.** HMAC (HS256) exige compartir el secreto con cada validador, así
que cualquiera de ellos podría **emitir** tokens. RSA o EC (RS256, ES256) permiten validar con la
clave pública sin poder firmar. En un sistema distribuido, asimétrico siempre.

> **Veredicto:** un JWT bien validado es seis comprobaciones, no una. Y la que separa en entrevista
> es `aud`: si no la validas, tu servicio acepta credenciales que no eran suyas.

---

## 6. 🚫 La revocación: el problema de fondo

**Qué es.** El precio de la validación sin estado. Un JWT es válido hasta que caduca, y el emisor
no tiene forma de retirarlo porque **nadie le pregunta**.

```text
Token opaco     → el recurso pregunta al emisor (introspección). Revocar es inmediato.
                  Precio: una llamada por petición, o una caché con su ventana.
JWT autocontenido→ el recurso valida solo. Rápido y sin dependencia.
                  Precio: revocar es imposible hasta la caducidad.
```

Las salidas, con su compromiso:

- **Caducidad corta** (5–15 minutos) más refresh token rotativo. Es la estándar: acota la ventana y
  la revocación real ocurre al negar el refresh.
- **Lista de revocación** consultada por el recurso. Funciona y reintroduce estado y una
  dependencia.
- **Introspección** con caché corta. El punto medio: latencia acotada y revocación en segundos.
- **Marca de versión de sesión** en el token, comparada contra un valor por usuario. Barata, y
  exige una consulta.

> ⚠️ **Advertencia.** *"Tenemos JWT y podemos revocar al instante"* es contradictorio salvo que
> haya introspección o lista de revocación, y entonces ya no es validación sin estado. Reconocer
> el compromiso es lo que se evalúa.

**Y el caso que se pregunta en banca:** cuando un empleado es despedido, la sesión no puede seguir
viva quince minutos. Ahí la respuesta es caducidad muy corta, o introspección, o ambas — y decir
que se acepta el coste.

> **Veredicto:** la elección entre token opaco y JWT es la elección entre revocación inmediata y
> validación sin dependencia. No hay una tercera opción, y quien dice tener las dos no ha
> identificado el precio.

---

## 7. 🧭 Cómo se elige

```text
¿Necesitas saber QUIÉN es el usuario?
    → OIDC, no OAuth2 a secas. El ID token es para el cliente; el access token, para la API.

¿Qué flujo?
    Hay un usuario (web, SPA, móvil)   → Authorization Code + PKCE. Siempre.
    Máquina a máquina, sin usuario     → Client Credentials
    Dispositivo sin navegador          → Device Code
    Implicit o ROPC                    → NO. Y sabe decir por qué.

¿Formato del access token?
    ¿La revocación inmediata es un requisito? (banca, empleados)
        Sí → opaco con introspección, o JWT muy corto + introspección
        No → JWT autocontenido, caducidad de minutos, refresh rotativo

Y al validar un JWT, SIEMPRE las seis:
    firma (JWKS con rotación) · exp · nbf · iss · aud · alg contra lista blanca
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "OAuth2 autentica usuarios" | OAuth2 delega autorización; quien autentica es OIDC |
| "Usamos OAuth2 con JWT" | Son tres capas distintas: marco, identidad y formato |
| "El JWT está cifrado" | Está **firmado**: cualquiera lee el contenido |
| "Mando el ID token a la API" | El ID token es para el cliente; la API espera el access token |
| "Validamos la firma y listo" | Faltan `exp`, `nbf`, `iss`, `aud` y el algoritmo |
| "Con JWT revocamos al instante" | No, salvo que añadas introspección o lista, y entonces ya hay estado |
| "El scope autoriza al usuario" | El scope es permiso de la **aplicación**; el del objeto es de tu dominio |
| "Usamos el flujo password, es más simple" | Retirado: impide 2FA y obliga a la app a manejar la contraseña |

---

## 📚 Para profundizar

- **Libro** — Prabath Siriwardena y Nuwan Dias, *Microservices Security in Action* (Manning,
  2020). Capítulos 2, 6 y 7: OAuth2, OIDC y JWT aplicados a microservicios, con los ataques reales.
- **Libro** — Laurentiu Spilca, *Spring Security in Action*, 2ª ed. (Manning, 2024). Capítulos
  sobre OAuth2: cliente y servidor de recursos con la configuración moderna.
- [RFC 6749 — The OAuth 2.0 Authorization Framework](https://datatracker.ietf.org/doc/html/rfc6749):
  la especificación base, con los actores y los flujos originales.
- [RFC 9700 — Best Current Practice for OAuth 2.0 Security](https://datatracker.ietf.org/doc/html/rfc9700):
  **la referencia actual**. Declara obsoletos Implicit y ROPC y exige PKCE.
- [RFC 7636 — PKCE](https://datatracker.ietf.org/doc/html/rfc7636): qué problema resuelve y cómo.
- [RFC 7519 — JSON Web Token](https://datatracker.ietf.org/doc/html/rfc7519): los claims
  registrados y las reglas de validación.
- [OpenID Connect — How it works](https://openid.net/developers/how-connect-works/): la capa de
  identidad y la diferencia entre ID token y access token.
- [Spring Security — OAuth2 Resource Server JWT](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html):
  cómo se valida en Spring, incluidos `aud` e `iss`.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Qué es OAuth2, qué es OIDC y qué es JWT? 🟢
2. Nombra los cuatro actores de OAuth2. 🟢
3. ¿Qué diferencia hay entre access token y refresh token? 🟢
4. ¿Qué partes tiene un JWT? 🟢
5. ¿Qué flujo es el recomendado hoy para aplicaciones con usuario? 🟢
6. ¿Qué es PKCE y qué problema resuelve? 🟡
7. ¿Qué diferencia hay entre ID token y access token? 🟡
8. ¿Por qué un JWT no debe llevar datos sensibles? 🟡
9. ¿Para qué sirve el claim `kid`? 🟡
10. ¿Por qué `sub` y no el email como identificador? 🟡
11. ¿Cuándo se usa Client Credentials? 🟡
12. ¿Qué es la introspección de token? 🟡
13. ¿Qué seis cosas se validan en un JWT? 🟡
14. ¿Por qué validar `aud` es crítico? 🟠
15. ¿Por qué Implicit está obsoleto? 🟠
16. ¿Por qué el flujo password se retiró de la especificación? 🟠
17. ¿Por qué en un sistema distribuido se firma con clave asimétrica? 🟠
18. ¿Qué es el ataque de confusión de algoritmo? 🟠
19. ¿Por qué "con JWT revocamos al instante" es contradictorio? 🟠
20. ¿Qué diferencia hay entre un scope y un permiso sobre un objeto? 🟠
21. Diseña la revocación de sesiones para una banca donde despedir a un empleado
    debe cortarle el acceso en segundos. 🔴
22. Un servicio acepta tokens emitidos para otra API del mismo proveedor.
    Diagnostica y explica el impacto. 🔴
23. Te piden migrar de flujo Implicit a Authorization Code + PKCE en una SPA con
    40.000 usuarios activos. ¿Cómo lo haces sin cortar el servicio? 🔴

---

**Anterior:** [`02` — Spring Security por dentro](02-spring-security-por-dentro.md) ·
**Siguiente:** [`04` — Propagación de identidad](04-propagacion-de-identidad.md) ·
**Relacionado:** [`01` — Autenticación, autorización y amenazas](01-autenticacion-autorizacion-y-amenazas.md)
