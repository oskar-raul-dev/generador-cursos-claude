# 01 — Bases de arquitectura

> El bloque troncal de [`arquitectura/01-bases`](../README.md). Cubre lo que se pregunta en
> **todas** las entrevistas de Backend Senior / Tech Lead, sea cual sea el stack: cómo se
> razona una decisión, cómo se reparte un sistema, cómo se organiza el código, qué patrones
> hay que saber y qué pasa cuando algo falla.
>
> **Vigencia:** 2026-09-18. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](../prompts/guia-de-estilo-y-convenciones.md)

---

## Qué es esto

Material de **repaso para entrevista**, no un curso de arquitectura. La diferencia manda
sobre todo el contenido:

```text
Curso        → te enseña a construir el sistema.
Este repaso  → te enseña a decir por qué lo construirías así, en 2 minutos y en voz alta.
```

Por eso cada concepto cierra con un **veredicto**, todo patrón viene con su **precio**, y
las preguntas **no llevan la respuesta al lado**: viven en
[`12-respuestas.md`](12-respuestas.md), para que no puedas verlas sin querer.

---

## Orden de lectura

| # | Documento | Qué cubre |
|---|---|---|
| `01` | [Fundamentos del arquitecto](01-fundamentos-del-arquitecto.md) | Trade-offs, atributos de calidad, ADR, C4, Conway, fitness functions |
| `02` | [Estilos de despliegue](02-estilos-de-despliegue.md) | Monolito, modular, service-based, microservicios, SOA, serverless, space-based, microkernel, pipeline |
| `03` | [Arquitecturas de aplicación](03-arquitecturas-de-aplicacion.md) | Capas, hexagonal, limpia, cebolla, vertical slice |
| `04` | [Patrones GoF](04-patrones-gof.md) | Los nueve que se preguntan, dónde están en Spring, y los que ya no se usan |
| `05` | [Fowler PoEAA](05-fowler-poeaa.md) | Transaction Script, Domain Model, Repository, Unit of Work, N+1, OSIV, DTO |
| `06` | [DDD estratégico](06-ddd-estrategico.md) | Contexto acotado, lenguaje ubicuo, subdominios, mapa de contextos, ACL |
| `07` | [DDD táctico](07-ddd-tactico.md) | Agregado, entidad, objeto de valor, evento de dominio, y el choque con JPA |
| `08` | [Comunicación e integración](08-comunicacion-e-integracion.md) | Síncrono vs asíncrono, REST, gRPC, contratos, idempotencia, garantías de entrega |
| `09` | [Resiliencia](09-resiliencia.md) | Timeout, reintento con jitter, circuit breaker, bulkhead, degradación, antipatrones |
| `10` | [Alta disponibilidad y escalado](10-alta-disponibilidad-y-escalado.md) | Estado, autoescalado, salud vs disponibilidad, RTO/RPO, despliegues sin caída |
| `11` | [Simulación de entrevista](11-simulacion-de-entrevista.md) | 40 preguntas transversales + 6 escenarios de diseño |
| `12` | [Respuestas](12-respuestas.md) | Solucionario completo, en tres capas |

**Si el calendario aprieta**, el orden de prioridad es: `02`, `03`, `09`, `06`, `05`. Esos
cinco cubren la mayor parte de lo preguntable.

---

## Cómo se estudia

```text
1. Lee el capítulo entero, sin saltarte los veredictos.
2. Contesta las preguntas EN VOZ ALTA, cronometrado a 2 minutos.
3. Solo entonces abre 12-respuestas.md.
4. Lo que supiste pero no pudiste articular en 2 minutos, cuenta como fallo: vuelve.
```

La estructura de las respuestas está pensada para esto:

- **⏱️ 30 segundos** — lo que dices primero, sin que te lo pidan.
- **🗣️ 2 minutos** — lo que añades cuando dicen "cuéntame más".
- **🔬 El detalle** — para estudiar, no para recitar.

Cuando lleves cuatro o cinco capítulos, pasa a [`11`](11-simulacion-de-entrevista.md) y
haz un escenario de diseño con papel. Es lo que más se parece a la entrevista real.

---

## Mapa mental del bloque

```text
                     ¿Cómo decido?           → 01  (trade-off, atributos, ADR)
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
  ¿Cómo reparto?      ¿Cómo organizo?      ¿Cómo modelo?
      02                    03                 06 · 07
  (despliegue)         (dentro del          (DDD estratégico
                        despliegue)          y táctico)
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
                    ¿Cómo se hablan?         → 08
                            │
                    ¿Y cuando falla?         → 09 · 10
```

`04` y `05` son transversales: el vocabulario de patrones que aparece en todos los demás.

---

## Qué NO está aquí

- **Eventos, brokers, saga y event sourcing** → bloque [`02-eventos`](../02-eventos/).
- **CAP, NoSQL, DynamoDB, sharding, caché y CQRS** → bloque [`03-datos`](../03-datos/).
- **Spring Security, OAuth2, mTLS y secretos** → bloque [`04-seguridad`](../04-seguridad/).
- **Core bancario, MQ, batch, ISO 20022 y PSD2** → bloque [`05-banca`](../05-banca/).
- **El monolito modular y el monolito distribuido en profundidad** →
  [`arquitectura/02-monolito`](../../02-monolito/README.md). `02` los sitúa entre los estilos; allí
  se estudia qué mantener unido y cuándo compensa distribuir.
- **Hexagonal por dentro: puertos, adaptadores y testing por anillos** →
  [`arquitectura/03-hexagonal`](../../03-hexagonal/README.md). `03` la compara con capas y cebolla;
  allí se justifica cada frontera.
- **Los patrones de microservicios implementados en cuatro plataformas** →
  [`arquitectura/04-microservicios`](../../04-microservicios/README.md). Aquí se decide si los quieres;
  allí se escriben.
- **Laboratorio práctico.** Este corpus es teoría y evaluación; no hay labs. Está
  declarado en la [guía de estilo §7](../prompts/guia-de-estilo-y-convenciones.md).
