# 05 — Banca

> Quinto bloque de [`arquitectura/01-bases`](../README.md). El contexto que hace distinta una entrevista de
> backend en banca: core heredado, ventana batch, MQ, Spring Batch, ISO 20022, PSD2, y la
> conciliación como red de seguridad.
>
> **Vigencia:** 2026-09-18. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](../prompts/guia-de-estilo-y-convenciones.md)

---

## Qué es esto

El bloque diferencial. Los cuatro anteriores se preguntan en cualquier entrevista de arquitectura;
este es el que separa a un candidato genérico de uno que ha trabajado en banca.

**Spring Batch** aparece en casi toda entrevista de backend Java en banca, y el dominio impone restricciones que no existen en
otros sectores: un core que no se toca, una ventana de madrugada que no se puede desbordar, formatos
acordados entre organizaciones, y la obligación de que todo cuadre y se pueda auditar.

Asume leídos [`01-bases`](../01-bases/), [`02-eventos`](../02-eventos/) y
[`04-seguridad`](../04-seguridad/): aquí se aplican, no se repiten.

---

## Orden de lectura

| # | Documento | Qué cubre |
|---|---|---|
| `01` | [Core bancario y legado](01-core-bancario-y-legado.md) | Qué es, ventana batch, las tres fechas, saldo contable vs disponible |
| `02` | [MQ e integración asíncrona](02-mq-e-integracion.md) | Colas transaccionales, request-reply, XA y su sustitución por outbox |
| `03` | [Batch y Spring Batch](03-batch-y-spring-batch.md) | **El más preguntado.** `Job`/`Step`/chunk, reinicio, skip, particionado, cuadre |
| `04` | [Capa anticorrupción](04-capa-anticorrupcion.md) | Qué traduce, cómo se estructura, cómo se prueba, y cuándo no ponerla |
| `05` | [ISO 20022 y mensajería financiera](05-iso20022-y-mensajeria-financiera.md) | `pacs`/`pain`/`camt`, ISO 8583, SWIFT, y el truncamiento |
| `06` | [PSD2 y Open Banking](06-psd2-y-open-banking.md) | Roles, SCA, consentimiento como entidad, y disponibilidad obligatoria |
| `07` | [BPM y workflow](07-bpm-y-workflow.md) | BPMN, DMN, relación con la saga, y el riesgo del ESB disfrazado |
| `08` | [Idempotencia y conciliación](08-idempotencia-y-conciliacion.md) | Partida doble, clave de negocio, conciliación y pista de auditoría |
| `09` | [Simulación de entrevista](09-simulacion-de-entrevista.md) | 32 preguntas `S#` + 6 escenarios de diseño |
| `10` | [Respuestas](10-respuestas.md) | Solucionario completo, en tres capas |

**Si el calendario aprieta**, el orden de prioridad es: `03`, `01`, `08`. Esos tres cubren lo que más
se pregunta y lo que más distingue.

---

## Mapa mental del bloque

```text
        ¿Con qué convivo?        → 01 (core, ventana, saldos y fechas)
                 │
        ┌────────┼────────┐
        ▼        ▼        ▼
   ¿Cómo le    ¿Cómo     ¿Cómo lo
    hablo?     proceso?   protejo?
    02 MQ      03 batch   04 ACL
        │
        ▼
   ¿Y con el mundo?        → 05 formatos · 06 PSD2 · 07 workflow
        │
        ▼
   ¿Y si algo falla?       → 08 (partida doble, conciliación, auditoría)
```

---

## Qué NO está aquí

- **Saga, outbox y event sourcing** → [`02-eventos`](../02-eventos/). Aquí se aplican al dominio.
- **Consistencia, sharding y caché** → [`03-datos`](../03-datos/).
- **OAuth2, mTLS y gestión de secretos** → [`04-seguridad`](../04-seguridad/). El capítulo `06` los
  aplica a Open Banking, no los explica.
- **Contabilidad como disciplina.** Se cubre lo que afecta al diseño —partida doble, inmutabilidad,
  conciliación— y no el plan contable.
- **Spring Batch escrito y corrido** → [`frameworks/01-spring-boot/22`](../../../frameworks/01-spring-boot/22-spring-batch.md)
  y el [taller de lotes](../../03-hexagonal/06-talleres/11-lotes-spring-batch.md) de hexagonal.
- **Laboratorio.** Este corpus es teoría y evaluación; no hay labs.
