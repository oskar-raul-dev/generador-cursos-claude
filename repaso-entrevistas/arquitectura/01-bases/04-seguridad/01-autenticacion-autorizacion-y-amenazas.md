# 01 — Autenticación, autorización y amenazas

> El vocabulario que hay que tener antes de tocar un token: quién eres contra qué puedes hacer,
> los modelos de autorización y cuál elegir, dónde se decide y dónde se aplica, y las amenazas
> que un arquitecto debe poder nombrar sin mirar la lista.
> Asume leído [`01-bases/08` — Comunicación e integración](../01-bases/08-comunicacion-e-integracion.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Te preguntan cómo aseguras un sistema de microservicios y respondes "con JWT". La pregunta de
seguimiento llega sola: *"¿y quién decide si este usuario puede aprobar esta transferencia?"*.

Ahí se ve la diferencia. El token dice **quién eres**; no dice **qué puedes hacer**, ni dónde se
decide, ni qué pasa cuando la respuesta cambia a mitad de sesión.

```text
Autenticación (authn) → ¿quién eres?          Ocurre una vez, al entrar.
Autorización  (authz) → ¿qué puedes hacer?    Ocurre en CADA operación.
```

Confundirlas produce el error más caro y más común: meter todos los permisos en el token y
descubrir que revocarlos exige esperar a que caduque.

> **Regla:** la autenticación es un evento; la autorización es una decisión continua. Todo lo que
> este bloque discute sale de esa asimetría.

---

## 2. 🆔 Autenticación

**Qué es.** Verificar la identidad. El sistema confirma que quien llega es quien dice ser, y a
partir de ahí emite una credencial de sesión.

Los factores, con la clasificación que se pregunta:

```text
Algo que SABES    → contraseña, PIN
Algo que TIENES   → móvil, llave física, tarjeta
Algo que ERES     → huella, cara
```

- **Doble factor** es combinar dos **categorías distintas**. Contraseña más pregunta de seguridad
  no es doble factor: son dos cosas que sabes.
- El SMS como segundo factor está desaconsejado —se intercepta con SIM swapping— frente a TOTP o
  llaves con WebAuthn/FIDO2, que además resisten el phishing porque están ligadas al dominio.

**Dónde ocurre.** En un proveedor de identidad —Keycloak, Cognito, Entra ID, Auth0—, **nunca en
cada servicio**. La autenticación es un subdominio genérico de
[`01-bases/06`](../01-bases/06-ddd-estrategico.md): se compra, no se construye.

**Cuándo sí construirla.** Prácticamente nunca. Ni la gestión de contraseñas, ni el flujo de
recuperación, ni la rotación de tokens, ni el cumplimiento normativo asociado son terreno donde
improvisar.

**Cuándo no.** Siempre "no". La excepción defendible: un sistema interno sin datos sensibles donde
el proveedor añada más operación de la que ahorra.

> ⚠️ **Advertencia.** *"Escribimos nuestro propio servicio de autenticación"* es, en una entrevista
> de banca, una respuesta que resta. Es presupuesto del núcleo gastado en un subdominio genérico
> que el mercado resuelve mejor, y superficie de ataque añadida.

> **Veredicto:** la autenticación se delega. Lo que sí es trabajo tuyo es cómo se propaga esa
> identidad por dentro, que es [`04`](04-propagacion-de-identidad.md) y es donde se gana la
> entrevista.

---

## 3. 🔐 Autorización: los modelos

**Qué es.** Decidir si una identidad puede ejecutar una operación sobre un recurso. Hay tres
modelos y elegir mal es caro.

**RBAC — por roles.** El usuario tiene roles, los roles tienen permisos.

```text
usuario → rol ANALISTA → permisos {leer_cliente, leer_riesgo}
```

- Simple, auditable, y lo que todo el mundo entiende. Es el valor por defecto.
- **Su modo de fallo es la explosión de roles**: en cuanto aparece "analista pero solo de su
  sucursal", nace `ANALISTA_SUCURSAL_MADRID`, y a los dos años hay cuatrocientos roles que nadie
  puede auditar.

**ABAC — por atributos.** La decisión se calcula con atributos del sujeto, del recurso, de la acción
y del contexto.

```text
permite si sujeto.sucursal == recurso.sucursal
       y  accion == "leer"
       y  hora entre 08:00 y 20:00
```

- Expresivo y granular; resuelve la explosión de roles sin crear roles.
- Precio: las decisiones son difíciles de auditar —"¿quién puede ver esto?" deja de tener respuesta
  sencilla— y de depurar.

**ReBAC — por relaciones.** El permiso deriva de la relación con el recurso: eres el **dueño** del
documento, el **gestor** de esa cuenta, **miembro** de ese equipo.

- Es lo que de verdad piden muchos dominios, y lo que RBAC intenta simular con roles artificiales.
- Su implementación canónica es un grafo de relaciones consultable, estilo Zanzibar.

**Cuándo sí cada uno.** RBAC como base, siempre. ABAC cuando aparezcan condiciones contextuales
—sucursal, importe, horario—. ReBAC cuando el permiso dependa de una relación concreta con el
recurso.

**Cuándo no.** ABAC puro desde el día uno: es sobre-ingeniería y hace imposible la pregunta de
auditoría más frecuente. Lo habitual y sano es **RBAC más atributos** para los pocos casos que lo
exigen.

> **Veredicto:** la pregunta que decide el modelo es *"¿el permiso depende solo de quién eres, o
> también de qué recurso concreto es?"*. Si es lo segundo, RBAC solo no va a llegar y conviene
> saberlo antes de tener cuatrocientos roles.

---

## 4. 🚪 Dónde se decide y dónde se aplica

**Qué es.** La distinción estructural del capítulo, y la que separa una respuesta de arquitecto de
una de desarrollador. Viene del vocabulario de XACML y se usa aunque no uses XACML:

```text
PEP  Policy Enforcement Point  → dónde se APLICA. Intercepta y deja pasar o no.
PDP  Policy Decision Point     → dónde se DECIDE. Evalúa la política y responde sí/no.
PIP  Policy Information Point  → de dónde salen los datos que la decisión necesita.
PAP  Policy Administration     → dónde se escriben y gestionan las políticas.
```

**Las tres arquitecturas posibles**, con su compromiso:

| | Dónde decide | Ventaja | Precio |
|---|---|---|---|
| **En el gateway** | Un punto central | Consistente, fácil de auditar | No conoce el recurso: solo puede decidir por ruta y rol |
| **En cada servicio** | Distribuido | Conoce el recurso y el dominio | La política se dispersa y diverge |
| **PDP externo** | Servicio dedicado (OPA, Cedar) | Política centralizada, decisión con contexto | Un salto más, y un punto crítico |

**La regla que resuelve la mayoría de los casos:**

> El gateway hace el filtro grueso —autenticado, token válido, rol compatible con la ruta— y **cada
> servicio decide lo fino**, porque es el único que sabe si este usuario es el gestor de esta
> cuenta.

- **Nunca solo el gateway.** Si un servicio confía en que "alguien delante ya validó", basta una
  ruta interna mal expuesta para saltarse todo. Es defensa en profundidad.
- El PDP externo con políticas declarativas es la opción madura cuando hay muchos servicios y la
  política tiene que ser auditable en un sitio.

> 🧠 **Modelo mental.** El gateway sabe **quién llama y adónde**; solo el servicio sabe **sobre qué
> recurso**. Por eso la autorización a nivel de objeto no puede vivir en el borde.

> **Veredicto:** decidir solo en el gateway es la respuesta que más veces se da y la que más veces
> está incompleta. Decir *"grueso en el borde, fino en el servicio"* cierra la pregunta.

---

## 5. 🧨 Las amenazas que hay que nombrar

**Qué es.** No hace falta recitar el OWASP Top 10 entero, pero sí poder nombrar las que afectan a
decisiones de arquitectura. Las cinco que más caen:

**Broken Access Control.** El número uno del OWASP Top 10, y el más aburrido: el sistema no
comprueba si este usuario puede ver **este** objeto. Su forma canónica es el **IDOR**: cambiar
`/pedidos/771` por `/pedidos/772` y ver el pedido de otro.

- Es el mismo fallo que la fuga multi-tenant de [`03-datos/08`](../03-datos/08-poliglota-y-multi-tenant.md),
  y se defiende igual: la comprobación no puede depender de que el desarrollador se acuerde.

**Inyección.** SQL, LDAP, comandos. Sigue viva. La defensa es estructural —consultas
parametrizadas, nunca concatenación— y la superficie moderna incluye plantillas y deserialización.

**Fallos criptográficos.** Datos sensibles sin cifrar en reposo o en tránsito, algoritmos obsoletos,
claves en el repositorio. Se ve en [`06`](06-secretos-y-criptografia.md).

**SSRF.** El servidor hace una petición a una URL que controla el atacante y alcanza recursos
internos: el endpoint de metadatos de la nube, un servicio no expuesto. Es especialmente grave en
arquitecturas donde los servicios internos confían entre sí.

**Confusión de deputado y escalada entre servicios.** El servicio A, que tiene muchos permisos,
ejecuta en nombre del usuario B algo que B no podía hacer. Es el problema que
[`04`](04-propagacion-de-identidad.md) existe para resolver.

> 💡 **Truco.** En una entrevista de arquitectura no te van a pedir que expliques XSS. Te van a
> preguntar **dónde pones la comprobación** para que un fallo de acceso sea imposible, no
> improbable. Esa es la conversación de arquitectura.

---

## 6. 🛡️ Principios que se citan y se aplican

```text
Mínimo privilegio      → cada identidad, humana o de servicio, solo lo que necesita.
                         Y con caducidad: un permiso temporal que no caduca no era temporal.
Defensa en profundidad → varias capas independientes. Ninguna es la última línea.
Fallo cerrado          → ante un error al evaluar la política, DENIEGA. Nunca permite.
Separación de deberes  → quien aprueba no es quien ejecuta. En banca es normativo.
Diseño seguro          → la operación insegura no debe ser posible, no solo estar desaconsejada.
```

- **Fallo cerrado** es el que más se incumple: un `catch` que devuelve `true` "para no romper el
  flujo" convierte un error transitorio del PDP en un agujero.
- **Separación de deberes** en banca no es una buena práctica: es una exigencia regulatoria, y
  condiciona el modelo de datos —quién aprueba queda registrado— y el de autorización.

> **Veredicto:** citar principios sin aplicarlos no puntúa. Lo que puntúa es decir dónde los
> materializas: *"fallo cerrado significa que si el PDP no responde, el servicio devuelve 403, no
> 200"*.

---

## 7. 🧭 Cómo se elige

```text
¿Quién autentica?
    → Un proveedor de identidad. Siempre. No lo construyes.

¿Qué modelo de autorización?
    ¿El permiso depende solo de quién eres?              → RBAC. Empieza aquí.
    ¿Depende del contexto (sucursal, importe, horario)?  → RBAC + atributos
    ¿Depende de tu relación con ESE recurso concreto?    → ReBAC, o RBAC + comprobación de dominio
    ¿Ya tienes 200 roles?                                → la explosión ya ocurrió: atributos

¿Dónde se decide?
    Filtro grueso (autenticado, rol, ruta)   → gateway
    Decisión fina (¿este usuario, este objeto?) → EN EL SERVICIO, siempre
    ¿Muchos servicios y política auditable?   → PDP externo con políticas declarativas

Y en cualquier caso:
    → fallo cerrado, defensa en profundidad, y la comprobación de objeto no puede
      depender de que alguien se acuerde de escribirla.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con JWT ya está asegurado" | El token autentica; la autorización sobre el objeto es otra cosa |
| "Validamos en el gateway" | El gateway no conoce el recurso: la decisión fina va en el servicio |
| "Contraseña + pregunta secreta es 2FA" | Son dos cosas que sabes: es un solo factor |
| "Metemos todos los permisos en el token" | Revocar exige esperar a la caducidad; ver [`03`](03-oauth2-oidc-y-jwt.md) |
| "Construimos nuestro SSO" | Subdominio genérico: se compra, y construirlo añade superficie de ataque |
| "Si falla el PDP, dejamos pasar" | Fallo cerrado: ante el error, se deniega |
| "RBAC sirve para todo" | Hasta que aparece "solo los de su sucursal" y explotan los roles |

---

## 📚 Para profundizar

- **Libro** — Prabath Siriwardena y Nuwan Dias, *Microservices Security in Action* (Manning,
  2020). Capítulos 1 a 3: el modelo de amenazas de una arquitectura de microservicios y dónde va
  cada control. **Es el libro de este bloque.**
- **Libro** — Laurentiu Spilca, *Spring Security in Action*, 2ª ed. (Manning, 2024). Capítulos 1 y
  7: autenticación y autorización en Spring, con la distinción entre ambas bien trabajada.
- **Libro** — Ross Anderson, *Security Engineering*, 3ª ed. (Wiley, 2020). Capítulos sobre control
  de acceso: el tratado de referencia, disponible gratis en la web del autor.
- [OWASP Top 10](https://owasp.org/projects/top-ten): el catálogo, con Broken Access Control
  en el primer puesto y su explicación.
- [OWASP — Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html):
  dónde poner las comprobaciones y por qué la de objeto no puede ir en el borde.
- [Spring Security — Authorization Architecture](https://docs.spring.io/spring-security/reference/servlet/authorization/architecture.html):
  cómo se materializan PEP y PDP en Spring.
- [NIST SP 800-207 — Zero Trust Architecture](https://csrc.nist.gov/pubs/sp/800/207/final): el
  vocabulario de PEP y PDP en su forma canónica; se amplía en [`05`](05-mtls-zero-trust-y-mesh.md).
- **Video** — GOTO Conferences y Spring I/O, charlas sobre seguridad en microservicios y sobre
  modelos de autorización. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Qué diferencia hay entre autenticación y autorización? 🟢
2. ¿Qué son RBAC, ABAC y ReBAC? 🟢
3. ¿Qué son PEP y PDP? 🟢
4. ¿Cuáles son los tres factores de autenticación? 🟢
5. ¿Cuál es el primer puesto del OWASP Top 10? 🟢
6. ¿Qué es un IDOR? 🟡
7. ¿Por qué contraseña más pregunta secreta no es doble factor? 🟡
8. ¿Qué es la explosión de roles y cuándo aparece? 🟡
9. ¿Qué significa "fallo cerrado"? 🟡
10. ¿Qué es SSRF y por qué es grave en microservicios? 🟡
11. ¿Por qué la autenticación se delega a un proveedor de identidad? 🟡
12. ¿Qué es la separación de deberes y por qué importa en banca? 🟡
13. ¿Por qué el gateway no puede decidir la autorización fina? 🟠
14. ¿Qué pregunta decide entre RBAC y ABAC? 🟠
15. ¿Por qué ABAC puro desde el día uno es sobre-ingeniería? 🟠
16. ¿Qué problema tiene un `catch` que devuelve `true` al fallar el PDP? 🟠
17. ¿Cuándo usarías un PDP externo y qué cuesta? 🟠
18. ¿Por qué un permiso temporal sin caducidad no era temporal? 🟠
19. ¿Qué es la confusión de deputado entre servicios? 🟠
20. ¿Por qué la comprobación de acceso a objeto no puede depender de la
    disciplina del desarrollador? 🟠
21. Diseña el modelo de autorización de una banca en línea: consultar cuentas
    propias, operar, y que un gestor vea las de sus clientes. 🔴
22. Un usuario cambió `/pedidos/771` por `/pedidos/772` y vio el de otro.
    Describe la investigación y las medidas, inmediatas y de fondo. 🔴
23. Te piden "asegurar" un sistema de 12 microservicios que hoy confían entre
    sí. ¿Por dónde empiezas y en qué orden? 🔴

---

**Siguiente:** [`02` — Spring Security por dentro](02-spring-security-por-dentro.md) ·
**Relacionado:** [`04` — Propagación de identidad](04-propagacion-de-identidad.md)
