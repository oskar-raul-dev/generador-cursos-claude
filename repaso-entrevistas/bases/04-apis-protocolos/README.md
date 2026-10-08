# APIs y protocolos — repaso para entrevistas

> Seis capítulos sobre lo que viaja por el cable: el mensaje HTTP, la semántica de los métodos, la
> codificación de los cuerpos, TLS y las versiones del protocolo. Más una simulación de entrevista y
> un solucionario en tres capas.
>
> La regla que lo distingue de cualquier tutorial: **cada afirmación normativa cita su RFC**, y cada
> convención se declara como convención. Todo lo ejecutable está corrido; todas las trazas están
> capturadas de verdad.
>
> **Vigencia:** 2026-09-17. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](prompts/guia-de-estilo-y-convenciones.md)

---

## Para quién es

Perfiles de **Backend Senior, Tech Lead o Software Architect** que se presentan a entrevistas donde
el protocolo se pregunta en serio: qué garantiza HTTPS, si `PATCH` es idempotente, cómo se sube un
archivo, qué diferencia `no-cache` de `no-store`. No asume nada leído; sí asume que se ha programado
contra HTTP sin haberlo estudiado nunca.

---

## Orden de lectura

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [Los RFC: la fuente de verdad](01-los-rfc-fuente-de-verdad.md) | 25 | Qué es un RFC, categorías, `MUST`/`SHOULD`/`MAY`, la cadena 2616 → 9110, el prefijo `X-` |
| `02` | [El mensaje y los encabezados](02-el-mensaje-y-los-encabezados.md) | 27 | Anatomía del mensaje, sintaxis de campos, seis familias de encabezados, framing, *smuggling* |
| `03` | [Métodos, semántica e idempotencia](03-metodos-semantica-e-idempotencia.md) | 28 | Seguro/idempotente/cacheable, `PUT` vs `POST` vs `PATCH`, claves de idempotencia, REST |
| `04` | [Codificación y formatos](04-codificacion-y-formatos.md) | 28 | Tipos de medio, negociación, Base64 con su coste medido, `multipart`, UTF-8 y URL |
| `05` | [TLS y seguridad del transporte](05-tls-y-seguridad-del-transporte.md) | 29 | SSL vs TLS, el saludo, certificados y cadena, HSTS, mTLS, SSH frente a TLS |
| `06` | [Versiones, proxies y tiempo real](06-versiones-proxies-y-tiempo-real.md) | 29 | HTTP/1.1, 2 y 3, QUIC, caché de RFC 9111, proxies, SSE frente a WebSocket |
| `07` | [Simulación de entrevista](07-simulacion-de-entrevista.md) | 40 + 6 | Transversales por bloques, "las que descolocan" y seis escenarios |
| `08` | [Respuestas](08-respuestas.md) | 212 | Solucionario completo, en tres capas |

**Si el calendario aprieta:** `03` y `05` son los más rentables — son los dos temarios que casi toda
entrevista de backend senior toca, y donde más se nota responder con la norma en la mano.

---

## Las diez cosas que este corpus deja claras

1. **RFC 2616 está obsoleto desde 2014.** Lo vigente es RFC 9110 (STD 97) y su familia.
2. **`PATCH` no es idempotente y ni siquiera se define en RFC 9110**: está en RFC 5789.
3. **El prefijo `X-` está desaconsejado desde 2012** por RFC 6648, y sigue en el 90 % de las APIs.
4. **Base64 infla un 33 % exacto**, y gzip lo recupera casi entero en datos ya comprimidos (+1 %
   medido) pero lo empeora un 43 % en datos comprimibles.
5. **Un espacio antes de los dos puntos obliga al servidor a responder `400`** — reproducido contra un
   servidor real, y es un `MUST` de seguridad.
6. **`no-cache` no significa no cachear**: significa revalidar siempre. Lo otro es `no-store`.
7. **HTTPS no dice que el sitio sea legítimo.** El phishing también tiene candado.
8. **HTTP/2 quitó el bloqueo de cabeza de línea en HTTP y lo heredó de TCP**; por eso existe HTTP/3.
9. **Exactly-once no existe** sobre una red que pierde mensajes: hay at-least-once más idempotencia.
10. **`ETag` con `If-Match` da concurrencia optimista** sin bloqueos, y casi nadie lo usa.

---

## Qué NO está aquí, y dónde está

Este corpus se escribió **después** que los demás, y su alcance se recortó a propósito para no
duplicar nada:

| Tema | Dónde |
|---|---|
| HATEOAS, paginación, `Page`/`Pageable` | `repaso-spring-entrevistas` |
| `ProblemDetail` (RFC 9457), versionado de API, negociación en el servidor | `repaso-spring-entrevistas` |
| `MultipartFile`, timeouts y pool del cliente HTTP | `repaso-spring-entrevistas` |
| CORS, CSRF, OAuth, JWT, diseño de autenticación | `repaso-arquitectura-entrevistas` |
| mTLS como patrón de arquitectura, malla de servicios | `repaso-arquitectura-entrevistas` |
| Balanceadores gestionados, VPC, DNS, CDN del proveedor | `repaso-aws-entrevistas`, `repaso-gcp-entrevistas` |
| Codificación de caracteres en el lenguaje, strings, complejidad | `repaso-bases-entrevistas` |

Lo que sí es exclusivo de aquí: **la norma**. Qué obliga un RFC, qué solo recomienda y qué es
costumbre del gremio — y la cita para poder demostrarlo.

---

## Cómo se estudia

```text
1. Un capítulo por sesión. Se lee entero, incluida la tabla de "lo que dice la norma".
2. Las preguntas se responden EN VOZ ALTA antes de abrir el solucionario.
3. Cada respuesta se autoevalúa por capas: ¿faltó la de 30 segundos, la de 2 minutos o el detalle?
4. Al terminar los seis, la simulación completa con cronómetro.
```

El error que más se repite al autoevaluarse no es desconocer el dato: es **no distinguir norma de
convención**. Es también el que más rápido se corrige.

---

## Verificación

Antes de dar por buena cualquier edición:

```bash
# Sincronía preguntas ↔ respuestas: los dos números deben coincidir
for f in 0[1-6]-*.md; do
  sed -n '/^## 🧠 Preguntas/,$p' "$f" | grep -cE '^[0-9]+\. '
done | paste -sd+ - | bc
grep -cE '^\*\*[0-9]{2} → [0-9]+\.' 08-respuestas.md

# Enlaces internos rotos
grep -oh '](\([0-9][^)#]*\.md\)' *.md | sed 's/](//' | sort -u | while read f; do
  [ -f "$f" ] || echo "ROTO: $f"
done

# Enlaces externos: se comprueban por código de estado, nunca a ojo
grep -oh 'https\?://[^) ]*' *.md | sort -u | while read u; do
  printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 20 "$u")" "$u"
done | grep -v '^200'
```
