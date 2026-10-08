# 04 — Propagación de identidad entre servicios

> Qué pasa con "quién eres" cuando la petición cruza cinco servicios. Las tres estrategias, la
> confusión de deputado, el token exchange, y el problema que casi nadie plantea: separar la
> identidad del **usuario** de la identidad del **servicio**.
> Asume leído [`03` — OAuth2, OIDC y JWT](03-oauth2-oidc-y-jwt.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

El usuario llama al gateway, que llama a `Pedidos`, que llama a `Pagos`, que llama a `Riesgo`.
`Riesgo` tiene que decidir si esta operación se permite. Y la pregunta es: **¿qué sabe `Riesgo` del
usuario?**

Las tres respuestas posibles definen el capítulo:

```text
1. Nada: confía en que Pedidos ya validó         → confianza implícita. Frágil.
2. Todo: le llega el mismo token del usuario     → simple, y con problemas de alcance.
3. Un token acotado, emitido para él             → correcto, y más maquinaria.
```

Y hay un problema que aparece en las tres y que es el que se pregunta:

> **Regla:** en una cadena de servicios hay **dos identidades**, no una: quién es el usuario y qué
> servicio está llamando. Confundirlas es la raíz de la escalada de privilegios entre servicios.

---

## 2. 🕳️ La confianza implícita y por qué falla

**Qué es.** El modelo por defecto de casi todo sistema que creció sin pensarlo: el gateway valida
el token, y hacia dentro los servicios se llaman sin credenciales porque "están en la red interna".

**Por qué falla**, y son tres razones independientes:

- **La red interna no es una frontera.** Un contenedor comprometido, un SSRF, un servicio expuesto
  por error en un despliegue, y cualquiera puede llamar a `Riesgo` diciendo ser `Pagos`.
- **Se pierde la trazabilidad.** `Riesgo` registra "llamada de Pagos", y cuando auditoría pregunta
  quién autorizó esa operación, no hay respuesta.
- **Se pierde la autorización fina.** `Riesgo` no puede comprobar si **este usuario** podía pedir
  eso, porque no sabe quién es. La única defensa posible es la que `Pedidos` hizo o no hizo.

> ⚠️ **Advertencia.** Este es el modelo que la mayoría de los sistemas tiene de verdad, y decirlo
> en entrevista con naturalidad —*"lo habitual es confianza implícita, y su problema es que la red
> deja de ser una frontera en cuanto algo se compromete"*— sitúa muy bien la respuesta.

> **Veredicto:** "está en la red interna" es el `@Transactional` de la seguridad: parece una
> garantía y no lo es. La frontera de confianza no es la red, es cada servicio.

---

## 3. 🎟️ Estrategia 1: propagar el token del usuario

**Qué es.** El token del usuario viaja tal cual por toda la cadena. Cada servicio lo valida y
decide.

```text
usuario --[JWT del usuario]--> gateway --[el mismo JWT]--> Pedidos --[el mismo]--> Pagos
```

**Lo que compra.** Es la opción más simple y resuelve lo importante: cada servicio sabe quién es el
usuario y puede decidir sobre el objeto concreto. La trazabilidad es completa.

**Lo que cuesta:**

- **El token vale en todas partes.** Si `Pagos` se compromete, tiene un token válido para llamar a
  cualquier servicio en nombre de ese usuario, durante toda su vigencia.
- **El `aud` deja de acotar.** O el token se emite para un público genérico —y entonces no acota
  nada— o hay que emitir uno por servicio, que es ya la estrategia 3.
- **Crece.** Cada servicio que quiere algo en el token lo infla, y el token viaja en cada salto.

**Cuándo sí.** Sistemas internos de confianza media, pocos servicios, y cuando la alternativa
añadiría más complejidad de la que el riesgo justifica. Es una decisión legítima si se declara.

**Cuándo no.** Cuando algún servicio llama a terceros —les estarías entregando el token del
usuario— o cuando el radio de daño de un servicio comprometido es inaceptable.

> **Veredicto:** propagar el token es correcto y honesto en muchos sistemas. Lo que no es
> aceptable es hacerlo sin haber visto que un servicio comprometido hereda toda la identidad del
> usuario.

---

## 4. 🔄 Estrategia 2: token exchange

**Qué es.** El estándar (RFC 8693) para lo que la estrategia 1 hace mal: un servicio cambia el
token que recibió por **otro acotado** al siguiente destino y con menos permisos.

```text
Pedidos recibe token(aud=Pedidos, scope=pedidos:*)
   ↓ token exchange contra el servidor de autorización
Pedidos obtiene token(aud=Pagos, scope=pagos:cobrar, act=Pedidos, sub=usuario)
   ↓
Pagos valida: es para mí (aud), el usuario es X (sub), lo pidió Pedidos (act)
```

- **`act` (actor) es el claim clave**: registra que `Pedidos` está actuando en nombre del usuario.
  Eso da a la vez trazabilidad y la posibilidad de políticas del tipo "este usuario puede, pero no
  a través de ese servicio".
- El token resultante está **acotado en público y en alcance**: si `Pagos` se compromete, lo que
  tiene solo sirve para lo que `Pagos` podía hacer.

**Cuándo sí.** Cadenas largas, servicios con niveles de confianza distintos, dominios regulados, y
siempre que haya una llamada a un tercero.

**Cuándo no.** Sistemas pequeños: añade una llamada al servidor de autorización por salto —que hay
que cachear— y una dependencia crítica más. Si el servidor de autorización cae, la cadena se
detiene.

> 💰 **Costo.** Una ida y vuelta adicional por salto, mitigable con caché por (sujeto, destino,
> alcance). Y el servidor de autorización pasa a estar en el camino crítico de cada petición, no
> solo al iniciar sesión.

> **Veredicto:** token exchange es la respuesta correcta al problema y casi nadie la nombra en una
> entrevista. Mencionar el RFC 8693 y el claim `act` es de las cosas que más distinguen en este
> bloque.

---

## 5. 👥 Estrategia 3: dos identidades a la vez

**Qué es.** La que resuelve el problema de fondo y la que se usa en arquitecturas maduras:
separar explícitamente **quién es el usuario** de **qué servicio llama**.

```text
Identidad del SERVICIO  → mTLS, o un token de Client Credentials.
                          Responde: ¿tengo derecho a hablar con este servicio?
Identidad del USUARIO   → el token propagado o intercambiado.
                          Responde: ¿en nombre de quién actúo?
```

- Las dos se comprueban en el destino, y sirven para cosas distintas: la del servicio autoriza la
  **llamada**; la del usuario autoriza la **operación sobre el objeto**.
- Es la combinación que hace real la defensa en profundidad: aunque alguien obtenga un token de
  usuario, no puede usarlo sin ser un servicio autorizado; y aunque comprometa un servicio, no
  puede actuar sin identidad de usuario válida.
- La identidad del servicio es donde encaja mTLS, que se ve en
  [`05`](05-mtls-zero-trust-y-mesh.md), y que además la da sin que el código tenga que gestionar
  credenciales.

**Cuándo sí.** Cualquier sistema donde el radio de daño importe: banca, salud, cualquier dominio
regulado.

**Cuándo no.** Un sistema interno pequeño donde la identidad de servicio no añada información: si
solo hay tres servicios y todos pueden llamar a todos, la comprobación es ceremonia.

> 🧠 **Modelo mental.** *"¿Quién llama?"* y *"¿en nombre de quién?"* son dos preguntas, y un
> sistema que solo responde una tiene un agujero. La primera la responde mTLS o Client
> Credentials; la segunda, el token del usuario.

> **Veredicto:** las dos identidades es la respuesta completa. Y es lo que permite responder a la
> pregunta de auditoría de banca: *"¿quién ordenó esto, y a través de qué sistema?"*.

---

## 6. 🎪 La confusión de deputado

**Qué es.** El ataque que todo esto previene, y conviene poder narrarlo.

```text
Riesgo confía en Pagos y le permite consultar cualquier expediente.
Un usuario sin permiso llama a Pagos con una petición manipulada.
Pagos, que no comprueba si ESE usuario podía, consulta Riesgo con SU propia credencial.
Riesgo responde, porque confía en Pagos.
→ el usuario obtuvo datos que no podía ver, usando a Pagos como "deputado" confundido.
```

- El fallo no está en `Riesgo`: está en que `Pagos` actúa con **sus** permisos sin comprobar los
  del usuario en cuyo nombre actúa.
- Es exactamente lo que resuelve llevar la identidad del usuario hasta el final: `Riesgo` puede
  comprobar por sí mismo, en vez de confiar.
- Y es la razón por la que **cada servicio debe autorizar, no solo autenticar**. Es la defensa en
  profundidad de [`01`](01-autenticacion-autorizacion-y-amenazas.md) aplicada a la cadena.

> **Veredicto:** poder narrar la confusión de deputado con nombres concretos es lo que convierte
> "propagamos el token" en una decisión razonada en vez de una costumbre.

---

## 7. 🔍 Trazabilidad y auditoría

**Qué es.** El requisito que en banca convierte todo lo anterior en obligatorio.

Lo que hay que poder responder ante una auditoría:

```text
¿Quién ordenó la operación?         → sub del token de usuario, registrado en cada salto
¿A través de qué sistemas pasó?     → act, y el correlation ID de la traza distribuida
¿Cuándo y desde dónde?              → marca de tiempo, IP, dispositivo
¿Con qué autorización?              → qué política permitió la decisión, y con qué datos
```

- **El correlation ID no basta**: dice que los saltos pertenecen a la misma petición, no quién la
  ordenó. Hace falta la identidad en cada registro.
- **Los logs de auditoría no son los logs de aplicación**: van a un almacén aparte, inmutable, con
  su retención regulatoria, y no se borran con la rotación normal.
- **Nunca se registra el token entero.** Se registra `sub`, `act`, `jti` —el identificador del
  token— y el resultado de la decisión. Un token en un log es una credencial en un log.

> ⚠️ **Advertencia.** Registrar el JWT completo "para depurar" es una fuga de credenciales que
> además persiste en el sistema de logs, replicado y con acceso más amplio que la aplicación. Es
> uno de los hallazgos más frecuentes en una auditoría real.

---

## 8. 🧭 Cómo se elige

```text
¿Cuántos servicios y qué radio de daño?
    Pocos, internos, dominio no regulado   → propagar el token del usuario, DECLARANDO el riesgo
    Cadenas largas o confianza desigual    → token exchange (RFC 8693) con claim act
    Dominio regulado o alto radio de daño  → LAS DOS IDENTIDADES: mTLS + token de usuario

¿Alguna llamada sale a un tercero?
    → NUNCA propagues el token del usuario hacia fuera. Token exchange o credencial propia.

¿Qué comprueba cada servicio?
    Autenticación del llamante  → mTLS o Client Credentials
    Identidad del usuario       → token validado con las seis comprobaciones de `03`
    Autorización sobre el objeto→ SIEMPRE, en el servicio. Nunca delegada al que llamó.

Y para auditoría:
    → sub y act en cada registro, log inmutable aparte, y NUNCA el token completo.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Están en la red interna, se confían" | La red no es una frontera: un SSRF o un contenedor comprometido la atraviesa |
| "El gateway ya validó" | El gateway no sabe sobre qué objeto se opera; cada servicio autoriza |
| "Propagamos el token y ya" | Es válido si lo declaras; el riesgo es que un servicio comprometido hereda al usuario |
| "El correlation ID da trazabilidad" | Correlaciona saltos; no dice quién ordenó la operación |
| "Registramos el token para depurar" | Es una credencial en los logs, replicada y con acceso amplio |
| "Una identidad basta" | Son dos: qué servicio llama y en nombre de quién |
| "Mandamos el token del usuario al proveedor externo" | Le entregas una credencial que vale en todo tu sistema |

---

## 📚 Para profundizar

- **Libro** — Prabath Siriwardena y Nuwan Dias, *Microservices Security in Action* (Manning,
  2020). Capítulos 6 a 8 y 11: propagación de identidad, token exchange y el modelo de dos
  identidades. **Es el libro de este capítulo y no hay alternativa igual de específica.**
- **Libro** — Sam Newman, *Building Microservices*, 2ª ed. (O'Reilly, 2021). Capítulo 11:
  confianza entre servicios y el problema de la confusión de deputado.
- **Libro** — Ross Anderson, *Security Engineering*, 3ª ed. (Wiley, 2020). El capítulo sobre
  control de acceso trata la confusión de deputado en su forma general.
- [RFC 8693 — OAuth 2.0 Token Exchange](https://datatracker.ietf.org/doc/html/rfc8693): el
  estándar, con el claim `act` y la delegación frente a la suplantación.
- [RFC 9068 — JWT Profile for OAuth 2.0 Access Tokens](https://datatracker.ietf.org/doc/html/rfc9068):
  qué claims debe llevar un access token en formato JWT y cómo se valida.
- [RFC 8705 — mTLS Client Authentication and Certificate-Bound Access Tokens](https://datatracker.ietf.org/doc/html/rfc8705):
  cómo atar un token a un certificado para que robarlo no baste.
- [OWASP — Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html):
  por qué la comprobación va en cada capa y no solo en el borde.
- **Video** — GOTO Conferences y Devoxx, charlas sobre seguridad en arquitecturas de
  microservicios y sobre token exchange. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Cuáles son las tres estrategias de propagación de identidad? 🟢
2. ¿Qué es la confusión de deputado? 🟢
3. ¿Qué es el token exchange? 🟢
4. ¿Qué dos identidades hay en una llamada entre servicios? 🟢
5. ¿Qué claim registra que un servicio actúa en nombre del usuario? 🟢
6. ¿Por qué "están en la red interna" no es una garantía? 🟡
7. ¿Qué se pierde con la confianza implícita entre servicios? 🟡
8. ¿Qué cuesta propagar el token del usuario tal cual? 🟡
9. ¿Por qué no se registra el token completo en los logs? 🟡
10. ¿Qué diferencia hay entre el correlation ID y la identidad en el registro? 🟡
11. ¿Qué acota un token obtenido por token exchange? 🟡
12. ¿Qué responde la identidad de servicio y qué responde la de usuario? 🟡
13. ¿Por qué el token exchange pone al servidor de autorización en el camino
    crítico? 🟠
14. ¿Por qué nunca se propaga el token del usuario a un tercero? 🟠
15. Narra la confusión de deputado con tres servicios concretos. 🟠
16. ¿Cuándo es aceptable propagar el token tal cual? 🟠
17. ¿Por qué el `aud` deja de acotar si propagas el mismo token? 🟠
18. ¿Qué debe poder responder el sistema ante una auditoría? 🟠
19. ¿Por qué los logs de auditoría van a un almacén aparte? 🟠
20. ¿Cómo se mitiga el coste del token exchange? 🟠
21. Diseña la propagación de identidad de una cadena gateway → pedidos → pagos →
    proveedor externo de tarjetas. Justifica cada salto. 🔴
22. Un servicio interno consultó expedientes de clientes que el usuario no podía
    ver, sin que nadie lo detectara. Reconstruye el fallo y las medidas. 🔴
23. Te piden pasar de confianza implícita a identidad verificada en 12 servicios
    sin parar el negocio. ¿Cómo lo haces y en qué orden? 🔴

---

**Anterior:** [`03` — OAuth2, OIDC y JWT](03-oauth2-oidc-y-jwt.md) ·
**Siguiente:** [`05` — mTLS, zero-trust y service mesh](05-mtls-zero-trust-y-mesh.md) ·
**Relacionado:** [`01-bases/08` — Comunicación e integración](../01-bases/08-comunicacion-e-integracion.md)
