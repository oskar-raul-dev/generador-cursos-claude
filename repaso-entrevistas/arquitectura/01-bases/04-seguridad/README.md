# 04 — Seguridad

> Cuarto bloque de [`arquitectura/01-bases`](../README.md). Quién eres, qué puedes hacer, y cómo se
> mantiene esa respuesta cuando la petición cruza cinco servicios: Spring Security, OAuth2/OIDC,
> propagación de identidad, mTLS, zero-trust y gestión de secretos.
>
> **Vigencia:** 2026-09-18. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](../prompts/guia-de-estilo-y-convenciones.md)

---

## Qué es esto

**Spring Security** se pregunta en casi toda entrevista de backend Java, y en banca la seguridad
no es un capítulo transversal sino un requisito regulatorio con consecuencias de diseño. Este bloque cubre lo que se
pregunta de verdad: no cómo se configura, sino **dónde se verifica y dónde se decide**.

Asume leído [`01-bases`](../01-bases/), y en particular
[`08` — Comunicación e integración](../01-bases/08-comunicacion-e-integracion.md).

---

## Orden de lectura

| # | Documento | Qué cubre |
|---|---|---|
| `01` | [Autenticación, autorización y amenazas](01-autenticacion-autorizacion-y-amenazas.md) | authn vs authz, RBAC/ABAC/ReBAC, PEP y PDP, OWASP |
| `02` | [Spring Security por dentro](02-spring-security-por-dentro.md) | **El más preguntado.** Cadena de filtros, `SecurityContext`, `@PreAuthorize`, CSRF |
| `03` | [OAuth2, OIDC y JWT](03-oauth2-oidc-y-jwt.md) | Las tres capas, flujos vigentes y obsoletos, validación, revocación |
| `04` | [Propagación de identidad](04-propagacion-de-identidad.md) | Las tres estrategias, token exchange, confusión de deputado, auditoría |
| `05` | [mTLS, zero-trust y mesh](05-mtls-zero-trust-y-mesh.md) | Identidad de servicio, el modelo NIST, qué da y qué cuesta una malla |
| `06` | [Secretos y criptografía](06-secretos-y-criptografia.md) | Gestión de secretos, cifrado en reposo, sobre criptográfico, contraseñas |
| `07` | [Simulación de entrevista](07-simulacion-de-entrevista.md) | 32 preguntas `S#` + 5 escenarios de diseño |
| `08` | [Respuestas](08-respuestas.md) | Solucionario completo, en tres capas |

**Si el calendario aprieta**, el orden de prioridad es: `02`, `03`, `04`. Esos tres cubren lo que
más se pregunta.

---

## Mapa mental del bloque

```text
        ¿Quién eres? ¿Qué puedes?     → 01 (vocabulario, modelos, dónde se decide)
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
   Dentro del servicio   Entre servicios
      02 Spring Security    04 propagación de identidad
      03 tokens             05 mTLS y zero-trust
                   │
           ¿Y los datos?     → 06 (secretos, cifrado, contraseñas)
```

---

## Qué NO está aquí

- **Resiliencia, timeouts y circuit breaker** →
  [`01-bases/09`](../01-bases/09-resiliencia.md). La malla los roza; allí se estudian.
- **Aislamiento multi-tenant y Row-Level Security** →
  [`03-datos/08`](../03-datos/08-poliglota-y-multi-tenant.md).
- **Crypto-shredding y RGPD sobre un log inmutable** →
  [`02-eventos/07`](../02-eventos/07-event-sourcing.md). Aquí está el mecanismo; allí el caso.
- **PSD2, Open Banking y firma de mensajes financieros** → [`05-banca`](../05-banca/).
- **La configuración de Spring Security y OAuth2 paso a paso** →
  [`frameworks/01-spring-boot`](../../../frameworks/01-spring-boot/), capítulos `20` y `21`.
  Aquí se decide dónde se verifica; allí se escribe.
- **Laboratorio.** Este corpus es teoría y evaluación; no hay labs.
