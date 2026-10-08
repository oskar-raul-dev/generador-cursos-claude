# 🏛️ Bases de arquitectura para entrevistas

> Corpus de repaso para entrevistas de **Backend Senior / Software Architect / Tech Lead**
> en el ecosistema Java. Cinco bloques independientes, cada uno con capítulos breves,
> bloques extensos de preguntas y un solucionario aparte — para que estudiar no sea leer
> la respuesta al lado de la pregunta.
>
> **Vigencia:** 2026-09-18. · **Índice de arquitectura:** [`../README.md`](../README.md)

---

## Los cinco bloques

| Bloque | Qué cubre | Estado |
|---|---|---|
| [`01-bases/`](01-bases/) | Fundamentos, estilos de despliegue, capas y hexagonal, GoF, PoEAA, DDD, comunicación, resiliencia, alta disponibilidad | ✅ **completo** — 12 documentos |
| [`02-eventos/`](02-eventos/) | EDA, brokers, garantías de entrega, saga, outbox, event sourcing, streaming | ✅ **completo** — 10 documentos |
| [`03-datos/`](03-datos/) | CAP y PACELC, transacciones, NoSQL y DynamoDB, sharding, réplicas, CQRS, caché | ✅ **completo** — 10 documentos |
| [`04-seguridad/`](04-seguridad/) | Spring Security, OAuth2/OIDC, propagación de identidad, mTLS, zero-trust, secretos | ✅ **completo** — 8 documentos |
| [`05-banca/`](05-banca/) | Core bancario, MQ, Spring Batch, capa anticorrupción sobre mainframe, ISO 20022, PSD2, BPM | ✅ **completo** — 10 documentos |

**Empieza por [`01-bases/`](01-bases/).** Es el troncal: cubre lo que se pregunta en toda
entrevista de arquitectura, y los otros cuatro lo asumen leído.

---

## Cómo está construido cada bloque

```text
NN-tema.md         capítulo: el problema → guía rápida por concepto → errores
                   frecuentes → referencias → 20-30 preguntas SIN respuesta
NN-simulacion.md   preguntas transversales + escenarios de diseño
NN-respuestas.md   solucionario del bloque, con el enunciado copiado literal
README.md          índice, orden de lectura y mapa mental
```

Cada capítulo sigue el mismo patrón por concepto: **qué es → cuándo sí → cuándo no →
veredicto**. Y cada respuesta del solucionario va en tres capas:

```text
⏱️ 30 segundos  → lo que dices primero, sin que te lo pidan
🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más"
🔬 El detalle   → para estudiar, no para decir en voz alta
```

---

## Reglas del corpus

Están en [`prompts/guia-de-estilo-y-convenciones.md`](prompts/guia-de-estilo-y-convenciones.md),
que es normativa y **compartida por los cinco bloques**. Lo esencial:

- **Todo concepto cierra con un veredicto.** Un patrón sin su precio no está explicado.
- **Capítulos breves**, de 200 a 350 líneas. Compite con el calendario, no con un libro.
- **Las respuestas viven en un solo archivo por bloque**, con el enunciado copiado literal.
  Tocar una pregunta obliga a actualizar el solucionario en la misma edición.
- **Referencias por orden de autoridad**: libro con capítulo concreto → fuente primaria del
  autor del concepto → documentación oficial del framework → tutorial → video (por título,
  sin URL). Máximo 8 por capítulo.
- **No se inventan URLs**, y las que se escriben se comprueban por código de estado.
- **No hay laboratorio.** Es teoría y evaluación; los labs se deciden aparte.

---

## Relación con el resto del repositorio

Este módulo es el troncal del [corpus de arquitectura](../README.md). Los módulos hermanos lo dan por
leído y bajan de altitud: cada uno toma una decisión de aquí y la estudia entera.

- [`arquitectura/02-monolito`](../02-monolito/README.md) — el monolito bien hecho y el monolito
  distribuido visto desde dentro. Parte de [`01-bases/02`](01-bases/02-estilos-de-despliegue.md).
- [`arquitectura/03-hexagonal`](../03-hexagonal/README.md) — puertos y adaptadores con criterio de
  producción. Parte de [`01-bases/03`](01-bases/03-arquitecturas-de-aplicacion.md).
- [`arquitectura/04-microservicios`](../04-microservicios/README.md) — los patrones implementados
  en Java · Node/TS · Go · Python. Parte de [`02-eventos`](02-eventos/) y
  [`01-bases/08`](01-bases/08-comunicacion-e-integracion.md)–[`09`](01-bases/09-resiliencia.md).
- [`bases/04-apis-protocolos`](../../bases/04-apis-protocolos/) y
  [`bases/05-bases-datos`](../../bases/05-bases-datos/) — el protocolo y el motor por dentro.
- [`frameworks/01-spring-boot`](../../frameworks/01-spring-boot/) — Spring por dentro. Aquí Spring
  es el ancla de los ejemplos; allí se estudia el mecanismo.
- [`cloud/01-aws`](../../cloud/01-aws/), [`cloud/02-gcp`](../../cloud/02-gcp/) y
  [`cloud/03-azure`](../../cloud/03-azure/) — la nube, con laboratorio. El capítulo
  [`01-bases/09`](01-bases/09-resiliencia.md) se apoya en ellos y no los repite.
- [`preguntas-entrevista/`](../../../preguntas-entrevista/) — bancos de ~100 preguntas con
  respuesta inline. Complementan: allí se repasa rápido, aquí se estudia con veredicto.
- `Entrevistas/` — material personal de búsqueda de empleo. **No se cita desde aquí**: este
  corpus está pensado para publicarse.
