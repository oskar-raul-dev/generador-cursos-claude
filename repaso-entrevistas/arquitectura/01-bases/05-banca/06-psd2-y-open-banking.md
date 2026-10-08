# 06 — PSD2 y Open Banking

> La normativa que obligó a los bancos a abrir APIs, qué roles crea, cómo se autentica y se firma, y
> qué exige de tu arquitectura: disponibilidad medida, consentimiento como entidad de dominio, y
> límites de consulta impuestos por ley.
> Asume leído [`04-seguridad/03` — OAuth2, OIDC y JWT](../04-seguridad/03-oauth2-oidc-y-jwt.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Antes de PSD2, si una aplicación de finanzas personales quería leer tus movimientos, te pedía tus
credenciales del banco y se hacía pasar por ti. Eso —*screen scraping*— era frágil, inseguro, y el
banco no podía distinguir al cliente de la app.

La normativa europea lo prohibió y obligó a los bancos a ofrecer una alternativa:

```text
El banco DEBE exponer APIs para que terceros autorizados accedan a las cuentas
del cliente, CON su consentimiento explícito, y con una disponibilidad y un
rendimiento comparables a los de sus propios canales.
```

Esa última frase es la que convierte una obligación legal en un requisito de arquitectura medido y
reportado.

> **Regla:** en Open Banking, la disponibilidad y la latencia de tu API no son objetivos internos:
> son obligaciones con reporte al supervisor.

---

## 2. 🎭 Los roles

**Qué es.** El vocabulario, que hay que reconocer sin dudar.

```text
ASPSP  Account Servicing PSP → el banco que mantiene la cuenta. Tú, si trabajas en el banco.
TPP    Third Party Provider  → el tercero autorizado. Se subdivide en:
   AISP  Account Information → solo LEE: saldos y movimientos.
   PISP  Payment Initiation  → ORDENA pagos en nombre del cliente.
   CBPII Card-Based PII      → consulta si hay fondos suficientes. Nada más.
PSU    Payment Service User  → el cliente. El dueño de la cuenta y del consentimiento.
```

- **La distinción AISP / PISP importa** porque el alcance del consentimiento y el riesgo son
  distintos: leer movimientos no es lo mismo que mover dinero.
- **El TPP está autorizado por un regulador nacional** y lo acredita con un certificado específico
  del sector (eIDAS: QWAC para el canal, QSEAL para la firma). El banco debe verificar esa
  autorización, no solo la identidad.

> **Veredicto:** el modelo de roles es lo primero que se pregunta y lo más fácil de acertar. Saber
> que un AISP solo lee y un PISP ordena, y que ambos necesitan certificado acreditado, cubre la
> pregunta de vocabulario.

---

## 3. ✍️ Autenticación reforzada y consentimiento

**Qué es.** Dos mecanismos distintos que se confunden: quién eres y qué has autorizado.

**SCA — autenticación reforzada del cliente.** Doble factor de
[`04-seguridad/01`](../04-seguridad/01-autenticacion-autorizacion-y-amenazas.md), obligatorio para
acceder a la cuenta en línea y para ordenar pagos. Con dos propiedades añadidas por norma:

```text
Dinamic linking → el código de autenticación debe estar LIGADO al importe y al beneficiario
                  concretos. Un código genérico no vale: si cambia el importe, el código deja
                  de ser válido. Impide que un atacante reutilice una autenticación.
Exenciones      → importes pequeños, beneficiarios de confianza, pagos recurrentes,
                  análisis de riesgo de la transacción. Cada exención se justifica y se mide.
```

**El consentimiento.** Una entidad de dominio de pleno derecho, no un booleano:

```text
Consentimiento
  · qué cuentas cubre
  · qué alcance: saldos, movimientos, detalles de la cuenta
  · desde cuándo y hasta cuándo (caducidad obligatoria)
  · estado: recibido, válido, expirado, revocado, rechazado
  · quién lo otorgó, cuándo y con qué autenticación
```

- **Es revocable en cualquier momento**, por el cliente y desde el banco. Y la revocación tiene que
  ser inmediata: no es un caso de "esperar a que caduque el token".
- **Caduca por norma**, con un plazo máximo, y la renovación exige autenticación de nuevo.
- Todo acceso del TPP se comprueba contra el consentimiento vigente, no contra el token: el token
  dice quién llama, el consentimiento dice qué puede ver.

> ⚠️ **Advertencia.** Modelar el consentimiento como un campo booleano en la cuenta es el error de
> diseño más caro de este capítulo. Es una entidad con ciclo de vida, auditoría y caducidad, y el
> supervisor pregunta por ella.

> **Veredicto:** el token autentica al TPP; el **consentimiento** autoriza el acceso a los datos.
> Son dos comprobaciones y las dos son obligatorias, en cada petición.

---

## 4. 🔐 Cómo se asegura el canal

**Qué es.** La combinación concreta, y es donde se aplica todo lo de
[`04-seguridad`](../04-seguridad/).

```text
mTLS con QWAC       → el TPP presenta un certificado acreditado. El banco verifica que
                      está autorizado y para qué roles. Es identidad de organización.
OAuth2 + OIDC       → Authorization Code con PKCE para obtener el consentimiento del cliente.
                      El flujo lleva al PSU al banco, que autentica con SCA.
Firma con QSEAL     → algunas implementaciones exigen firmar el cuerpo de la petición,
                      para no repudio: el TPP no puede negar haber ordenado ese pago.
Token atado al      → RFC 8705: el access token se liga al certificado del TPP. Robarlo
certificado           no basta, hace falta también la clave privada.
```

- **Son tres identidades superpuestas** y conviene separarlas: el **certificado** identifica a la
  organización TPP; el **token** identifica la sesión autorizada; el **consentimiento** delimita qué
  datos. Fallar cualquiera de las tres comprobaciones es rechazar.
- **La firma del cuerpo es para no repudio**, no para confidencialidad: el canal ya va cifrado. Su
  función es probatoria.

> 🧠 **Modelo mental.** Open Banking es el caso de estudio más completo de
> [`04-seguridad/04`](../04-seguridad/04-propagacion-de-identidad.md): identidad de organización con
> mTLS, identidad de usuario con OIDC, y una tercera capa —el consentimiento— que acota el alcance.
> Si entiendes este capítulo, entiendes aquel.

> **Veredicto:** aquí casi no eliges, cumples: mTLS con QWAC, Authorization Code con PKCE y
> consentimiento explícito son requisito regulatorio, y su precio —latencia de handshake y
> gestión de certificados— no es negociable. Lo único que decides es si atas el token al
> certificado, y conviene hacerlo: robar el token deja de bastar.

---

## 5. 🏗️ Lo que exige de tu arquitectura

**Qué es.** Las consecuencias concretas, que es lo que se evalúa en una entrevista de arquitectura.

```text
1. DISPONIBILIDAD MEDIDA Y REPORTADA
   La API dedicada debe tener disponibilidad y tiempos de respuesta comparables a los
   canales propios del banco, y el banco publica esas métricas. No es un SLO interno.

2. MECANISMO DE CONTINGENCIA
   Si la API dedicada falla de forma sostenida, la norma exige una alternativa —o una
   exención concedida por haber demostrado calidad—. La indisponibilidad tiene consecuencias
   regulatorias, no solo comerciales.

3. LÍMITES DE CONSULTA IMPUESTOS
   Hay un número máximo de consultas diarias sin intervención del cliente. Eso condiciona
   el diseño del TPP y obliga al banco a contarlas y aplicarlas.

4. AISLAMIENTO DEL TRÁFICO DE TERCEROS
   Un TPP con un bucle no puede degradar la app del banco. Límites por TPP, cuotas y
   aislamiento de recursos: es el vecino ruidoso de
   [`03-datos/08`](../03-datos/08-poliglota-y-multi-tenant.md) con nombre regulatorio.

5. TRAZABILIDAD COMPLETA
   Qué TPP, qué PSU, qué consentimiento, qué datos, cuándo. Conservado con retención
   regulatoria y consultable ante una reclamación.
```

- **El punto 1 cambia la conversación**: no puedes tratar la API de Open Banking como un canal
  secundario. Su degradación es reportable.
- **El punto 4 es el que más se olvida en el diseño** y el que más incidentes produce: sin cuotas por
  TPP, un tercero mal implementado consume la capacidad que necesitan los clientes del banco.

> **Veredicto:** Open Banking convierte requisitos no funcionales en obligaciones legales. Es el
> ejemplo más claro de que los atributos de calidad de
> [`01-bases/01`](../01-bases/01-fundamentos-del-arquitecto.md) determinan la arquitectura.

---

## 6. 📐 Los estándares de implementación

**Qué es.** PSD2 dice **qué** hay que ofrecer, no **cómo**. Los estándares de implementación llenan
ese hueco, y por eso hay varios.

```text
Berlin Group (NextGenPSD2) → el más extendido en la Europa continental. Define las APIs
                             REST concretas: cuentas, consentimientos, pagos, con ISO 20022 dentro.
Open Banking UK            → el del Reino Unido, con su propio directorio y su esquema.
STET                       → Francia.
```

- **La consecuencia práctica es incómoda**: un TPP que opera en varios países se integra con
  variantes distintas del mismo concepto. Y un banco que opera en varios países expone varias.
- **El diseño correcto lo absorbe con una ACL**: el dominio interno tiene `Consentimiento`,
  `OrdenDePago` y `Cuenta`, y cada estándar entra por su adaptador. Es
  [`04`](04-capa-anticorrupcion.md) otra vez, ahora con un formato regulado en vez de un core.

> **Veredicto:** la variedad de estándares es un problema de integración, no de dominio. Modelar el
> consentimiento y la orden de pago como conceptos propios, y traducir en el borde, es lo que evita
> multiplicar el sistema por el número de países.

---

## 7. 🧭 Cómo se elige

```text
¿Estás en el lado del banco (ASPSP) o del tercero (TPP)?
    Banco → expones API dedicada, con disponibilidad medida, cuotas por TPP y contingencia
    TPP   → consumes, con certificado acreditado, y diseñas para los límites de consulta

Modelado, en ambos casos:
    Consentimiento → ENTIDAD con ciclo de vida, alcance, caducidad y auditoría. Nunca un booleano.
    Orden de pago  → máquina de estados: iniciada, autenticada, aceptada, ejecutada, rechazada
    Cuenta/Movimiento → tu modelo, no el del estándar

Seguridad, las tres capas y las tres se comprueban:
    certificado (¿qué organización y autorizada para qué rol?)
    + token (¿sesión válida?)
    + consentimiento (¿vigente, y cubre ESTA cuenta y ESTE alcance?)

Operación:
    cuotas por TPP · aislamiento del tráfico · métricas publicables · trazabilidad con retención
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El consentimiento es un booleano" | Es una entidad con alcance, caducidad, estado y auditoría |
| "AISP y PISP son lo mismo" | AISP solo lee; PISP ordena pagos. Riesgo y alcance distintos |
| "Con el token basta" | Hacen falta tres comprobaciones: certificado, token y consentimiento |
| "SCA es doble factor" | Y además *dynamic linking*: el código va ligado a importe y beneficiario |
| "PSD2 define la API" | Define qué ofrecer; el cómo lo define Berlin Group, OBUK o STET |
| "Si la API falla, es un problema técnico" | La indisponibilidad sostenida tiene consecuencias regulatorias |
| "Los TPP consultan lo que quieran" | Hay un máximo de consultas diarias sin intervención del cliente |
| "SWIFT y Open Banking son lo mismo" | Uno es interbancario internacional; el otro, acceso de terceros a cuentas |

---

## 📚 Para profundizar

- **Libro** — Prabath Siriwardena y Nuwan Dias, *Microservices Security in Action* (Manning, 2020).
  Los capítulos de OAuth2, mTLS y token exchange, que son exactamente las piezas que Open Banking
  combina.
- **Libro** — Aaron Parecki, *OAuth 2.0 Simplified* (2020). Para fijar el flujo de Authorization
  Code con PKCE, que es el que usa el consentimiento.
- **Libro** — Vlad Khononov, *Learning Domain-Driven Design* (O'Reilly, 2021). Capítulo 4: por qué
  el consentimiento debe ser un concepto de tu dominio y no del estándar.
- [EBA — Payment services and electronic money](https://www.eba.europa.eu/regulation-and-policy/payment-services-and-electronic-money):
  el marco regulatorio europeo, con las normas técnicas de regulación sobre SCA y comunicación.
- [Berlin Group — openFinance downloads](https://www.berlin-group.org/openfinance-downloads): la
  especificación de implementación más extendida en la Europa continental.
- [RFC 8705 — mTLS Client Authentication and Certificate-Bound Access Tokens](https://datatracker.ietf.org/doc/html/rfc8705):
  el mecanismo que ata el token al certificado del TPP.
- [RFC 9700 — Best Current Practice for OAuth 2.0 Security](https://datatracker.ietf.org/doc/html/rfc9700):
  por qué el flujo es Authorization Code con PKCE y no otro.
- **Video** — conferencias del sector de pagos y GOTO Conferences, charlas sobre arquitecturas de
  Open Banking. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué son ASPSP, TPP y PSU? 🟢
2. ¿Qué diferencia hay entre AISP y PISP? 🟢
3. ¿Qué es SCA? 🟢
4. ¿Qué es el consentimiento en PSD2? 🟢
5. ¿Qué estándares de implementación existen? 🟢
6. ¿Qué es el *dynamic linking* y qué impide? 🟡
7. ¿Qué acredita el certificado de un TPP? 🟡
8. ¿Por qué el consentimiento no es un booleano? 🟡
9. ¿Qué tres comprobaciones hace el banco en cada petición de un TPP? 🟡
10. ¿Para qué sirve firmar el cuerpo de la petición? 🟡
11. ¿Qué exenciones de SCA existen? 🟡
12. ¿Por qué PSD2 no define la API concreta? 🟡
13. ¿Por qué la disponibilidad de la API es una obligación y no un objetivo
    interno? 🟠
14. ¿Qué es el mecanismo de contingencia y cuándo aplica? 🟠
15. ¿Por qué hay límites de consulta impuestos? 🟠
16. ¿Cómo se evita que un TPP degrade la app del banco? 🟠
17. ¿Qué relación tiene Open Banking con la propagación de identidad? 🟠
18. ¿Cómo se absorbe la variedad de estándares sin multiplicar el sistema? 🟠
19. ¿Por qué la revocación del consentimiento no puede esperar a la caducidad
    del token? 🟠
20. ¿Qué hay que registrar de cada acceso de un TPP? 🟠
21. Diseña el modelo de consentimiento de un banco que expone Berlin Group:
    entidad, ciclo de vida, y cómo se comprueba en cada petición. 🔴
22. Un TPP está consumiendo el 60 % de la capacidad de tu API y los clientes
    del banco notan latencia. ¿Qué haces, inmediato y de fondo? 🔴
23. Te piden exponer Open Banking sobre un core que cierra 4 horas cada noche.
    Diseña la solución y declara sus límites. 🔴

---

**Anterior:** [`05` — ISO 20022, ISO 8583 y SWIFT](05-iso20022-y-mensajeria-financiera.md) ·
**Siguiente:** [`07` — BPM y workflow](07-bpm-y-workflow.md) ·
**Relacionado:** [`04-seguridad/04` — Propagación de identidad](../04-seguridad/04-propagacion-de-identidad.md)
